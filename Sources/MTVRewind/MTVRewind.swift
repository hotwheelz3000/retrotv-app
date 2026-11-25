import SwiftUI

/// Black behind the page, so there's no white flash before the player draws.
extension UIColor {
    static let mtvBlack = UIColor.black
}

/// What the Retro TV app sees of this module: the MTV Rewind player screen,
/// and its logo for the living-room card.
public enum MTVRewindInfo {
    /// The app's version line for the About sheet. Retro TV sets it at launch
    /// from its own BuildInfo, which the Build IPA workflow fills in.
    @MainActor public static var buildLabel = "Development build"
}

/// The full MTV Rewind player. `onClose` goes back to the living room.
public struct MTVRewindScreen: View {
    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        ContentView(onClose: onClose)
            .preferredColorScheme(.dark)
    }
}

/// The lavender VHS-style "MTV REWIND" title.
public struct MTVRewindLogo: View {
    private let size: CGFloat

    public init(size: CGFloat = 22) {
        self.size = size
    }

    public var body: some View {
        Wordmark(size: size, alignment: .leading)
    }
}
