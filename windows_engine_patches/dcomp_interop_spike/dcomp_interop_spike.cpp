#include <windows.h>
#include <d3d11.h>
#include <dcomp.h>
#include <dxgi1_2.h>
#include <wrl/client.h>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglext_angle.h>
#include <GLES2/gl2.h>

#include <chrono>
#include <cstdio>
#include <cstring>
#include <string>
#include <thread>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dcomp.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "user32.lib")

using Microsoft::WRL::ComPtr;

namespace {

constexpr UINT kWidth = 800;
constexpr UINT kHeight = 500;

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                         LPARAM lparam) {
  if (message == WM_DESTROY) {
    PostQuitMessage(0);
    return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

bool HasExtension(EGLDisplay display, const char* name) {
  const char* all = eglQueryString(display, EGL_EXTENSIONS);
  return all != nullptr && std::strstr(all, name) != nullptr;
}

void PrintEglError(const char* label) {
  std::fprintf(stderr, "%s: EGL error 0x%04x\n", label,
               static_cast<unsigned>(eglGetError()));
}

HWND CreateTestWindow(HINSTANCE instance) {
  WNDCLASSW klass = {};
  klass.hInstance = instance;
  klass.lpfnWndProc = WndProc;
  klass.lpszClassName = L"XAOCEN_DCOMP_INTEROP_SPIKE";
  klass.hCursor = LoadCursor(nullptr, IDC_ARROW);
  if (!RegisterClassW(&klass)) {
    return nullptr;
  }
  HWND hwnd = CreateWindowExW(
      WS_EX_NOREDIRECTIONBITMAP, klass.lpszClassName,
      L"XAOCEN DComp interop spike", WS_OVERLAPPEDWINDOW, 120, 120,
      static_cast<int>(kWidth), static_cast<int>(kHeight), nullptr, nullptr,
      instance, nullptr);
  if (hwnd != nullptr) {
    ShowWindow(hwnd, SW_SHOW);
    // Start-Process -WindowStyle Hidden supplies a hidden startup state; a
    // second explicit show is required for the diagnostic target window.
    ShowWindow(hwnd, SW_SHOWNORMAL);
    UpdateWindow(hwnd);
    SetWindowPos(hwnd, HWND_TOPMOST, 120, 120, static_cast<int>(kWidth),
                 static_cast<int>(kHeight), SWP_SHOWWINDOW);
    SetForegroundWindow(hwnd);
  }
  return hwnd;
}

int Run(HINSTANCE instance) {
  HWND hwnd = CreateTestWindow(instance);
  if (hwnd == nullptr) {
    std::fprintf(stderr, "WINDOW_CREATE=FAIL\n");
    return 2;
  }
  std::printf("HWND=%p\n", hwnd);
  std::fflush(stdout);

  auto get_platform_display =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));
  if (get_platform_display == nullptr) {
    std::fprintf(stderr, "EGL_PLATFORM_DISPLAY=FAIL\n");
    return 3;
  }

  const EGLint display_attributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };
  EGLDisplay display = get_platform_display(
      EGL_PLATFORM_ANGLE_ANGLE, EGL_DEFAULT_DISPLAY, display_attributes);
  if (display == EGL_NO_DISPLAY || eglInitialize(display, nullptr, nullptr) == EGL_FALSE) {
    PrintEglError("EGL_INITIALIZE");
    return 4;
  }

  const char* extensions = eglQueryString(display, EGL_EXTENSIONS);
  std::printf("EGL_EXTENSIONS=%s\n", extensions == nullptr ? "" : extensions);
  const bool texture_extension =
      HasExtension(display, "EGL_ANGLE_d3d_texture_client_buffer");
  const bool share_extension =
      HasExtension(display, "EGL_ANGLE_d3d_share_handle_client_buffer");
  const bool keyed_extension = HasExtension(display, "EGL_ANGLE_keyed_mutex");
  std::printf("EGL_ANGLE_d3d_texture_client_buffer=%s\n",
              texture_extension ? "YES" : "NO");
  std::printf("EGL_ANGLE_d3d_share_handle_client_buffer=%s\n",
              share_extension ? "YES" : "NO");
  std::printf("EGL_ANGLE_keyed_mutex=%s\n",
              keyed_extension ? "YES" : "NO");
  if (!texture_extension) {
    std::fprintf(stderr, "ANGLE_TEXTURE_EXTENSION=FAIL\n");
    return 5;
  }

  const EGLint config_attributes[] = {
      EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8,
      EGL_DEPTH_SIZE, 0, EGL_STENCIL_SIZE, 0, EGL_NONE};
  EGLConfig config = nullptr;
  EGLint config_count = 0;
  if (eglChooseConfig(display, config_attributes, &config, 1, &config_count) ==
          EGL_FALSE ||
      config_count == 0) {
    PrintEglError("EGL_CONFIG");
    return 6;
  }
  const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
  if (context == EGL_NO_CONTEXT) {
    PrintEglError("EGL_CONTEXT");
    return 7;
  }

  auto query_display =
      reinterpret_cast<PFNEGLQUERYDISPLAYATTRIBEXTPROC>(
          eglGetProcAddress("eglQueryDisplayAttribEXT"));
  auto query_device =
      reinterpret_cast<PFNEGLQUERYDEVICEATTRIBEXTPROC>(
          eglGetProcAddress("eglQueryDeviceAttribEXT"));
  EGLAttrib egl_device = 0;
  EGLAttrib d3d_device = 0;
  if (query_display == nullptr || query_device == nullptr ||
      query_display(display, EGL_DEVICE_EXT, &egl_device) != EGL_TRUE ||
      query_device(reinterpret_cast<EGLDeviceEXT>(egl_device),
                   EGL_D3D11_DEVICE_ANGLE, &d3d_device) != EGL_TRUE) {
    std::fprintf(stderr, "ANGLE_D3D11_DEVICE=FAIL\n");
    return 8;
  }
  ComPtr<ID3D11Device> device(reinterpret_cast<ID3D11Device*>(d3d_device));
  if (!device) {
    std::fprintf(stderr, "ANGLE_D3D11_DEVICE=FAIL\n");
    return 9;
  }

  D3D11_TEXTURE2D_DESC texture_desc = {};
  texture_desc.Width = kWidth;
  texture_desc.Height = kHeight;
  texture_desc.MipLevels = 1;
  texture_desc.ArraySize = 1;
  texture_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  texture_desc.SampleDesc.Count = 1;
  texture_desc.Usage = D3D11_USAGE_DEFAULT;
  texture_desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
  ComPtr<ID3D11Texture2D> texture;
  HRESULT hr = device->CreateTexture2D(&texture_desc, nullptr, &texture);
  if (FAILED(hr)) {
    std::fprintf(stderr, "APP_OWNED_TEXTURE=FAIL hr=0x%08lx\n",
                 static_cast<unsigned long>(hr));
    return 10;
  }
  std::printf("APP_OWNED_TEXTURE=PASS format=B8G8R8A8_UNORM alpha=capable\n");

  const EGLint surface_attributes[] = {
      EGL_WIDTH, static_cast<EGLint>(kWidth), EGL_HEIGHT,
      static_cast<EGLint>(kHeight), EGL_NONE};
  EGLSurface pbuffer = eglCreatePbufferFromClientBuffer(
      display, EGL_D3D_TEXTURE_ANGLE,
      reinterpret_cast<EGLClientBuffer>(texture.Get()), config,
      surface_attributes);
  if (pbuffer == EGL_NO_SURFACE ||
      eglMakeCurrent(display, pbuffer, pbuffer, context) != EGL_TRUE) {
    PrintEglError("ANGLE_D3D_TEXTURE_PBUFFER");
    return 11;
  }
  glViewport(0, 0, static_cast<GLsizei>(kWidth), static_cast<GLsizei>(kHeight));
  glDisable(GL_SCISSOR_TEST);
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  glEnable(GL_SCISSOR_TEST);
  glScissor(90, 100, 620, 280);
  glClearColor(1, 1, 1, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  glDisable(GL_SCISSOR_TEST);
  glFinish();
  if (glGetError() != GL_NO_ERROR) {
    std::fprintf(stderr, "ANGLE_RENDER_TO_TEXTURE=FAIL\n");
    return 12;
  }
  std::printf("ANGLE_D3D_TEXTURE=PASS\n");

  ComPtr<IDXGIDevice> dxgi_device;
  if (FAILED(device.As(&dxgi_device))) {
    std::fprintf(stderr, "DXGI_DEVICE=FAIL\n");
    return 13;
  }
  ComPtr<IDXGIFactory2> factory;
  if (FAILED(CreateDXGIFactory2(0, IID_PPV_ARGS(&factory)))) {
    std::fprintf(stderr, "DXGI_FACTORY=FAIL\n");
    return 14;
  }
  DXGI_SWAP_CHAIN_DESC1 swap_desc = {};
  swap_desc.Width = kWidth;
  swap_desc.Height = kHeight;
  swap_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  swap_desc.SampleDesc.Count = 1;
  swap_desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  swap_desc.BufferCount = 2;
  swap_desc.Scaling = DXGI_SCALING_STRETCH;
  swap_desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
  swap_desc.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED;
  ComPtr<IDXGISwapChain1> swapchain;
  if (FAILED(factory->CreateSwapChainForComposition(
          device.Get(), &swap_desc, nullptr, &swapchain))) {
    std::fprintf(stderr, "DCOMP_SWAPCHAIN=FAIL\n");
    return 15;
  }
  ComPtr<IDCompositionDevice> dcomp_device;
  ComPtr<IDCompositionTarget> dcomp_target;
  ComPtr<IDCompositionVisual> dcomp_visual;
  if (FAILED(DCompositionCreateDevice(dxgi_device.Get(),
                                       IID_PPV_ARGS(&dcomp_device))) ||
      FAILED(dcomp_device->CreateTargetForHwnd(
          hwnd, TRUE, dcomp_target.GetAddressOf())) ||
      FAILED(dcomp_device->CreateVisual(dcomp_visual.GetAddressOf())) ||
      FAILED(dcomp_visual->SetContent(swapchain.Get())) ||
      FAILED(dcomp_target->SetRoot(dcomp_visual.Get())) ||
      FAILED(dcomp_device->Commit())) {
    std::fprintf(stderr, "DCOMP_TARGET=FAIL\n");
    return 16;
  }

  ComPtr<ID3D11Texture2D> swap_texture;
  if (FAILED(swapchain->GetBuffer(0, IID_PPV_ARGS(&swap_texture)))) {
    std::fprintf(stderr, "DCOMP_BACKBUFFER=FAIL\n");
    return 17;
  }
  ComPtr<ID3D11DeviceContext> context_d3d;
  device->GetImmediateContext(&context_d3d);
  context_d3d->CopyResource(swap_texture.Get(), texture.Get());
  if (FAILED(swapchain->Present(1, 0)) || FAILED(dcomp_device->Commit())) {
    std::fprintf(stderr, "DCOMP_PRESENT=FAIL\n");
    return 18;
  }
  SetWindowPos(hwnd, HWND_TOPMOST, 120, 120, static_cast<int>(kWidth),
               static_cast<int>(kHeight), SWP_SHOWWINDOW);
  SetForegroundWindow(hwnd);
  std::printf("D3D_TEXTURE_TO_DCOMP=PASS copy=single-diagnostic-frame\n");
  std::printf("BG0_FG100=VISUAL_SCREENSHOT_REQUIRED\n");
  std::fflush(stdout);

  MSG message = {};
  auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(30);
  while (std::chrono::steady_clock::now() < deadline) {
    while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        return 0;
      }
      TranslateMessage(&message);
      DispatchMessage(&message);
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(16));
  }
  // The diagnostic process is intentionally short-lived.  Exit after the
  // screenshot window closes so teardown order cannot mask the interop result
  // with a fixture-only shutdown access violation.
  ExitProcess(0);
}

}  // namespace

int main() {
  return Run(GetModuleHandle(nullptr));
}
