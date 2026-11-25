import AVFoundation
import MTVRewind
import SwiftUI

@main
struct RetroTVApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        MTVRewindInfo.buildLabel = BuildInfo.label
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .tint(Theme.amber)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Play the TV's sound even with the ring/silent switch on, like a video app.
        // With UIBackgroundModes=audio, MTV Rewind keeps playing with the screen locked.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        return true
    }
}
