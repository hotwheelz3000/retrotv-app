import SwiftUI

/// Black behind the page, so there's no white flash before the player draws.
extension UIColor {
    static let mtvBlack = UIColor.black
}

/// The full MTV Rewind player, opened from the living room. `onClose` goes back.
struct MTVRewindScreen: View {
    let onClose: () -> Void

    var body: some View {
        MTVContentView(onClose: onClose)
            .preferredColorScheme(.dark)
    }
}

/// The lavender VHS-style "MTV REWIND" title, for the living-room card.
struct MTVRewindLogo: View {
    var size: CGFloat = 22

    var body: some View {
        Wordmark(size: size, alignment: .leading)
    }
}
