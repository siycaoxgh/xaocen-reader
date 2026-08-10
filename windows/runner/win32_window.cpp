#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include <algorithm>

#include "resource.h"

namespace {

/// Window attribute that enables dark mode window decorations.
///
/// Redefined in case the developer's machine has a Windows SDK older than
/// version 10.0.22000.0.
/// See: https://docs.microsoft.com/windows/win32/api/dwmapi/ne-dwmapi-dwmwindowattribute
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

/// Registry key for app theme preference.
///
/// A value of 0 indicates apps should use dark mode. A non-zero or missing
/// value indicates apps should use light mode.
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
  L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

constexpr const wchar_t kWindowStateRegKey[] =
    L"Software\\XAOCEN\\xaocen_reader\\WindowState";
constexpr const wchar_t kNormalXValue[] = L"normalX";
constexpr const wchar_t kNormalYValue[] = L"normalY";
constexpr const wchar_t kNormalWidthValue[] = L"normalWidth";
constexpr const wchar_t kNormalHeightValue[] = L"normalHeight";
constexpr const wchar_t kMaximizedValue[] = L"maximized";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

bool ReadDword(HKEY key, const wchar_t* name, DWORD* value) {
  DWORD type = 0;
  DWORD size = sizeof(*value);
  return RegQueryValueExW(key, name, nullptr, &type,
                          reinterpret_cast<LPBYTE>(value), &size) ==
             ERROR_SUCCESS &&
         type == REG_DWORD;
}

bool ReadInt32(HKEY key, const wchar_t* name, LONG* value) {
  DWORD raw = 0;
  if (!ReadDword(key, name, &raw)) return false;
  *value = static_cast<LONG>(raw);
  return true;
}

bool IsUsableRect(const RECT& rect) {
  return rect.right > rect.left && rect.bottom > rect.top &&
         (rect.right - rect.left) >= GetSystemMetrics(SM_CXMINTRACK) &&
         (rect.bottom - rect.top) >= GetSystemMetrics(SM_CYMINTRACK);
}

RECT ClampToVisibleWorkArea(const RECT& requested) {
  RECT result = requested;
  HMONITOR monitor = MonitorFromRect(&result, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info{sizeof(info)};
  if (monitor == nullptr || !GetMonitorInfoW(monitor, &info)) return result;

  const RECT work = info.rcWork;
  LONG width = std::min(result.right - result.left, work.right - work.left);
  LONG height = std::min(result.bottom - result.top, work.bottom - work.top);
  width = std::max<LONG>(width, GetSystemMetrics(SM_CXMINTRACK));
  height = std::max<LONG>(height, GetSystemMetrics(SM_CYMINTRACK));

  result.right = result.left + width;
  result.bottom = result.top + height;

  // Keep a visible strip on the selected monitor if the old monitor vanished.
  constexpr LONG kVisibleStrip = 64;
  if (result.right < work.left + kVisibleStrip) {
    OffsetRect(&result, work.left + kVisibleStrip - result.right, 0);
  }
  if (result.left > work.right - kVisibleStrip) {
    OffsetRect(&result, work.right - kVisibleStrip - result.left, 0);
  }
  if (result.bottom < work.top + kVisibleStrip) {
    OffsetRect(&result, 0, work.top + kVisibleStrip - result.bottom);
  }
  if (result.top > work.bottom - kVisibleStrip) {
    OffsetRect(&result, 0, work.bottom - kVisibleStrip - result.top);
  }
  return result;
}

bool LoadSavedWindowState(Win32Window::SavedWindowState* state) {
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kWindowStateRegKey, 0, KEY_READ,
                    &key) != ERROR_SUCCESS) {
    return false;
  }

  RECT bounds{};
  DWORD maximized = 0;
  const bool valid = ReadInt32(key, kNormalXValue, &bounds.left) &&
                     ReadInt32(key, kNormalYValue, &bounds.top) &&
                     ReadInt32(key, kNormalWidthValue, &bounds.right) &&
                     ReadInt32(key, kNormalHeightValue, &bounds.bottom) &&
                     ReadDword(key, kMaximizedValue, &maximized);
  RegCloseKey(key);
  if (!valid) return false;

  bounds.right += bounds.left;
  bounds.bottom += bounds.top;
  if (!IsUsableRect(bounds)) return false;
  state->normal_bounds = ClampToVisibleWorkArea(bounds);
  state->maximized = maximized != 0;
  state->valid = true;
  return true;
}

void SaveWindowStateToRegistry(const Win32Window::SavedWindowState& state) {
  HKEY key = nullptr;
  DWORD disposition = 0;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kWindowStateRegKey, 0, nullptr, 0,
                      KEY_WRITE, nullptr, &key, &disposition) !=
      ERROR_SUCCESS) {
    return;
  }

  const RECT& rect = state.normal_bounds;
  const DWORD x = static_cast<DWORD>(rect.left);
  const DWORD y = static_cast<DWORD>(rect.top);
  const DWORD width = static_cast<DWORD>(rect.right - rect.left);
  const DWORD height = static_cast<DWORD>(rect.bottom - rect.top);
  const DWORD maximized = state.maximized ? 1u : 0u;
  RegSetValueExW(key, kNormalXValue, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&x), sizeof(x));
  RegSetValueExW(key, kNormalYValue, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&y), sizeof(y));
  RegSetValueExW(key, kNormalWidthValue, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&width), sizeof(width));
  RegSetValueExW(key, kNormalHeightValue, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&height), sizeof(height));
  RegSetValueExW(key, kMaximizedValue, 0, REG_DWORD,
                 reinterpret_cast<const BYTE*>(&maximized), sizeof(maximized));
  RegCloseKey(key);
}

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

}  // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registrar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  UpdateTheme(window);

  return OnCreate();
}

bool Win32Window::Show() {
  return ShowWindow(window_handle_, SW_SHOWNORMAL);
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_CLOSE:
      SaveCurrentState();
      return DefWindowProc(hwnd, message, wparam, lparam);

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::RestoreSavedState() {
  if (window_handle_ == nullptr) return;
  SavedWindowState state;
  if (!LoadSavedWindowState(&state)) return;

  // Restore normal bounds first. This keeps maximized startup deterministic
  // across monitor/DPI changes; only then apply the maximized presentation.
  WINDOWPLACEMENT placement{sizeof(placement)};
  placement.showCmd = SW_SHOWNORMAL;
  placement.rcNormalPosition = state.normal_bounds;
  SetWindowPlacement(window_handle_, &placement);
  if (state.maximized) ShowWindow(window_handle_, SW_MAXIMIZE);
}

void Win32Window::SaveCurrentState() {
  if (window_handle_ == nullptr) return;
  WINDOWPLACEMENT placement{sizeof(placement)};
  if (!GetWindowPlacement(window_handle_, &placement)) return;
  // Do not overwrite the last useful state when the user closes while
  // minimized. rcNormalPosition is still retained by Windows in that case.
  if (placement.showCmd == SW_SHOWMINIMIZED) return;

  SavedWindowState state;
  state.normal_bounds = placement.rcNormalPosition;
  state.maximized = placement.showCmd == SW_SHOWMAXIMIZED;
  if (!IsUsableRect(state.normal_bounds)) return;
  state.normal_bounds = ClampToVisibleWorkArea(state.normal_bounds);
  state.valid = true;
  SaveWindowStateToRegistry(state);
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy() {
  // No-op; provided for subclasses.
}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  if (result == ERROR_SUCCESS) {
    BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}
