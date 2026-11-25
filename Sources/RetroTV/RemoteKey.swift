/// The site's keyboard shortcuts (and the app's own actions that share their names),
/// pressed by the remote, the gestures and the Effects panel.
enum RemoteKey: String {
    case power = " "
    case channelUp = "ArrowUp"
    case channelDown = "ArrowDown"
    case volumeUp = "+"
    case volumeDown = "-"
    case mute = "m"
    case noise = "n"
    case glow = "g"
    case blackAndWhite = "b"
    case colorScheme = "c"
    case staticTransition = "o"
    case youtube = "y"
    case fullScreen = "f"
    case immersive = "i"
    case playlist = "p"
    case shuffle = "s"

    /// What the remote's little LED display shows after a press.
    var led: String {
        switch self {
        case .power: return "POWER"
        case .channelUp: return "CH ▲"
        case .channelDown: return "CH ▼"
        case .volumeUp: return "VOL +"
        case .volumeDown: return "VOL −"
        case .mute: return "SFX"
        case .noise: return "NOISE"
        case .glow: return "GLOW"
        case .blackAndWhite: return "B/W"
        case .colorScheme: return "COLOR"
        case .staticTransition: return "STATIC"
        case .youtube: return "YOUTUBE"
        case .fullScreen: return "FULL"
        case .immersive: return "FOCUS"
        case .playlist: return "PLAYLIST"
        case .shuffle: return "SHUFFLE"
        }
    }
}

/// A year on the site's year bar (2000...2009).
struct GuideYear: Identifiable, Equatable {
    let index: Int
    let name: String
    let selected: Bool
    var id: Int { index }
}

/// One of the site's content filters ("Cartoons (4584)").
struct GuideCategory: Identifiable, Equatable {
    let code: String
    let name: String
    let count: Int
    var checked: Bool
    var id: String { code }
}
