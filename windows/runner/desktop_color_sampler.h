#ifndef RUNNER_DESKTOP_COLOR_SAMPLER_H_
#define RUNNER_DESKTOP_COLOR_SAMPLER_H_

#include <windows.h>

#include <string>

namespace desktop_color_sampler {

struct Sample {
  POINT point{};
  COLORREF color = CLR_INVALID;
};

// Samples one physical coordinate in the Windows virtual desktop DC. No
// screenshot or Flutter surface readback is used.
bool SamplePixel(int x, int y, Sample* sample, std::string* error);

}  // namespace desktop_color_sampler

#endif  // RUNNER_DESKTOP_COLOR_SAMPLER_H_
