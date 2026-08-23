#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <cstdlib>

#include "flutter_window.h"
#include "utils.h"

namespace {

bool IsPatchedEngineStage() {
  wchar_t module_path[MAX_PATH] = {};
  const DWORD length = ::GetModuleFileNameW(nullptr, module_path,
                                             ARRAYSIZE(module_path));
  if (length == 0 || length >= ARRAYSIZE(module_path)) {
    return false;
  }

  std::filesystem::path manifest_path(module_path);
  manifest_path.replace_filename(L"engine-selection.json");
  std::ifstream manifest(manifest_path, std::ios::binary);
  if (!manifest) {
    return false;
  }
  const std::string contents((std::istreambuf_iterator<char>(manifest)),
                             std::istreambuf_iterator<char>());
  // The manifest is generated as JSON and may contain arbitrary whitespace
  // around the colon.  Do not use a byte-for-byte JSON formatting match here;
  // the selection marker is the only value that controls the runner's alpha
  // opt-in.
  const auto selection_key = contents.find("\"selection\"");
  const auto patched_value = contents.find("XAOCEN_PATCHED_ENGINE");
  return selection_key != std::string::npos &&
         patched_value != std::string::npos && patched_value > selection_key;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  HANDLE instance_mutex = CreateMutexW(
      nullptr, TRUE, L"XAOCEN.Reader.StandardInstance");
  if (instance_mutex == nullptr || GetLastError() == ERROR_ALREADY_EXISTS) {
    if (instance_mutex != nullptr) CloseHandle(instance_mutex);
    HWND existing = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"XAOCEN Reader");
    if (existing != nullptr) {
      ShowWindow(existing, IsIconic(existing) ? SW_RESTORE : SW_SHOW);
      SetForegroundWindow(existing);
      SetFocus(existing);
    }
    return EXIT_SUCCESS;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  const bool patched_engine_stage = IsPatchedEngineStage();
  if (patched_engine_stage) {
    // The patched Release Engine has a small, explicit release whitelist for
    // this variable. Standard bundles never set it and stay on opaque ANGLE.
    // Use the CRT setter as well as Win32's environment API: the Engine reads
    // through std::getenv, whose CRT snapshot is not guaranteed to observe a
    // later SetEnvironmentVariableW call.
    _putenv_s("XAOCEN_ENABLE_WINDOWS_ALPHA_SURFACE", "1");
    ::SetEnvironmentVariableW(L"XAOCEN_ENABLE_WINDOWS_ALPHA_SURFACE", L"1");
  }
  FlutterWindow window(project);
  if (patched_engine_stage) {
    window.SetAlphaSurfaceRequested(true);
  }
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"XAOCEN Reader", origin, size)) {
    return EXIT_FAILURE;
  }
  window.RestoreSavedState();
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  CloseHandle(instance_mutex);
  return EXIT_SUCCESS;
}
