#include "windows_eyedropper_native.h"

#include <string>
#include <utility>

namespace windows_eyedropper {

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
  timer_id_ = SetTimer(owner_, 0xE9E, 33, nullptr);
  if (timer_id_ == 0) {
    if (error != nullptr) *error = "SetTimer(eyedropper) failed";
    Stop();
    return false;
  }
  Tick();
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
  if (active_controller_ == this) active_controller_ = nullptr;
  picking_ = false;
  owner_ = nullptr;
  on_sample_ = nullptr;
  on_confirm_ = nullptr;
  on_cancel_ = nullptr;
}

void Controller::Tick() {
  if (!picking_) return;
  desktop_color_sampler::Sample sample;
  std::string error;
  if (SampleAtCursor(&sample, &error)) on_sample_(sample);
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
  if (message != WM_LBUTTONDOWN && message != WM_RBUTTONDOWN) return;

  desktop_color_sampler::Sample sample;
  std::string error;
  if (!SampleAtCursor(&sample, &error)) return;
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

}  // namespace windows_eyedropper
