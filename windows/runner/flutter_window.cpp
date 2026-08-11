#include "flutter_window.h"

#include <optional>
#include <map>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/standard_method_codec.h>

namespace {
std::string Utf8FromWide(const std::wstring& value) {
  if (value.empty()) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                      static_cast<int>(value.size()), nullptr,
                                      0, nullptr, nullptr);
  std::string result(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), size,
                      nullptr, nullptr);
  return result;
}

flutter::EncodableList InstalledWindowsFonts() {
  std::map<std::string, std::wstring> fonts;
  const wchar_t* paths[] = {
      L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts",
  };
  const HKEY roots[] = {HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER};
  for (const auto root : roots) {
    HKEY key = nullptr;
    if (RegOpenKeyExW(root, paths[0], 0, KEY_READ, &key) != ERROR_SUCCESS) {
      continue;
    }
    DWORD index = 0;
    wchar_t value_name[512];
    DWORD value_name_size = std::size(value_name);
    while (RegEnumValueW(key, index++, value_name, &value_name_size, nullptr,
                         nullptr, nullptr, nullptr) == ERROR_SUCCESS) {
      std::wstring name(value_name);
      const auto suffix = name.find(L" (");
      if (suffix != std::wstring::npos) name.resize(suffix);
      wchar_t data[1024] = {};
      DWORD data_size = sizeof(data);
      DWORD data_type = 0;
      std::wstring file_name;
      if (RegQueryValueExW(key, value_name, nullptr, &data_type,
                           reinterpret_cast<LPBYTE>(data), &data_size) ==
              ERROR_SUCCESS &&
          (data_type == REG_SZ || data_type == REG_EXPAND_SZ)) {
        file_name.assign(data, data_size / sizeof(wchar_t));
        while (!file_name.empty() && file_name.back() == L'\0') {
          file_name.pop_back();
        }
        const auto slash = file_name.find_last_of(L"\\/");
        if (slash != std::wstring::npos) file_name = file_name.substr(slash + 1);
      }
      if (file_name.empty()) file_name = name;
      for (auto& character : file_name) {
        if (character >= L'A' && character <= L'Z') {
          character = static_cast<wchar_t>(character - L'A' + L'a');
        }
        if (!((character >= L'a' && character <= L'z') ||
              (character >= L'0' && character <= L'9'))) {
          character = L'_';
        }
      }
      if (!name.empty()) {
        fonts["windows.system.file." + Utf8FromWide(file_name)] = name;
      }
      value_name_size = std::size(value_name);
    }
    RegCloseKey(key);
  }
  flutter::EncodableList result;
  for (const auto& entry : fonts) {
    const auto& id = entry.first;
    const auto& name = entry.second;
    const auto utf8_name = Utf8FromWide(name);
    flutter::EncodableMap descriptor;
    descriptor[flutter::EncodableValue("id")] =
        flutter::EncodableValue(id);
    descriptor[flutter::EncodableValue("familyName")] =
        flutter::EncodableValue(utf8_name);
    // Registry display names are already localized by Windows when the
    // current locale has a localized family name; keep the family as the
    // stable runtime value and expose the localized value for UI.
    descriptor[flutter::EncodableValue("displayName")] =
        flutter::EncodableValue(utf8_name);
    result.emplace_back(flutter::EncodableValue(descriptor));
  }
  return result;
}
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  shell_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "xaocen/windows_shell",
      &flutter::StandardMethodCodec::GetInstance());
  shell_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "setShellVisibility") {
          bool taskbar = true;
          bool tray = false;
          const auto* args = call.arguments();
          if (args != nullptr) {
            const auto* map = std::get_if<flutter::EncodableMap>(args);
            if (map != nullptr) {
              const auto taskbar_it =
                  map->find(flutter::EncodableValue("taskbar"));
              const auto tray_it = map->find(flutter::EncodableValue("tray"));
              if (taskbar_it != map->end()) {
                if (const auto* value =
                        std::get_if<bool>(&taskbar_it->second)) {
                  taskbar = *value;
                }
              }
              if (tray_it != map->end()) {
                if (const auto* value = std::get_if<bool>(&tray_it->second)) {
                  tray = *value;
                }
              }
            }
          }
          result->Success(flutter::EncodableValue(
              SetShellVisibility(taskbar, tray)));
          return;
        }
        if (call.method_name() == "setWindowBorder") {
          bool show_border = true;
          const auto* args = call.arguments();
          if (args != nullptr) {
            const auto* map = std::get_if<flutter::EncodableMap>(args);
            if (map != nullptr) {
              const auto border_it =
                  map->find(flutter::EncodableValue("show"));
              if (border_it != map->end()) {
                if (const auto* value =
                        std::get_if<bool>(&border_it->second)) {
                  show_border = *value;
                }
              }
            }
          }
          result->Success(
              flutter::EncodableValue(SetWindowBorder(show_border)));
          return;
        }
        if (call.method_name() == "hideWindow") {
          result->Success(flutter::EncodableValue(HideToTray()));
          return;
        }
        if (call.method_name() == "showWindow") {
          result->Success(flutter::EncodableValue(ShowFromTray()));
          return;
        }
        if (call.method_name() == "quitApplication") {
          result->Success(flutter::EncodableValue(QuitApplication()));
          return;
        }
        result->NotImplemented();
      });
  fonts_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "xaocen/windows_fonts",
      &flutter::StandardMethodCodec::GetInstance());
  fonts_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "listAvailableFonts") {
          result->Success(InstalledWindowsFonts());
          return;
        }
        result->NotImplemented();
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (shell_channel_) {
    shell_channel_->SetMethodCallHandler(nullptr);
    shell_channel_.reset();
  }
  if (fonts_channel_) {
    fonts_channel_->SetMethodCallHandler(nullptr);
    fonts_channel_.reset();
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // The Flutter child view covers the client area. Handle borderless hit
  // testing before forwarding top-level messages so native drag/resize keeps
  // working even when Flutter has focus.
  if (message == WM_NCHITTEST && !IsWindowBorderVisible()) {
    return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
  }
  // Persist shell geometry before Flutter/plugin close handling can consume
  // WM_CLOSE. Minimized state is filtered inside SaveCurrentState().
  if (message == WM_CLOSE) {
    if (IsTrayEnabled() && !IsQuitRequested()) {
      HideToTray();
      return 0;
    }
    SaveCurrentState();
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
