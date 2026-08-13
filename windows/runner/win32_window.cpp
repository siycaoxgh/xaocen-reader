#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>
#include <shellapi.h>
#include <windowsx.h>

#include <algorithm>
#include <vector>

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

UINT TaskbarCreatedMessage() {
  static const UINT message = RegisterWindowMessageW(L"TaskbarCreated");
  return message;
}

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

// The popup style retains native resize, minimize, maximize and system-menu
// behavior while removing only the caption/frame decoration.
constexpr LONG_PTR kWindowFrameStyleBits =
    WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU;
constexpr LONG_PTR kBorderlessStyleBits =
    WS_POPUP | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU;
constexpr int kBorderlessDragBand = 36;

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
  if (message == TaskbarCreatedMessage()) {
    // Explorer can restart and discard tray icons. Re-add the tray entry or
    // force the taskbar entry back as the safe recovery path.
    tray_icon_added_ = false;
    if (tray_enabled_ && !AddTrayIcon()) {
      tray_enabled_ = false;
      SetShellVisibility(true, false);
    }
    return 0;
  }
  switch (message) {
    case WM_NCHITTEST:
      if (!window_border_visible_) {
        POINT point{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
        RECT bounds{};
        GetWindowRect(hwnd, &bounds);
        if (!IsZoomed(hwnd)) {
          const int resize_x = GetSystemMetrics(SM_CXSIZEFRAME);
          const int resize_y = GetSystemMetrics(SM_CYSIZEFRAME);
          const bool left = point.x >= bounds.left &&
                            point.x < bounds.left + resize_x;
          const bool right = point.x < bounds.right &&
                             point.x >= bounds.right - resize_x;
          const bool top = point.y >= bounds.top &&
                           point.y < bounds.top + resize_y;
          const bool bottom = point.y < bounds.bottom &&
                              point.y >= bounds.bottom - resize_y;
          if (top && left) return HTTOPLEFT;
          if (top && right) return HTTOPRIGHT;
          if (bottom && left) return HTBOTTOMLEFT;
          if (bottom && right) return HTBOTTOMRIGHT;
          if (left) return HTLEFT;
          if (right) return HTRIGHT;
          if (top) return HTTOP;
          if (bottom) return HTBOTTOM;
        }
        if (point.y < bounds.top + kBorderlessDragBand) {
          // HTCAPTION gives us native drag, double-click maximize/restore and
          // the standard system drag behavior without a global mouse hook.
          return HTCAPTION;
        }
      }
      break;

    case WM_DESTROY:
      RemoveTrayIcon();
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_CLOSE:
      if (!quit_requested_ && tray_enabled_) {
        HideToTray();
        return 0;
      }
      SaveCurrentState();
      return DefWindowProc(hwnd, message, wparam, lparam);

    case kTrayCallbackMessage: {
      // NOTIFYICON_VERSION_4 packs the notification code into LOWORD(lParam)
      // and the icon id into HIWORD(lParam). Older shells may send the code
      // directly, so accept both forms without changing right-click routing.
      const UINT tray_event = LOWORD(lparam);
      if (tray_event == WM_LBUTTONUP ||
          tray_event == WM_LBUTTONDBLCLK ||
          static_cast<UINT>(lparam) == WM_LBUTTONUP ||
          static_cast<UINT>(lparam) == WM_LBUTTONDBLCLK) {
        ShowFromTray();
        return 0;
      }
      if (tray_event == WM_RBUTTONUP ||
          static_cast<UINT>(lparam) == WM_RBUTTONUP) {
        ShowTrayMenu();
        return 0;
      }
      break;
    }

    case WM_HOTKEY:
      if (wparam == kBossHotKeyId) {
        if (!boss_capture_active_) ToggleBossWindow();
        return 0;
      }
      break;

    case WM_INPUT:
      if (mouse_boss_enabled_ && !boss_capture_active_) {
        HandleRawMouseInput(reinterpret_cast<HRAWINPUT>(lparam));
      } else if (boss_capture_active_) {
        ResetMouseBossChord();
      }
      return 0;

    case WM_COMMAND:
      if (LOWORD(wparam) == kTrayShowCommand) {
        ShowFromTray();
        return 0;
      }
      if (LOWORD(wparam) == kTrayHideCommand) {
        HideToTray();
        return 0;
      }
      if (LOWORD(wparam) == kTrayExitCommand) {
        QuitApplication();
        return 0;
      }
      break;

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

  ClearGlobalBossKey();
  SetMouseBossChordEnabled(false);
  RemoveTrayIcon();

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

bool Win32Window::SetShellVisibility(bool show_taskbar, bool show_tray) {
  if (window_handle_ == nullptr || (!show_taskbar && !show_tray)) {
    // A hidden window without a tray/recovery entry would strand the user.
    return false;
  }

  taskbar_enabled_ = show_taskbar;
  tray_enabled_ = show_tray;
  if (tray_enabled_) {
    if (!AddTrayIcon()) {
      tray_enabled_ = false;
      taskbar_enabled_ = true;
      return false;
    }
  } else {
    RemoveTrayIcon();
  }

  const bool was_visible = IsWindowVisible(window_handle_) != FALSE;
  if (was_visible) ShowWindow(window_handle_, SW_HIDE);
  LONG_PTR style = GetWindowLongPtr(window_handle_, GWL_EXSTYLE);
  if (taskbar_enabled_) {
    style &= ~static_cast<LONG_PTR>(WS_EX_TOOLWINDOW);
    style |= static_cast<LONG_PTR>(WS_EX_APPWINDOW);
  } else {
    style &= ~static_cast<LONG_PTR>(WS_EX_APPWINDOW);
    style |= static_cast<LONG_PTR>(WS_EX_TOOLWINDOW);
  }
  SetWindowLongPtr(window_handle_, GWL_EXSTYLE, style);
  SetWindowPos(window_handle_, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);
  if (was_visible) ShowWindow(window_handle_, SW_SHOW);
  return true;
}

bool Win32Window::SetGlobalBossKey(UINT modifiers, UINT virtual_key) {
  if (window_handle_ == nullptr || virtual_key == 0) return false;
  ClearGlobalBossKey();
  boss_hotkey_registered_ = RegisterHotKey(window_handle_, kBossHotKeyId,
                                           modifiers, virtual_key) != FALSE;
  return boss_hotkey_registered_;
}

void Win32Window::ClearGlobalBossKey() {
  if (!boss_hotkey_registered_ || window_handle_ == nullptr) return;
  UnregisterHotKey(window_handle_, kBossHotKeyId);
  boss_hotkey_registered_ = false;
}

bool Win32Window::RegisterMouseRawInput() {
  if (window_handle_ == nullptr) return false;
  RAWINPUTDEVICE device{};
  device.usUsagePage = 0x01;
  device.usUsage = 0x02;
  device.dwFlags = RIDEV_INPUTSINK;
  device.hwndTarget = window_handle_;
  return RegisterRawInputDevices(&device, 1, sizeof(device)) == TRUE;
}

bool Win32Window::SetMouseBossChordEnabled(bool enabled) {
  if (!enabled) {
    if (mouse_boss_enabled_) {
      RAWINPUTDEVICE device{};
      device.usUsagePage = 0x01;
      device.usUsage = 0x02;
      device.dwFlags = RIDEV_REMOVE;
      device.hwndTarget = nullptr;
      RegisterRawInputDevices(&device, 1, sizeof(device));
    }
    mouse_boss_enabled_ = false;
    ResetMouseBossChord();
    return true;
  }
  if (!RegisterMouseRawInput()) return false;
  mouse_boss_enabled_ = true;
  ResetMouseBossChord();
  return true;
}

void Win32Window::SetBossCaptureActive(bool active) {
  boss_capture_active_ = active;
  ResetMouseBossChord();
}

void Win32Window::ResetMouseBossChord() {
  mouse_boss_left_down_ = false;
  mouse_boss_right_down_ = false;
  mouse_boss_latched_ = false;
  mouse_boss_left_down_at_ = 0;
  mouse_boss_right_down_at_ = 0;
}

void Win32Window::HandleRawMouseInput(HRAWINPUT input_handle) {
  UINT size = 0;
  if (GetRawInputData(input_handle, RID_INPUT, nullptr, &size,
                      sizeof(RAWINPUTHEADER)) != 0 ||
      size < sizeof(RAWINPUT)) {
    return;
  }
  std::vector<BYTE> data(size);
  if (GetRawInputData(input_handle, RID_INPUT, data.data(), &size,
                      sizeof(RAWINPUTHEADER)) != size) {
    return;
  }
  const auto* input = reinterpret_cast<const RAWINPUT*>(data.data());
  if (input->header.dwType != RIM_TYPEMOUSE) return;

  const USHORT flags = input->data.mouse.usButtonFlags;
  const ULONGLONG now = GetTickCount64();
  bool invalidated = false;
  if ((flags & RI_MOUSE_LEFT_BUTTON_DOWN) != 0) {
    if (!mouse_boss_left_down_) mouse_boss_left_down_at_ = now;
    mouse_boss_left_down_ = true;
  }
  if ((flags & RI_MOUSE_RIGHT_BUTTON_DOWN) != 0) {
    if (!mouse_boss_right_down_) mouse_boss_right_down_at_ = now;
    mouse_boss_right_down_ = true;
  }
  if ((flags & RI_MOUSE_LEFT_BUTTON_UP) != 0) {
    mouse_boss_left_down_ = false;
    invalidated = true;
  }
  if ((flags & RI_MOUSE_RIGHT_BUTTON_UP) != 0) {
    mouse_boss_right_down_ = false;
    invalidated = true;
  }
  if (!mouse_boss_left_down_ && !mouse_boss_right_down_) {
    ResetMouseBossChord();
    return;
  }
  if (invalidated || mouse_boss_latched_ || !mouse_boss_left_down_ ||
      !mouse_boss_right_down_) {
    return;
  }
  const ULONGLONG delta = mouse_boss_left_down_at_ > mouse_boss_right_down_at_
                              ? mouse_boss_left_down_at_ -
                                    mouse_boss_right_down_at_
                              : mouse_boss_right_down_at_ -
                                    mouse_boss_left_down_at_;
  if (delta > kBossMouseChordThresholdMs) return;
  mouse_boss_latched_ = true;
  ToggleBossWindow();
}

void Win32Window::ToggleBossWindow() {
  if (window_handle_ == nullptr) return;
  if (IsWindowVisible(window_handle_) != FALSE) {
    // A registered Boss input is itself a recovery channel, so hiding remains
    // safe even when the tray is disabled.
    if (!HideToTray()) ShowWindow(window_handle_, SW_HIDE);
  } else {
    ShowFromTray();
  }
}

bool Win32Window::SetWindowBorder(bool show_border) {
  if (window_handle_ == nullptr) return false;
  if (window_border_visible_ == show_border) return true;

  WINDOWPLACEMENT placement{sizeof(placement)};
  const bool was_maximized =
      GetWindowPlacement(window_handle_, &placement) &&
      placement.showCmd == SW_SHOWMAXIMIZED;
  if (was_maximized) ShowWindow(window_handle_, SW_RESTORE);

  LONG_PTR style = GetWindowLongPtr(window_handle_, GWL_STYLE);
  style &= ~kWindowFrameStyleBits;
  style |= show_border ? static_cast<LONG_PTR>(WS_OVERLAPPEDWINDOW)
                       : kBorderlessStyleBits;
  SetWindowLongPtr(window_handle_, GWL_STYLE, style);
  window_border_visible_ = show_border;

  SetWindowPos(window_handle_, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE |
                   SWP_FRAMECHANGED);
  if (was_maximized) ShowWindow(window_handle_, SW_MAXIMIZE);
  return true;
}

bool Win32Window::HideToTray() {
  // A taskbar entry is also a valid recovery path for Boss Key. The name is
  // retained for the existing channel contract, but hiding is allowed when
  // either shell entry remains enabled.
  if (window_handle_ == nullptr || (!tray_enabled_ && !taskbar_enabled_)) {
    return false;
  }
  ShowWindow(window_handle_, SW_HIDE);
  return true;
}

bool Win32Window::ShowFromTray() {
  if (window_handle_ == nullptr) return false;
  const bool was_minimized = IsIconic(window_handle_) != FALSE;
  const bool was_maximized = IsZoomed(window_handle_) != FALSE;
  ShowWindow(window_handle_, was_minimized ? SW_RESTORE : SW_SHOW);
  if (was_maximized) ShowWindow(window_handle_, SW_MAXIMIZE);
  SetWindowPos(window_handle_, HWND_TOP, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
  SetActiveWindow(window_handle_);
  SetForegroundWindow(window_handle_);
  BringWindowToTop(window_handle_);
  if (child_content_ != nullptr) SetFocus(child_content_);
  return true;
}

bool Win32Window::QuitApplication() {
  if (window_handle_ == nullptr) return false;
  quit_requested_ = true;
  RemoveTrayIcon();
  SaveCurrentState();
  PostMessage(window_handle_, WM_CLOSE, 0, 0);
  return true;
}

bool Win32Window::AddTrayIcon() {
  if (window_handle_ == nullptr) return false;
  if (tray_icon_added_) return true;
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = window_handle_;
  data.uID = kTrayIconId;
  data.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  data.uCallbackMessage = kTrayCallbackMessage;
  data.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
  wcscpy_s(data.szTip, L"XAOCEN Reader");
  if (Shell_NotifyIconW(NIM_ADD, &data) == FALSE) return false;
  data.uVersion = NOTIFYICON_VERSION_4;
  Shell_NotifyIconW(NIM_SETVERSION, &data);
  tray_icon_added_ = true;
  return true;
}

void Win32Window::RemoveTrayIcon() {
  if (!tray_icon_added_ || window_handle_ == nullptr) return;
  NOTIFYICONDATAW data{};
  data.cbSize = sizeof(data);
  data.hWnd = window_handle_;
  data.uID = kTrayIconId;
  Shell_NotifyIconW(NIM_DELETE, &data);
  tray_icon_added_ = false;
}

void Win32Window::ShowTrayMenu() {
  if (window_handle_ == nullptr || !tray_enabled_) return;
  POINT point{};
  GetCursorPos(&point);
  HMENU menu = CreatePopupMenu();
  if (menu == nullptr) return;
  const bool visible = IsWindowVisible(window_handle_) != FALSE;
  AppendMenuW(menu, MF_STRING, kTrayShowCommand, L"Show window");
  AppendMenuW(menu, MF_STRING | (visible ? MF_ENABLED : MF_GRAYED),
              kTrayHideCommand, L"Hide window");
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kTrayExitCommand, L"Exit application");
  // A popup menu must have a foreground owner for Windows to keep it open
  // and deliver WM_COMMAND. The owner may be hidden after a Boss action; the
  // tray popup itself remains the explicit recovery surface.
  SetForegroundWindow(window_handle_);
  TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_NOANIMATION, point.x, point.y, 0,
                 window_handle_, nullptr);
  DestroyMenu(menu);
  SetForegroundWindow(window_handle_);
  PostMessage(window_handle_, WM_NULL, 0, 0);
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
