#ifndef RUNNER_WINDOW_FULLSCREEN_H_
#define RUNNER_WINDOW_FULLSCREEN_H_

#include <windows.h>

namespace singbook {

// Borderless fullscreen on the window's monitor, with its previous normal or
// maximized placement restored when leaving. Never makes the app topmost.
class WindowFullscreen {
 public:
  explicit WindowFullscreen(HWND window) : window_(window) {}

  bool enabled() const { return enabled_; }
  bool changing() const { return changing_; }

  bool UpdateBounds() {
    MONITORINFO monitor = {};
    monitor.cbSize = sizeof(monitor);
    if (!GetMonitorInfoW(MonitorFromWindow(window_, MONITOR_DEFAULTTONEAREST),
                         &monitor)) {
      return false;
    }
    const auto& bounds = monitor.rcMonitor;
    const bool was_changing = changing_;
    changing_ = true;
    const bool updated =
        SetWindowPos(window_, nullptr, bounds.left, bounds.top,
                     bounds.right - bounds.left, bounds.bottom - bounds.top,
                     SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOACTIVATE |
                         SWP_FRAMECHANGED) != FALSE;
    changing_ = was_changing;
    return updated;
  }

  bool SetEnabled(bool enabled) {
    if (enabled == enabled_) return true;
    if (enabled) {
      WINDOWPLACEMENT placement = {};
      placement.length = sizeof(placement);
      if (!GetWindowPlacement(window_, &placement)) return false;
      const auto style = GetWindowLongPtrW(window_, GWL_STYLE);
      const auto ex_style = GetWindowLongPtrW(window_, GWL_EXSTYLE);
      changing_ = true;
      if (!SetStyle(GWL_STYLE, style & ~(WS_OVERLAPPEDWINDOW | WS_MAXIMIZE)) ||
          !SetStyle(GWL_EXSTYLE,
                    ex_style & ~(WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE |
                                 WS_EX_DLGMODALFRAME | WS_EX_STATICEDGE)) ||
          !UpdateBounds()) {
        SetStyle(GWL_STYLE, style);
        SetStyle(GWL_EXSTYLE, ex_style);
        SetWindowPlacement(window_, &placement);
        RefreshFrame();
        changing_ = false;
        return false;
      }
      placement_ = placement;
      style_ = style;
      ex_style_ = ex_style;
      enabled_ = true;
      changing_ = false;
      return true;
    }
    // Keep the snapshot until every restore operation succeeds, allowing a
    // failed restore to be retried without recording the fullscreen rectangle.
    changing_ = true;
    const bool style_restored = SetStyle(GWL_STYLE, style_);
    const bool ex_style_restored = SetStyle(GWL_EXSTYLE, ex_style_);
    const bool placement_restored =
        SetWindowPlacement(window_, &placement_) != FALSE;
    const bool frame_restored = RefreshFrame();
    changing_ = false;
    if (!style_restored || !ex_style_restored || !placement_restored ||
        !frame_restored) {
      return false;
    }
    enabled_ = false;
    return true;
  }

 private:
  bool SetStyle(int index, LONG_PTR style) const {
    SetLastError(ERROR_SUCCESS);
    return SetWindowLongPtrW(window_, index, style) != 0 ||
           GetLastError() == ERROR_SUCCESS;
  }

  bool RefreshFrame() const {
    return SetWindowPos(window_, nullptr, 0, 0, 0, 0,
                        SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                            SWP_NOOWNERZORDER | SWP_NOACTIVATE |
                            SWP_FRAMECHANGED) != FALSE;
  }

  HWND window_;
  bool enabled_ = false;
  bool changing_ = false;
  LONG_PTR style_ = 0;
  LONG_PTR ex_style_ = 0;
  WINDOWPLACEMENT placement_ = {};
};

}  // namespace singbook

#endif  // RUNNER_WINDOW_FULLSCREEN_H_
