/// JavaScript injected into the MyRetroTVs pages.
enum Scripts {
    /// Lets the app press the site's keyboard shortcuts (the site is driven by the
    /// keyboard: Space = power, arrows = channel, -/+ = volume, H = menu...).
    ///
    /// Runs at document start, before the site's own scripts, and notes which key
    /// events the page listens for (keydown, keyup or keypress) so the app sends the
    /// kind the site actually handles. `window.__retroKey('ArrowUp')` presses a key.
    static let keyBridge = #"""
        (function () {
          if (window.__retroKey) return;
          var seen = { keydown: 0, keyup: 0, keypress: 0 };
          var originalAdd = EventTarget.prototype.addEventListener;
          EventTarget.prototype.addEventListener = function (type, listener, options) {
            if (Object.prototype.hasOwnProperty.call(seen, type)) seen[type]++;
            return originalAdd.call(this, type, listener, options);
          };
          var NAMED = {
            ' ': ['Space', 32],
            ArrowUp: ['ArrowUp', 38],
            ArrowDown: ['ArrowDown', 40],
            ArrowLeft: ['ArrowLeft', 37],
            ArrowRight: ['ArrowRight', 39],
            '+': ['Equal', 187],
            '-': ['Minus', 189],
            Escape: ['Escape', 27]
          };
          function describe(key) {
            if (NAMED[key]) return { key: key, code: NAMED[key][0], keyCode: NAMED[key][1] };
            if (/^[0-9]$/.test(key)) return { key: key, code: 'Digit' + key, keyCode: 48 + Number(key) };
            var upper = key.toUpperCase();
            return { key: key, code: 'Key' + upper, keyCode: upper.charCodeAt(0) };
          }
          function fire(type, d) {
            var legacy = type === 'keypress' ? d.key.charCodeAt(0) : d.keyCode;
            var event = new KeyboardEvent(type, {
              key: d.key,
              code: d.code,
              keyCode: legacy,
              which: legacy,
              charCode: type === 'keypress' ? legacy : 0,
              shiftKey: d.key === '+',
              bubbles: true,
              cancelable: true,
              view: window
            });
            // The site reads jQuery's event.which. Safari doesn't always take keyCode/which
            // from the constructor, so set them on the event itself every time.
            var props = { keyCode: legacy, which: legacy, charCode: type === 'keypress' ? legacy : 0 };
            Object.keys(props).forEach(function (name) {
              try {
                Object.defineProperty(event, name, { get: function () { return props[name]; } });
              } catch (e) {}
            });
            var target = document.body || document.documentElement || document;
            target.dispatchEvent(event);
          }
          function hasInline(name) {
            return typeof document[name] === 'function' || typeof window[name] === 'function' ||
              (document.body && typeof document.body[name] === 'function');
          }
          window.__retroKey = function (key) {
            var d = describe(key);
            var down = seen.keydown > 0 || hasInline('onkeydown');
            var press = seen.keypress > 0 || hasInline('onkeypress');
            var up = seen.keyup > 0 || hasInline('onkeyup');
            if (down || (!press && !up)) fire('keydown', d);
            if (press && !down && d.key.length === 1) fire('keypress', d);
            fire('keyup', d);
            return true;
          };
        })();
        """#

    /// Makes the page behave like part of an app: no tap flashes, no long-press
    /// menus on the TV, no pinch zoom, no rubber-band bounce.
    static let appPolish = #"""
        (function () {
          var style = document.createElement('style');
          style.textContent = [
            'html, body { -webkit-tap-highlight-color: transparent !important; overscroll-behavior: none; }',
            'body, img, a, button { -webkit-touch-callout: none; -webkit-user-select: none; user-select: none; }',
            'input, textarea, select { -webkit-user-select: text; user-select: text; }'
          ].join('\n');
          (document.head || document.documentElement).appendChild(style);
          var metas = document.querySelectorAll('meta[name="viewport"]');
          var content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
          if (metas.length) {
            metas.forEach(function (meta) { meta.setAttribute('content', content); });
          } else {
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = content;
            (document.head || document.documentElement).appendChild(meta);
          }
        })();
        """#

    /// The app's own full screen: stretches the YouTube player to fill the whole page,
    /// without relying on the site's F key. `window.__retroFull(true/false)`.
    /// Ancestors of the player lose any transform/filter while it's on, since those
    /// would trap a fixed-position element inside the TV graphic.
    static let fullScreen = #"""
        (function () {
          if (window.__retroFull) return;
          var on = false;
          var style = document.createElement('style');
          style.textContent = [
            'html.retro-full, html.retro-full body { background: #000 !important; overflow: hidden !important; }',
            '[data-retro-anc] { transform: none !important; filter: none !important; perspective: none !important;',
            '  contain: none !important; will-change: auto !important; }',
            '[data-retro-player] { position: fixed !important; inset: 0 !important; width: 100vw !important;',
            '  height: 100vh !important; max-width: none !important; max-height: none !important;',
            '  margin: 0 !important; z-index: 2147483647 !important; background: #000 !important; }'
          ].join('\n');
          function player() {
            var frames = document.querySelectorAll('iframe');
            var best = null, bestArea = 0;
            for (var i = 0; i < frames.length; i++) {
              var f = frames[i];
              var src = f.src || '';
              var r = f.getBoundingClientRect();
              var area = r.width * r.height;
              if (/youtube|youtu\.be/.test(src)) area += 1e9;
              if (area > bestArea) { best = f; bestArea = area; }
            }
            return best || document.querySelector('video');
          }
          function clear() {
            document.querySelectorAll('[data-retro-anc]').forEach(function (el) { el.removeAttribute('data-retro-anc'); });
            document.querySelectorAll('[data-retro-player]').forEach(function (el) { el.removeAttribute('data-retro-player'); });
          }
          function apply() {
            if (!on) return;
            var p = player();
            if (!p) return;
            if (!p.hasAttribute('data-retro-player')) {
              clear();
              p.setAttribute('data-retro-player', '');
              for (var el = p.parentElement; el && el !== document.documentElement; el = el.parentElement) {
                el.setAttribute('data-retro-anc', '');
              }
            }
          }
          var pending = false;
          new MutationObserver(function () {
            if (!on || pending) return;
            pending = true;
            setTimeout(function () { pending = false; apply(); }, 150);
          }).observe(document.documentElement, { childList: true, subtree: true });
          window.__retroFull = function (value) {
            if (!style.parentNode) (document.head || document.documentElement).appendChild(style);
            on = !!value;
            document.documentElement.classList.toggle('retro-full', on);
            if (on) apply(); else clear();
            return on;
          };
        })();
        """#

    /// Reads the TV's state from the page for the app's guide and banners, and lets the
    /// app pick a year or switch categories with the site's own controls.
    ///
    /// Posts to `window.webkit.messageHandlers.retro`:
    ///   {type: 'state', title, channel, years: [{index, name, selected}],
    ///    categories: [{code, name, count, checked}]}
    ///   {type: 'status', text}  (the site's status line: "Tube glow effect is now enabled")
    /// `window.__retroGuide.year(i)`, `.category(code, on)`, `.all()`, `.none()`.
    static let pageState = #"""
        (function () {
          if (window.__retroGuide) return;
          function post(message) {
            try { window.webkit.messageHandlers.retro.postMessage(message); } catch (e) {}
          }
          function text(selector) {
            var el = document.querySelector(selector);
            return el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : '';
          }
          function state() {
            var years = Array.prototype.map.call(document.querySelectorAll('#yearbar .year'), function (el) {
              return { index: Number(el.getAttribute('name')), name: (el.textContent || '').trim(), selected: el.classList.contains('selected') };
            });
            var categories = Array.prototype.map.call(document.querySelectorAll('#tvfilters input[type=checkbox], input[id^="box_"]'), function (box) {
              var label = document.querySelector('label[for="' + box.id + '"]');
              var raw = label ? (label.textContent || '').trim() : box.id;
              var match = raw.match(/^(.*?)\s*\((\d+)\)\s*$/);
              return {
                code: box.id.replace(/^box_/, ''),
                name: match ? match[1] : raw,
                count: match ? Number(match[2]) : 0,
                checked: !!box.checked
              };
            });
            var seen = {};
            categories = categories.filter(function (c) { if (seen[c.code]) return false; seen[c.code] = 1; return true; });
            return { type: 'state', title: text('#lcdbar'), channel: text('#channellabel'), years: years, categories: categories };
          }
          var lastState = '', lastStatus = '';
          function check() {
            var s = state();
            var json = JSON.stringify(s);
            if (json !== lastState) { lastState = json; post(s); }
            var status = text('#statusbar');
            if (status && status !== lastStatus) post({ type: 'status', text: status });
            lastStatus = status;
          }
          var pending = false;
          function schedule() {
            if (pending) return;
            pending = true;
            setTimeout(function () { pending = false; check(); }, 200);
          }
          new MutationObserver(schedule).observe(document.documentElement, {
            childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ['class']
          });
          document.addEventListener('change', schedule, true);
          setInterval(check, 2000);
          check();
          window.__retroGuide = {
            refresh: function () { lastState = ''; check(); },
            year: function (index) {
              var el = document.querySelector('#yearbar .year[name="' + index + '"]');
              if (el) el.click();
              else if (window.__retroKey) window.__retroKey(String(index));
              schedule();
            },
            category: function (code, on) {
              var box = document.getElementById('box_' + code);
              if (box && box.checked !== on) box.click();
              schedule();
            },
            all: function () { var el = document.getElementById('filter_all'); if (el) el.click(); schedule(); },
            none: function () { var el = document.getElementById('filter_none'); if (el) el.click(); schedule(); }
          };
        })();
        """#

    /// Watches the YouTube player's progress messages (infoDelivery) for two jobs:
    ///
    /// - Playlist Mode backup, `window.__retroPlaylist(true/false)`. The site moves to the
    ///   next channel when a clip ends, but its player loops every clip, and on iPhone a
    ///   looping clip may never report that it ended. When the same clip jumps from its
    ///   end back to the start, this presses CH up.
    /// - Resume, `window.__retroResume.mark()` / `.resume()`. iOS pauses the video when
    ///   Notification Center covers the app; this remembers whether a clip was playing
    ///   and tells the player to play again on return.
    static let playerWatch = #"""
        (function () {
          if (window.__retroPlaylist) return;
          var on = false, lastId = '', lastTime = 0, duration = 0, cooldown = 0;
          // Player state for resuming after Notification Center / Control Center:
          // 1 = playing, 2 = paused (YouTube's numbers).
          var state = -1, pausedAt = 0, wasPlaying = false;
          function command(func) {
            document.querySelectorAll('iframe').forEach(function (frame) {
              if (!/youtube/.test(frame.src || '')) return;
              try {
                frame.contentWindow.postMessage(JSON.stringify({ event: 'command', func: func, args: [] }), '*');
              } catch (e) {}
            });
          }
          window.__retroResume = {
            mark: function () {
              wasPlaying = state === 1 || (state === 2 && Date.now() - pausedAt < 3000);
              return wasPlaying;
            },
            resume: function () {
              if (!wasPlaying) return false;
              wasPlaying = false;
              [0, 600, 1500, 3000].forEach(function (delay) {
                setTimeout(function () { if (state !== 1) command('playVideo'); }, delay);
              });
              return true;
            }
          };
          function videoId(info) {
            if (info && info.videoData && info.videoData.video_id) return info.videoData.video_id;
            return (location.hash || '').replace(/^#/, '');
          }
          function advance() {
            var now = Date.now();
            if (now < cooldown) return;
            cooldown = now + 4000;
            if (window.__retroKey) window.__retroKey('ArrowUp');
          }
          window.addEventListener('message', function (event) {
            if (!/^https:\/\/([a-z0-9-]+\.)*youtube(-nocookie)?\.com$/.test(event.origin || '')) return;
            var data = event.data;
            if (typeof data === 'string') { try { data = JSON.parse(data); } catch (e) { return; } }
            if (!data || data.event !== 'infoDelivery' || !data.info) return;
            var info = data.info;
            if (typeof info.playerState === 'number') {
              if (info.playerState === 2 && state !== 2) pausedAt = Date.now();
              state = info.playerState;
            }
            var id = videoId(info);
            if (id !== lastId) { lastId = id; lastTime = 0; duration = 0; }
            if (typeof info.duration === 'number' && info.duration > 0) duration = info.duration;
            if (!on) {
              if (typeof info.currentTime === 'number') lastTime = info.currentTime;
              return;
            }
            if (info.playerState === 0) { setTimeout(function () { if (videoId(null) === id || lastId === id) advance(); }, 2500); }
            if (typeof info.currentTime === 'number') {
              var t = info.currentTime;
              var nearEnd = duration > 0 ? lastTime > duration - 4 : lastTime > 20;
              if (nearEnd && t < 3 && lastTime - t > 5) advance();
              lastTime = t;
            }
          });
          window.__retroPlaylist = function (value) { on = !!value; cooldown = Date.now() + 1500; return on; };
        })();
        """#
}
