#ifndef RUNNER_WINDOW_CLOSE_GUARD_H_
#define RUNNER_WINDOW_CLOSE_GUARD_H_

#include <chrono>
#include <functional>
#include <memory>
#include <utility>

namespace singbook {

// A close request must finish before another can begin. Missing/error replies
// are cancellations; destroying the window invalidates outstanding replies.
// A request that stays unanswered for kReplyTimeout (an unresponsive Dart
// isolate) no longer blocks the window: the next close attempt closes natively.
class WindowCloseGuard {
 public:
  using Completion = std::function<void(bool)>;
  using RequestExit = std::function<void(Completion)>;
  using Clock = std::function<std::chrono::steady_clock::time_point()>;

  static constexpr std::chrono::seconds kReplyTimeout{10};

  WindowCloseGuard(RequestExit request_exit, std::function<bool()> close_window,
                   Clock now = [] { return std::chrono::steady_clock::now(); })
      : request_exit_(std::move(request_exit)),
        close_window_(std::move(close_window)), now_(std::move(now)),
        state_(std::make_shared<State>()) {}

  void RequestClose() {
    if (state_->approved) return;
    if (state_->pending) {
      if (now_() - state_->requested_at < kReplyTimeout) return;
      // No reply in time. Invalidate the outstanding request so a late answer
      // is ignored, then close without asking again.
      state_->pending = false;
      ++state_->generation;
      state_->approved = true;
      if (!close_window_()) state_->approved = false;
      return;
    }
    state_->pending = true;
    state_->requested_at = now_();
    const auto generation = ++state_->generation;
    std::weak_ptr<State> weak = state_;
    request_exit_([weak, generation, close = close_window_](bool approved) {
      const auto state = weak.lock();
      if (!state || !state->pending || state->generation != generation) return;
      state->pending = false;
      if (approved) {
        state->approved = true;
        if (!close()) state->approved = false;
      }
    });
  }

  WindowCloseGuard(const WindowCloseGuard&) = delete;
  WindowCloseGuard& operator=(const WindowCloseGuard&) = delete;

 private:
  struct State {
    bool pending = false;
    bool approved = false;
    unsigned long long generation = 0;
    std::chrono::steady_clock::time_point requested_at{};
  };
  RequestExit request_exit_;
  std::function<bool()> close_window_;
  Clock now_;
  std::shared_ptr<State> state_;
};

}  // namespace singbook
#endif  // RUNNER_WINDOW_CLOSE_GUARD_H_
