import SwiftUI
import UIKit

/// The full-screen TV for whichever set is on. Picking MTV Rewind on a decade set's
/// dial (or a decade on MTV Rewind's) swaps the screen without leaving it.
struct SetScreen: View {
    @State private var current: Decade

    init(start: Decade) {
        _current = State(initialValue: start)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if current.isMTV {
                MTVScreen { switchTo($0) }
                    .transition(.opacity)
            } else {
                TVScreen(decade: current) { switchTo($0) }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: current.isMTV)
    }

    private func switchTo(_ set: Decade) {
        guard set != current else { return }
        current = set
        UserDefaults.standard.set(set.id, forKey: "lastDecade")
        // The old screen turns the idle timer off as it goes; the new TV is still on.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}
