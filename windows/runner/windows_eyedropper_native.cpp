#include "windows_eyedropper_native.h"

#include <algorithm>
#include <cstdio>
#include <string>
#include <utility>

namespace windows_eyedropper {

namespace {

constexpr wchar_t kPreviewClassName[] = L"XAOCEN_EYEDROPPER_PREVIEW";

std::wstring HexForColor(COLORREF color) {
  wchar_t buffer[8]{};
  swprintf_s(buffer, L"#%02X%02X%02X", static_cast<unsigned>(GetRValue(color)),
             static_cast<unsigned>(GetGValue(color)),
             static_cast<unsigned>(GetBValue(color)));
  return buffer;
}

int ScaleForWindow(HWND window, int value) {
  const UINT dpi = window == nullptr ? 96 : GetDpiForWindow(window);
  return MulDiv(value, dpi == 0 ? 96 : static_cast<int>(dpi), 96);
}

}  // namespace

Controller* Controller::active_controller_ = nullptr;

Controller::~Controller() { Stop(); }

bool Controller::Start(HWND owner, SampleCallback on_sample,
                       ConfirmCallback on_confirm, CancelCallback on_cancel,
                       std::string* error) {
  if (picking_) return false;
  if (owner == nullptr || on_sample == nullptr || on_confirm == nullptr ||
      on_cancel == nullptr) {
    if (error != nullptr) *error = "invalid eyedropper controller arguments";
    return false;
  }

  owner_ = owner;
  on_sample_ = std::move(on_sample);
  on_confirm_ = std::move(on_confirm);
  on_cancel_ = std::move(on_cancel);
  CURSORINFO cursor_info{};
  cursor_info.cbSize = sizeof(cursor_info);
  previous_cursor_ = GetCursorInfo(&cursor_info) != FALSE
                         ? cursor_info.hCursor
                         : nullptr;
  // The preview is created by the owner timer after the initiating Flutter
  // click has returned, avoiding re-entrant native window creation.
  mouse_hook_ = SetWindowsHookExW(WH_MOUSE_LL, &Controller::MouseHook,
                                  GetModuleHandle(nullptr), 0);
  keyboard_hook_ = SetWindowsHookExW(WH_KEYBOARD_LL, &Controller::KeyboardHook,
                                     GetModuleHandle(nullptr), 0);
  if (mouse_hook_ == nullptr || keyboard_hook_ == nullptr) {
    if (error != nullptr) {
      *error = "SetWindowsHookEx(eyedropper) failed (" +
               std::to_string(GetLastError()) + ")";
    }
    Stop();
    return false;
  }

  active_controller_ = this;
  picking_ = true;
  SetPickingCursor();
  timer_id_ = SetTimer(owner_, 0xE9E, 33, nullptr);
  if (timer_id_ == 0) {
    if (error != nullptr) *error = "SetTimer(eyedropper) failed";
    Stop();
    return false;
  }
  // The first sample is delivered by the owner timer after this method has
  // returned to Flutter. This avoids re-entrant platform-channel callbacks.
  return true;
}

void Controller::OnTimer(UINT_PTR timer_id) {
  if (picking_ && timer_id == timer_id_) Tick();
}

void Controller::Stop() {
  if (timer_id_ != 0 && owner_ != nullptr) {
    KillTimer(owner_, timer_id_);
  }
  timer_id_ = 0;
  if (mouse_hook_ != nullptr) UnhookWindowsHookEx(mouse_hook_);
  if (keyboard_hook_ != nullptr) UnhookWindowsHookEx(keyboard_hook_);
  mouse_hook_ = nullptr;
  keyboard_hook_ = nullptr;
  DestroyPreviewWindow();
  RestoreCursor();
  if (active_controller_ == this) active_controller_ = nullptr;
  picking_ = false;
  owner_ = nullptr;
  on_sample_ = nullptr;
  on_confirm_ = nullptr;
  on_cancel_ = nullptr;
}

void Controller::Tick() {
  if (!picking_) return;
  if (preview_window_ == nullptr) {
    // Create the transient window from the normal owner timer rather than
    // re-entering native window creation while the Flutter start call is
    // still dispatching the initiating click.
    CreatePreviewWindow();
  }
  desktop_color_sampler::Sample sample;
  std::string error;
  SetPickingCursor();
  if (SampleAtCursor(&sample, &error)) {
    UpdatePreview(sample);
    on_sample_(sample);
  }
}

bool Controller::SampleAtCursor(desktop_color_sampler::Sample* sample,
                                std::string* error) const {
  POINT point{};
  if (!GetCursorPos(&point)) {
    if (error != nullptr) *error = "GetCursorPos failed";
    return false;
  }
  return desktop_color_sampler::SamplePixel(point.x, point.y, sample, error);
}

void Controller::HandleMouse(WPARAM message, const MSLLHOOKSTRUCT* data) {
  if (!picking_ || data == nullptr) return;
  if (message == WM_MOUSEMOVE) {
    SetPickingCursor();
    return;
  }
  if (message != WM_LBUTTONDOWN && message != WM_RBUTTONDOWN) return;

  desktop_color_sampler::Sample sample;
  std::string error;
  if (!SampleAtCursor(&sample, &error)) return;
  UpdatePreview(sample);
  on_sample_(sample);
  if (message == WM_LBUTTONDOWN) {
    ConfirmCallback confirm = std::move(on_confirm_);
    Stop();
    confirm(sample);
  } else {
    CancelCallback cancel = std::move(on_cancel_);
    Stop();
    cancel();
  }
}

void Controller::HandleKeyboard(WPARAM message, const KBDLLHOOKSTRUCT* data) {
  if (!picking_ || data == nullptr || message != WM_KEYDOWN) return;
  if (data->vkCode != VK_ESCAPE) return;
  CancelCallback cancel = std::move(on_cancel_);
  Stop();
  cancel();
}

LRESULT CALLBACK Controller::MouseHook(int code, WPARAM wparam,
                                       LPARAM lparam) {
  if (code == HC_ACTION && active_controller_ != nullptr) {
    active_controller_->HandleMouse(
        wparam, reinterpret_cast<const MSLLHOOKSTRUCT*>(lparam));
  }
  return CallNextHookEx(nullptr, code, wparam, lparam);
}

LRESULT CALLBACK Controller::KeyboardHook(int code, WPARAM wparam,
                                          LPARAM lparam) {
  if (code == HC_ACTION && active_controller_ != nullptr) {
    active_controller_->HandleKeyboard(
        wparam, reinterpret_cast<const KBDLLHOOKSTRUCT*>(lparam));
  }
  return CallNextHookEx(nullptr, code, wparam, lparam);
}

ATOM Controller::RegisterPreviewWindowClass(HINSTANCE instance) {
  WNDCLASSEXW existing{};
  existing.cbSize = sizeof(existing);
  if (GetClassInfoExW(instance, kPreviewClassName, &existing) != FALSE) {
    return 1;
  }

  WNDCLASSEXW window_class{};
  window_class.cbSize = sizeof(window_class);
  window_class.hInstance = instance;
  window_class.lpfnWndProc = &Controller::PreviewWindowProc;
  window_class.lpszClassName = kPreviewClassName;
  window_class.hCursor = LoadCursorW(nullptr, IDC_ARROW);
  return RegisterClassExW(&window_class);
}

bool Controller::CreatePreviewWindow() {
  if (preview_window_ != nullptr) return true;
  const HINSTANCE instance = GetModuleHandleW(nullptr);
  if (RegisterPreviewWindowClass(instance) == 0) return false;
  const int width = ScaleForWindow(owner_, 270);
  const int height = ScaleForWindow(owner_, 76);
  preview_window_ = CreateWindowExW(
      WS_EX_TOOLWINDOW | WS_EX_TOPMOST | WS_EX_NOACTIVATE | WS_EX_LAYERED,
      kPreviewClassName, L"", WS_POPUP, 0, 0, width, height, nullptr, nullptr,
      instance, this);
  if (preview_window_ == nullptr) return false;
  // Keep the transient preview visually consistent with the rounded XAOCEN
  // surfaces instead of presenting a square native tooltip-like window.
  const int radius = ScaleForWindow(owner_, 12);
  HRGN rounded_region = CreateRoundRectRgn(0, 0, width + 1, height + 1,
                                           radius, radius);
  if (rounded_region != nullptr &&
      SetWindowRgn(preview_window_, rounded_region, TRUE) == 0) {
    DeleteObject(rounded_region);
  }
  SetLayeredWindowAttributes(preview_window_, 0, 244, LWA_ALPHA);
  return true;
}

void Controller::DestroyPreviewWindow() {
  if (preview_window_ != nullptr) {
    DestroyWindow(preview_window_);
    preview_window_ = nullptr;
  }
}

void Controller::UpdatePreview(const desktop_color_sampler::Sample& sample) {
  preview_color_ = sample.color;
  preview_hex_ = HexForColor(sample.color);
  if (preview_window_ == nullptr) return;

  POINT cursor{};
  if (!GetCursorPos(&cursor)) return;
  const int margin = ScaleForWindow(owner_, 18);
  const int width = ScaleForWindow(owner_, 270);
  const int height = ScaleForWindow(owner_, 76);
  int x = cursor.x + margin;
  int y = cursor.y + margin;
  HMONITOR monitor = MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(monitor_info);
  if (monitor != nullptr && GetMonitorInfoW(monitor, &monitor_info) != FALSE) {
    const RECT work = monitor_info.rcWork;
    if (x + width > work.right) x = cursor.x - width - margin;
    if (y + height > work.bottom) y = cursor.y - height - margin;
    x = std::max(static_cast<int>(work.left),
                 std::min(x, static_cast<int>(work.right) - width));
    y = std::max(static_cast<int>(work.top),
                 std::min(y, static_cast<int>(work.bottom) - height));
  }
  SetWindowPos(preview_window_, HWND_TOPMOST, x, y, width, height,
               SWP_NOACTIVATE | SWP_SHOWWINDOW);
  InvalidateRect(preview_window_, nullptr, FALSE);
}

void Controller::SetPickingCursor() {
  if (!picking_) return;
  SetCursor(LoadCursorW(nullptr, IDC_CROSS));
}

void Controller::RestoreCursor() {
  HCURSOR cursor = previous_cursor_;
  if (cursor == nullptr) cursor = LoadCursorW(nullptr, IDC_ARROW);
  SetCursor(cursor);
  previous_cursor_ = nullptr;
}

LRESULT CALLBACK Controller::PreviewWindowProc(HWND window, UINT message,
                                               WPARAM wparam, LPARAM lparam) {
  auto* controller = reinterpret_cast<Controller*>(GetWindowLongPtrW(
      window, GWLP_USERDATA));
  if (message == WM_NCCREATE) {
    const auto* create = reinterpret_cast<const CREATESTRUCTW*>(lparam);
    controller = static_cast<Controller*>(create->lpCreateParams);
    SetWindowLongPtrW(window, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(controller));
  }

  switch (message) {
    case WM_NCHITTEST:
      return HTTRANSPARENT;
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;
    case WM_ERASEBKGND:
      return 1;
    case WM_PAINT: {
      PAINTSTRUCT paint{};
      HDC dc = BeginPaint(window, &paint);
      RECT bounds{};
      GetClientRect(window, &bounds);
      HBRUSH background = CreateSolidBrush(RGB(28, 31, 36));
      FillRect(dc, &bounds, background);
      DeleteObject(background);

      const int swatch = ScaleForWindow(window, 32);
      RECT swatch_rect{ScaleForWindow(window, 10), ScaleForWindow(window, 10),
                       ScaleForWindow(window, 10) + swatch,
                       ScaleForWindow(window, 10) + swatch};
      HBRUSH color = CreateSolidBrush(controller == nullptr
                                          ? RGB(80, 80, 80)
                                          : controller->preview_color_);
      FillRect(dc, &swatch_rect, color);
      DeleteObject(color);

      SetBkMode(dc, TRANSPARENT);
      SetTextColor(dc, RGB(245, 245, 245));
      HFONT font = static_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));
      const HGDIOBJ old_font = SelectObject(dc, font);
      RECT hex_rect{ScaleForWindow(window, 52), ScaleForWindow(window, 8),
                    bounds.right - ScaleForWindow(window, 8),
                    ScaleForWindow(window, 38)};
      const std::wstring hex = controller == nullptr ? L"#------"
                                                     : controller->preview_hex_;
      DrawTextW(dc, hex.c_str(), -1, &hex_rect, DT_SINGLELINE | DT_VCENTER);
      SetTextColor(dc, RGB(190, 200, 205));
      RECT hint_rect{ScaleForWindow(window, 52), ScaleForWindow(window, 40),
                     bounds.right - ScaleForWindow(window, 8),
                     bounds.bottom - ScaleForWindow(window, 6)};
      // Keep native source independent of the active Windows code page.
      // Universal-character escapes ensure DrawTextW receives the intended
      // Chinese text instead of a mojibake conversion.
      DrawTextW(dc, L"\u5DE6\u952E\u9009\u53D6   Esc / \u53F3\u952E\u53D6\u6D88", -1,
                &hint_rect, DT_SINGLELINE | DT_VCENTER);
      SelectObject(dc, old_font);
      EndPaint(window, &paint);
      return 0;
    }
    default:
      break;
  }
  return DefWindowProcW(window, message, wparam, lparam);
}

}  // namespace windows_eyedropper
