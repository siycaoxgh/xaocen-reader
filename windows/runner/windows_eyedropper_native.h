#ifndef RUNNER_WINDOWS_EYEDROPPER_NATIVE_H_
#define RUNNER_WINDOWS_EYEDROPPER_NATIVE_H_

#include "desktop_color_sampler.h"

#include <windows.h>

#include <functional>
#include <string>

namespace windows_eyedropper {

class Controller {
 public:
  using SampleCallback = std::function<void(
      const desktop_color_sampler::Sample& sample)>;
  using ConfirmCallback = std::function<void(
      const desktop_color_sampler::Sample& sample)>;
  using CancelCallback = std::function<void()>;

  Controller() = default;
  ~Controller();

  Controller(const Controller&) = delete;
  Controller& operator=(const Controller&) = delete;

  bool Start(HWND owner, SampleCallback on_sample, ConfirmCallback on_confirm,
             CancelCallback on_cancel, std::string* error);
  void Stop();
  void OnTimer(UINT_PTR timer_id);
  bool IsPicking() const { return picking_; }

 private:
  static LRESULT CALLBACK MouseHook(int code, WPARAM wparam, LPARAM lparam);
  static LRESULT CALLBACK KeyboardHook(int code, WPARAM wparam,
                                        LPARAM lparam);
  static Controller* active_controller_;

  void Tick();
  void HandleMouse(WPARAM message, const MSLLHOOKSTRUCT* data);
  void HandleKeyboard(WPARAM message, const KBDLLHOOKSTRUCT* data);
  bool SampleAtCursor(desktop_color_sampler::Sample* sample,
                      std::string* error) const;
  bool CreatePreviewWindow();
  void DestroyPreviewWindow();
  void UpdatePreview(const desktop_color_sampler::Sample& sample);
  void SetPickingCursor();
  void RestoreCursor();
  static LRESULT CALLBACK PreviewWindowProc(HWND window, UINT message,
                                            WPARAM wparam, LPARAM lparam);
  static ATOM RegisterPreviewWindowClass(HINSTANCE instance);

  HWND owner_ = nullptr;
  HWND preview_window_ = nullptr;
  HHOOK mouse_hook_ = nullptr;
  HHOOK keyboard_hook_ = nullptr;
  UINT_PTR timer_id_ = 0;
  bool picking_ = false;
  HCURSOR previous_cursor_ = nullptr;
  COLORREF preview_color_ = RGB(32, 32, 32);
  std::wstring preview_hex_ = L"#------";
  SampleCallback on_sample_;
  ConfirmCallback on_confirm_;
  CancelCallback on_cancel_;
};

}  // namespace windows_eyedropper

#endif  // RUNNER_WINDOWS_EYEDROPPER_NATIVE_H_
