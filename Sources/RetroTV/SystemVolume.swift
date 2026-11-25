import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

/// The iPhone's media volume. iOS doesn't let web pages change a video's volume,
/// so the site's own -/+ keys do nothing on a phone; the remote's VOL buttons
/// change the system volume instead, like the side buttons.
@MainActor
final class SystemVolume {
    static let shared = SystemVolume()

    /// An MPVolumeView kept (almost invisibly) on screen. Its slider sets the system
    /// volume, and while it's on screen iOS skips its own volume pop-up, so the
    /// remote's LED is the only indicator.
    let view: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        return view
    }()

    private var slider: UISlider? {
        view.subviews.compactMap { $0 as? UISlider }.first
    }

    /// 0...1
    var level: Float {
        slider?.value ?? AVAudioSession.sharedInstance().outputVolume
    }

    /// Changes the volume by one step (1/16, like the side buttons) and returns the new level.
    @discardableResult
    func step(up: Bool) -> Float {
        let step: Float = 1.0 / 16.0
        let current = (level / step).rounded() * step
        let new = min(1, max(0, current + (up ? step : -step)))
        if let slider {
            slider.setValue(new, animated: false)
            slider.sendActions(for: .valueChanged)
        }
        return new
    }

    /// "VOL ▮▮▮▮▯▯▯▯" for the LED.
    static func meter(_ level: Float) -> String {
        let filled = Int((level * 8).rounded())
        return "VOL " + String(repeating: "▮", count: filled) + String(repeating: "▯", count: 8 - filled)
    }
}

/// Puts the volume view in the window so its slider works.
struct VolumeViewHost: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let host = UIView(frame: .zero)
        host.isUserInteractionEnabled = false
        host.addSubview(SystemVolume.shared.view)
        return host
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
