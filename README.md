# Retro TV (Unofficial)

An unofficial iPhone app that puts two retro TV sites in one living room: [MyRetroTVs](https://www.myretrotvs.com), the retro TV simulator with seven decades of commercials, music videos, news and cartoons, and [MTV Rewind](https://wantmymtv.org) (I Want My MTV), music videos 24/7.

**Not made by or affiliated with MyRetroTVs or MTV Rewind.** Every TV set, channel and clip comes from those sites and YouTube. If you enjoy MyRetroTVs, [support it](https://www.buymeacoffee.com/myretrotvs).

## What's in it

- **Living room:** eight drawn TV sets, one per decade from the 50s to the 2010s plus MTV Rewind, and a "Back to the 80s" card for the last set you watched.
- **One TV screen for every set:** the picture in a glowing frame, a now-playing strip and the native remote (Power, Guide, CH and VOL, Full, the LED readout and a dial with all eight sets). Pick any set on the dial to switch without going back.
- **Decade sets:** Shuffle, Focus, the Picture & Sound panel, the guide with years and categories, and swipes to change channels and decades.
- **MTV Rewind:** CH changes the video, Guide opens the channels, and Years, Search and Saved open the Time Machine, search and your saved videos. Tap the heart on the strip to save a video, and swipe the picture for next or previous.
- **Full screen and landscape:** turn the phone or tap Full for just the picture, then tap it for the remote.
- Sound plays with the silent switch on, and MTV Rewind keeps playing with the screen locked.

## Download

```
https://github.com/hotwheelz3000/retrotv-app/releases/latest
```

The IPA is unsigned. Sign it when installing, for example with Signulous, Sideloadly or AltStore.

## Build

Built with [xtool](https://xtool.sh) (SwiftPM, no Xcode project) on GitHub Actions. Every push to `main` builds the IPA and publishes it as the `latest` release. The app icon is drawn by `scripts/make-app-icon.py`.

All the code is one target, `Sources/RetroTV`. MTV Rewind's player and lists live in `Sources/RetroTV/MTV`, and use the app's own theme.
