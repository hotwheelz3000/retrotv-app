import SwiftUI

/// The look of each decade's TV set on the home screen.
enum TVStyle {
    case console     // 50s: wooden floor console with legs
    case spaceAge    // 60s: rounded cabinet on tapered legs
    case woodgrain   // 70s: wood-paneled set with dials
    case boxy        // 80s: black plastic box with buttons
    case crt         // 90s: big grey CRT
    case silver      // 00s: silver widescreen CRT
    case flat        // 10s: thin flat panel on a stand
}

/// One of the TV sets in the living room: the seven decades on myretrotvs.com (each on
/// its own subdomain), plus MTV Rewind (wantmymtv.org) as the eighth set.
struct Decade: Identifiable, Hashable {
    let id: String
    let years: String
    let tagline: String
    let style: TVStyle
    let cabinet: [Color]
    let glow: Color

    var url: URL {
        if isMTV { return URL(string: "https://wantmymtv.org/") ?? URL(fileURLWithPath: "/") }
        return URL(string: "https://\(id).myretrotvs.com/") ?? URL(fileURLWithPath: "/")
    }

    /// The MTV Rewind set, which plays music videos instead of a decade's TV.
    var isMTV: Bool { id == Decade.mtv.id }

    /// "the 80s", or "MTV Rewind".
    var name: String { isMTV ? "MTV Rewind" : "the \(id)" }

    static func == (lhs: Decade, rhs: Decade) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [Decade] = [
        Decade(
            id: "50s", years: "1950–1959", tagline: "Black & white broadcasts", style: .console,
            cabinet: [Color(red: 0.42, green: 0.25, blue: 0.14), Color(red: 0.24, green: 0.13, blue: 0.07)],
            glow: Color(red: 0.80, green: 0.86, blue: 0.95)
        ),
        Decade(
            id: "60s", years: "1960–1969", tagline: "Space age & soul", style: .spaceAge,
            cabinet: [Color(red: 0.36, green: 0.62, blue: 0.60), Color(red: 0.17, green: 0.34, blue: 0.33)],
            glow: Color(red: 0.86, green: 0.92, blue: 0.88)
        ),
        Decade(
            id: "70s", years: "1970–1979", tagline: "Disco & wood paneling", style: .woodgrain,
            cabinet: [Color(red: 0.58, green: 0.36, blue: 0.17), Color(red: 0.33, green: 0.19, blue: 0.08)],
            glow: Color(red: 1.0, green: 0.62, blue: 0.24)
        ),
        Decade(
            id: "80s", years: "1980–1989", tagline: "Neon & mixtapes", style: .boxy,
            cabinet: [Color(red: 0.20, green: 0.19, blue: 0.21), Color(red: 0.08, green: 0.08, blue: 0.09)],
            glow: Color(red: 1.0, green: 0.30, blue: 0.62)
        ),
        Decade(
            id: "90s", years: "1990–1999", tagline: "Cable & Saturday cartoons", style: .crt,
            cabinet: [Color(red: 0.46, green: 0.46, blue: 0.48), Color(red: 0.24, green: 0.24, blue: 0.26)],
            glow: Color(red: 0.36, green: 0.86, blue: 0.62)
        ),
        Decade(
            id: "00s", years: "2000–2009", tagline: "Ringtones & reality TV", style: .silver,
            cabinet: [Color(red: 0.78, green: 0.80, blue: 0.83), Color(red: 0.46, green: 0.48, blue: 0.52)],
            glow: Color(red: 0.36, green: 0.66, blue: 1.0)
        ),
        Decade(
            id: "10s", years: "2010–2019", tagline: "Viral videos & HD", style: .flat,
            cabinet: [Color(red: 0.14, green: 0.14, blue: 0.16), Color(red: 0.05, green: 0.05, blue: 0.06)],
            glow: Color(red: 0.70, green: 0.48, blue: 1.0)
        ),
    ]

    /// MTV Rewind: music videos 24/7, on a dark CRT with a lavender glow.
    static let mtv = Decade(
        id: "MTV", years: "MTV Rewind", tagline: "Music videos 24/7", style: .crt,
        cabinet: [Color(red: 0.27, green: 0.21, blue: 0.34), Color(red: 0.11, green: 0.08, blue: 0.15)],
        glow: Color(red: 0.66, green: 0.61, blue: 0.85)
    )

    /// Every set in the living room and on the dial: the seven decades, then MTV Rewind.
    static let sets: [Decade] = all + [mtv]

    static func with(id: String) -> Decade? {
        sets.first { $0.id == id }
    }

    /// The next and previous decade (swipes on a decade set). MTV Rewind isn't one.
    var next: Decade? {
        guard let index = Decade.all.firstIndex(of: self), index + 1 < Decade.all.count else { return nil }
        return Decade.all[index + 1]
    }

    var previous: Decade? {
        guard let index = Decade.all.firstIndex(of: self), index > 0 else { return nil }
        return Decade.all[index - 1]
    }
}
