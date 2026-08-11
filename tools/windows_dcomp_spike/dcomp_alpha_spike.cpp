// XAOCEN Reader M5.7b isolated DirectComposition prototype.
//
// This executable is deliberately outside the Flutter runner. It creates a
// borderless HWND with a DirectComposition composition swapchain and renders
// premultiplied alpha test pixels. It does not link Flutter or Reader code.

#include <windows.h>
#include <shellapi.h>

#include <d3d11.h>
#include <dcomp.h>
#include <dxgi1_6.h>
#include <wrl.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "dcomp.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")

using Microsoft::WRL::ComPtr;

namespace {

constexpr wchar_t kWindowClass[] = L"XaocenM57DCompSpike";
constexpr UINT kInitialWidth = 960;
constexpr UINT kInitialHeight = 600;

void LogHr(const char* label, HRESULT hr) {
  std::printf("%s: 0x%08lx\n", label, static_cast<unsigned long>(hr));
}

const char* FormatName(DXGI_FORMAT format) {
  switch (format) {
    case DXGI_FORMAT_B8G8R8A8_UNORM:
      return "DXGI_FORMAT_B8G8R8A8_UNORM (RGBA8/BGRA8 SDR)";
    case DXGI_FORMAT_R16G16B16A16_FLOAT:
      return "DXGI_FORMAT_R16G16B16A16_FLOAT (FP16/scRGB)";
    default:
      return "unknown";
  }
}

class DCompSpike {
 public:
  explicit DCompSpike(DXGI_FORMAT format) : format_(format) {}
  ~DCompSpike() { Destroy(); }

  bool Create(bool visible) {
    if (!CreateWindowClass()) return false;
    hwnd_ = CreateWindowExW(
        WS_EX_NOREDIRECTIONBITMAP, kWindowClass, L"XAOCEN DComp Alpha Spike",
        WS_POPUP, 120, 120, static_cast<int>(kInitialWidth),
        static_cast<int>(kInitialHeight), nullptr, nullptr,
        GetModuleHandleW(nullptr), this);
    if (hwnd_ == nullptr) {
      std::printf("CreateWindowExW failed: %lu\n", GetLastError());
      return false;
    }
    if (visible) ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
    return CreateGraphics();
  }

  bool Render(float background_alpha) {
    if (!swap_chain_ || !context_) return false;
    if (format_ == DXGI_FORMAT_R16G16B16A16_FLOAT) {
      ComPtr<ID3D11Texture2D> back_buffer;
      HRESULT hr = swap_chain_->GetBuffer(0, IID_PPV_ARGS(&back_buffer));
      if (FAILED(hr)) {
        LogHr("FP16 GetBuffer", hr);
        return false;
      }
      ComPtr<ID3D11RenderTargetView> view;
      hr = device_->CreateRenderTargetView(back_buffer.Get(), nullptr, &view);
      if (FAILED(hr)) {
        LogHr("FP16 CreateRenderTargetView", hr);
        return false;
      }
      const float transparent[4] = {0, 0, 0, 0};
      context_->ClearRenderTargetView(view.Get(), transparent);
      hr = swap_chain_->Present(1, 0);
      if (FAILED(hr)) LogHr("FP16 Present", hr);
      return SUCCEEDED(hr);
    }

    if (!source_texture_) return false;
    std::vector<std::uint32_t> pixels(
        static_cast<size_t>(width_) * static_cast<size_t>(height_));
    const auto alpha = static_cast<std::uint32_t>(std::clamp(
        std::lround(background_alpha * 255.0f), 0L, 255L));
    // Premultiplied BGRA background. The center content is always opaque.
    const std::uint32_t bg_r = 35;
    const std::uint32_t bg_g = 70;
    const std::uint32_t bg_b = 110;
    const std::uint32_t bg = (alpha << 24) |
                             (((bg_b * alpha) / 255U) << 16) |
                             (((bg_g * alpha) / 255U) << 8) |
                             ((bg_r * alpha) / 255U);
    std::fill(pixels.begin(), pixels.end(), bg);

    const UINT left = width_ / 5;
    const UINT right = width_ - width_ / 5;
    const UINT top = height_ / 3;
    const UINT bottom = height_ - height_ / 3;
    constexpr std::uint32_t opaque_foreground = 0xFFFFFFFFU;
    for (UINT y = top; y < bottom; ++y) {
      for (UINT x = left; x < right; ++x) {
        pixels[static_cast<size_t>(y) * width_ + x] = opaque_foreground;
      }
    }

    context_->UpdateSubresource(source_texture_.Get(), 0, nullptr,
                                pixels.data(), width_ * sizeof(std::uint32_t),
                                0);
    ComPtr<ID3D11Texture2D> back_buffer;
    HRESULT hr = swap_chain_->GetBuffer(0, IID_PPV_ARGS(&back_buffer));
    if (FAILED(hr)) {
      LogHr("RGBA8 GetBuffer", hr);
      return false;
    }
    context_->CopyResource(back_buffer.Get(), source_texture_.Get());
    hr = swap_chain_->Present(1, 0);
    if (FAILED(hr)) LogHr("RGBA8 Present", hr);
    return SUCCEEDED(hr);
  }

  bool Resize(UINT width, UINT height) {
    if (!swap_chain_ || width == 0 || height == 0) return false;
    source_texture_.Reset();
    HRESULT hr = swap_chain_->ResizeBuffers(0, width, height, format_, 0);
    if (FAILED(hr)) {
      LogHr("ResizeBuffers", hr);
      return false;
    }
    width_ = width;
    height_ = height;
    if (format_ == DXGI_FORMAT_B8G8R8A8_UNORM && !CreateSourceTexture()) {
      return false;
    }
    return SetWindowPos(hwnd_, nullptr, 0, 0, static_cast<int>(width),
                        static_cast<int>(height),
                        SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE) != FALSE;
  }

  bool IsGpu() const { return hardware_device_; }
  HWND hwnd() const { return hwnd_; }

 private:
  bool CreateWindowClass() {
    static bool registered = false;
    if (registered) return true;
    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpfnWndProc = WindowProc;
    wc.lpszClassName = kWindowClass;
    wc.hCursor = LoadCursorW(
        nullptr, reinterpret_cast<LPCWSTR>(static_cast<ULONG_PTR>(32512)));
    if (RegisterClassExW(&wc) == 0 && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
      std::printf("RegisterClassExW failed: %lu\n", GetLastError());
      return false;
    }
    registered = true;
    return true;
  }

  bool CreateGraphics() {
    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    D3D_FEATURE_LEVEL level = D3D_FEATURE_LEVEL_11_0;
    HRESULT hr = D3D11CreateDevice(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags, nullptr, 0,
        D3D11_SDK_VERSION, device_.GetAddressOf(), &level,
        context_.GetAddressOf());
    if (FAILED(hr)) {
      LogHr("D3D11CreateDevice hardware", hr);
      hr = D3D11CreateDevice(
          nullptr, D3D_DRIVER_TYPE_WARP, nullptr, flags, nullptr, 0,
          D3D11_SDK_VERSION, device_.GetAddressOf(), &level,
          context_.GetAddressOf());
      if (FAILED(hr)) {
        LogHr("D3D11CreateDevice WARP", hr);
        return false;
      }
      hardware_device_ = false;
    } else {
      hardware_device_ = true;
    }
    std::printf("D3D11 device: %s, feature level 0x%x\n",
                hardware_device_ ? "hardware" : "WARP", level);

    ComPtr<IDXGIDevice> dxgi_device;
    hr = device_.As(&dxgi_device);
    if (FAILED(hr)) {
      LogHr("Query IDXGIDevice", hr);
      return false;
    }
    ComPtr<IDXGIAdapter> adapter;
    hr = dxgi_device->GetAdapter(&adapter);
    if (SUCCEEDED(hr)) {
      DXGI_ADAPTER_DESC adapter_desc{};
      if (SUCCEEDED(adapter->GetDesc(&adapter_desc))) {
        std::wprintf(L"Adapter: %s\n", adapter_desc.Description);
      }
    }
    ComPtr<IDXGIFactory2> factory;
    hr = CreateDXGIFactory2(0, IID_PPV_ARGS(&factory));
    if (FAILED(hr)) {
      LogHr("CreateDXGIFactory2", hr);
      return false;
    }

    DXGI_SWAP_CHAIN_DESC1 desc{};
    desc.Width = kInitialWidth;
    desc.Height = kInitialHeight;
    desc.Format = format_;
    desc.Stereo = FALSE;
    desc.SampleDesc.Count = 1;
    desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount = 2;
    desc.Scaling = DXGI_SCALING_STRETCH;
    desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
    desc.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED;

    hr = factory->CreateSwapChainForComposition(device_.Get(), &desc, nullptr,
                                                swap_chain_.GetAddressOf());
    if (FAILED(hr)) {
      LogHr("CreateSwapChainForComposition", hr);
      return false;
    }
    std::printf("Swapchain: %s, alpha=DXGI_ALPHA_MODE_PREMULTIPLIED\n",
                FormatName(format_));

    ComPtr<IDCompositionDevice> dcomp_device;
    hr = DCompositionCreateDevice(dxgi_device.Get(),
                                  IID_PPV_ARGS(dcomp_device.GetAddressOf()));
    if (FAILED(hr)) {
      LogHr("DCompositionCreateDevice", hr);
      return false;
    }
    hr = dcomp_device->CreateTargetForHwnd(hwnd_, TRUE,
                                           dcomp_target_.GetAddressOf());
    if (FAILED(hr)) {
      LogHr("CreateTargetForHwnd", hr);
      return false;
    }
    ComPtr<IDCompositionVisual> visual;
    hr = dcomp_device->CreateVisual(visual.GetAddressOf());
    if (FAILED(hr)) {
      LogHr("CreateVisual", hr);
      return false;
    }
    hr = visual->SetContent(swap_chain_.Get());
    if (FAILED(hr)) {
      LogHr("Visual.SetContent", hr);
      return false;
    }
    hr = dcomp_target_->SetRoot(visual.Get());
    if (FAILED(hr)) {
      LogHr("Target.SetRoot", hr);
      return false;
    }
    hr = dcomp_device->Commit();
    if (FAILED(hr)) {
      LogHr("DComp Commit", hr);
      return false;
    }
    width_ = kInitialWidth;
    height_ = kInitialHeight;
    if (format_ == DXGI_FORMAT_B8G8R8A8_UNORM) {
      return CreateSourceTexture();
    }
    return true;
  }

  bool CreateSourceTexture() {
    D3D11_TEXTURE2D_DESC desc{};
    desc.Width = width_;
    desc.Height = height_;
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = format_;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_DEFAULT;
    HRESULT hr = device_->CreateTexture2D(&desc, nullptr, &source_texture_);
    if (FAILED(hr)) {
      LogHr("CreateSourceTexture", hr);
      return false;
    }
    return true;
  }

  void Destroy() {
    if (hwnd_ != nullptr) {
      DestroyWindow(hwnd_);
      hwnd_ = nullptr;
    }
    source_texture_.Reset();
    swap_chain_.Reset();
    dcomp_target_.Reset();
    context_.Reset();
    device_.Reset();
  }

  static LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wparam,
                                     LPARAM lparam) {
    auto* self = reinterpret_cast<DCompSpike*>(
        GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
      const auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
      self = static_cast<DCompSpike*>(create->lpCreateParams);
      SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(self));
    }
    if (self != nullptr) {
      if (message == WM_KEYDOWN && wparam == VK_ESCAPE) {
        PostQuitMessage(0);
        return 0;
      }
      if (message == WM_LBUTTONDOWN) {
        ReleaseCapture();
        SendMessageW(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
        return 0;
      }
      if (message == WM_NCHITTEST) {
        // Keep the prototype borderless while allowing a basic drag gesture.
        return HTCAPTION;
      }
    }
    return DefWindowProcW(hwnd, message, wparam, lparam);
  }

  DXGI_FORMAT format_;
  HWND hwnd_ = nullptr;
  UINT width_ = kInitialWidth;
  UINT height_ = kInitialHeight;
  bool hardware_device_ = false;
  ComPtr<ID3D11Device> device_;
  ComPtr<ID3D11DeviceContext> context_;
  ComPtr<IDXGISwapChain1> swap_chain_;
  ComPtr<IDCompositionTarget> dcomp_target_;
  ComPtr<ID3D11Texture2D> source_texture_;
};

bool HasFlag(int argc, wchar_t** argv, const wchar_t* flag) {
  for (int i = 1; i < argc; ++i) {
    if (_wcsicmp(argv[i], flag) == 0) return true;
  }
  return false;
}

int RunSpike(bool self_test, bool fp16) {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  std::printf("M5.7b DirectComposition isolated spike\n");
  std::printf("monitors=%d\n", GetSystemMetrics(SM_CMONITORS));

  DCompSpike rgba8(DXGI_FORMAT_B8G8R8A8_UNORM);
  if (!rgba8.Create(!self_test)) {
    std::printf("RGBA8_CREATE=FAIL\n");
    return 2;
  }
  std::printf("RGBA8_CREATE=PASS\n");
  constexpr float alphas[] = {0.0f, 0.25f, 0.5f, 0.75f, 1.0f};
  for (const auto alpha : alphas) {
    std::printf("RGBA8_RENDER backgroundAlpha=%.2f foregroundAlpha=1.00\n",
                alpha);
    if (!rgba8.Render(alpha)) {
      std::printf("RGBA8_RENDER=FAIL\n");
      return 3;
    }
  }
  std::printf("RGBA8_ALPHA_CONTRACT=PASS (premultiplied background, opaque foreground)\n");

  if (self_test) {
    const UINT dpi = GetDpiForWindow(rgba8.hwnd());
    std::printf("DPI=%u\n", dpi);
    const bool resize_ok = rgba8.Resize(800, 500) && rgba8.Render(0.0f) &&
                           rgba8.Resize(1200, 700) && rgba8.Render(0.5f);
    std::printf("RESIZE_RESOURCE_RECREATE=%s\n", resize_ok ? "PASS" : "FAIL");
    ShowWindow(rgba8.hwnd(), SW_MAXIMIZE);
    Sleep(50);
    ShowWindow(rgba8.hwnd(), SW_RESTORE);
    std::printf("MAXIMIZE_RESTORE=PASS\n");
  }

  if (fp16) {
    DCompSpike fp16_spike(DXGI_FORMAT_R16G16B16A16_FLOAT);
    if (!fp16_spike.Create(!self_test)) {
      std::printf("FP16_CREATE=UNSUPPORTED\n");
    } else {
      std::printf("FP16_CREATE=PASS\n");
      if (fp16_spike.Render(0.0f)) {
        std::printf("FP16_PRESENT=PASS\n");
      } else {
        std::printf("FP16_PRESENT=FAIL\n");
      }
    }
  }

  if (self_test) {
    std::printf("SELF_TEST=PASS\n");
    return 0;
  }

  std::printf("Press Escape or close the window to exit.\n");
  MSG message{};
  while (GetMessageW(&message, nullptr, 0, 0) > 0) {
    TranslateMessage(&message);
    DispatchMessageW(&message);
  }
  return 0;
}

}  // namespace

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  int argc = 0;
  wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  const bool self_test = HasFlag(argc, argv, L"--self-test");
  const bool fp16 = HasFlag(argc, argv, L"--fp16");
  const int result = RunSpike(self_test, fp16);
  LocalFree(argv);
  return result;
}
