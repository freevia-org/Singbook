#ifndef RUNNER_WINDOW_CLOSE_GUARD_H_
#define RUNNER_WINDOW_CLOSE_GUARD_H_

#include <functional>
#include <memory>
#include <utility>

namespace singbook {

// A close request must finish before another can begin. Missing/error replies
// are cancellations; destroying the window invalidates outstanding replies.
class WindowCloseGuard {
 public:
  using Completion = std::function<void(bool)>;
  using RequestExit = std::function<void(Completion)>;

  WindowCloseGuard(RequestExit request_exit, std::function<bool()> close_window)
      : request_exit_(std::move(request_exit)),
        close_window_(std::move(close_window)), state_(std::make_shared<State>()) {}

  void RequestClose() {
    if (state_->pending || state_->approved) return;
    state_->pending = true;
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
  };
  RequestExit request_exit_;
  std::function<bool()> close_window_;
  std::shared_ptr<State> state_;
};

}  // namespace singbook
#endif  // RUNNER_WINDOW_CLOSE_GUARD_H_
