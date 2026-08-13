#include "desktop_color_sampler.h"

#include <windows.h>

#include <iomanip>
#include <sstream>

namespace desktop_color_sampler {
namespace {

std::string WindowsError(const char* operation) {
  std::ostringstream stream;
  stream << operation << " failed (" << GetLastError() << ")";
  return stream.str();
}

}  // namespace

bool SamplePixel(int x, int y, Sample* sample, std::string* error) {
  if (sample == nullptr || error == nullptr) return false;

  const int left = GetSystemMetrics(SM_XVIRTUALSCREEN);
  const int top = GetSystemMetrics(SM_YVIRTUALSCREEN);
  const int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  const int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  if (width <= 0 || height <= 0 || x < left || x >= left + width ||
      y < top || y >= top + height) {
    *error = "coordinate is outside the Windows virtual desktop";
    return false;
  }

  HDC screen = GetDC(nullptr);
  if (screen == nullptr) {
    *error = WindowsError("GetDC");
    return false;
  }
  SetLastError(ERROR_SUCCESS);
  const COLORREF color = GetPixel(screen, x, y);
  const DWORD pixel_error = GetLastError();
  ReleaseDC(nullptr, screen);
  if (color == CLR_INVALID && pixel_error != ERROR_SUCCESS) {
    *error = "GetPixel failed (" + std::to_string(pixel_error) + ")";
    return false;
  }

  sample->point = POINT{x, y};
  sample->color = color;
  return true;
}

}  // namespace desktop_color_sampler
