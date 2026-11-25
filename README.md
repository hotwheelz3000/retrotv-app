# Retro TV (Unofficial)

An unofficial iPhone app that puts two retro TV sites in one living room: [MyRetroTVs](https://www.myretrotvs.com), the retro TV simulator with seven decades of commercials, music videos, news and cartoons, and [MTV Rewind](https://wantmymtv.org) (I Want My MTV), music videos 24/7.

**Not made by or affiliated with MyRetroTVs or MTV Rewind.** Every TV set, channel and clip comes from those sites and YouTube. If you enjoy MyRetroTVs, [support it](https://www.buymeacoffee.com/myretrotvs).

## What's in it

- **Living room:** seven drawn TV sets, one per decade from the 50s to the 2010s, an MTV Rewind card, and a "Back to the 80s" card for the last set you watched.
- **Decade sets:** the native remote (Power, Guide, CH and VOL, Full, Shuffle, Focus, Effects, LED readout, decade dial), the guide, swipe gestures, the Picture & Sound panel, landscape and Focus mode.
- **MTV Rewind:** the full player in its own colors, with the lavender VHS title: channels, Time Machine, search, saved videos and the remote. The back button returns to the living room.
- Sound plays with the silent switch on, and MTV Rewind keeps playing with the screen locked.

## Download

```
https://github.com/hotwheelz3000/retrotv-app/releases/latest
```

The IPA is unsigned. Sign it when installing, for example with Signulous, Sideloadly or AltStore.

## Build

Built with [xtool](https://xtool.sh) (SwiftPM, no Xcode project) on GitHub Actions. Every push to `main` builds the IPA and publishes it as the `latest` release. The app icon is drawn by `scripts/make-app-icon.py`.

The code is two targets: `Sources/RetroTV` (the app and the MyRetroTVs sets) and `Sources/MTVRewind` (the MTV Rewind player, opened from the living room through `MTVRewindScreen`).
