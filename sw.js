/* Network-first for same-origin files (you always get the newest app when online);
   the QR libraries and every page asset are pre-cached on install so the whole
   app, including scanning and ID cards, keeps working with no internet connection. */
const C = "attendify-v2";
const CORE = [
  "./",
  "index.html",
  "manifest.webmanifest",
  "manifest-admin.webmanifest",
  "icon-192.png",
  "icon-512.png",
  "https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.js",
  "https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js",
  "config.js"
];

self.addEventListener("install", e => {
  self.skipWaiting();
  e.waitUntil(caches.open(C).then(c => Promise.all(CORE.map(u => c.add(u).catch(() => {})))));
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(k => Promise.all(k.filter(x => x !== C).map(x => caches.delete(x))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const r = e.request;
  if (r.method !== "GET") return;
  e.respondWith(
    fetch(r)
      .then(res => {
        if (res && res.ok) { const cp = res.clone(); caches.open(C).then(c => c.put(r, cp)); }
        return res;
      })
      .catch(() => caches.match(r).then(m => m || (r.mode === "navigate" ? caches.match("index.html") : new Response("", { status: 504, statusText: "Offline" }))))
  );
});
