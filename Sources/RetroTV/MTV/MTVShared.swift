import SwiftUI

/// The MTV Rewind lists, opened from the remote.
enum AppSheet: String, Identifiable {
    case channels, timeMachine, search, saved
    var id: String { rawValue }
}

/// Spacing and corner values for the MTV Rewind sheets, on an 8-point grid.
enum Metrics {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 16
    static let minTap: CGFloat = 44
}
