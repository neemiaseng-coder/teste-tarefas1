const CACHE='financeiro-familiar-v44';
const CORE=['./','./index.html','./manifest.webmanifest','./icon.svg','./styles/banking.css','./js/analytics.js','./js/installments.js','./js/ui-icons.js','./js/app-update.js','./js/header-ui.js','./icons/icon-180.png','./icons/icon-192.png','./icons/icon-512.png','./icons/icon-maskable-512.png'];
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(CORE)).then(()=>self.skipWaiting())));
self.addEventListener('activate',event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith('financeiro-familiar-')&&key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',event=>{
 const request=event.request;
 const url=new URL(request.url);
 if(request.method!=='GET'||url.origin!==location.origin)return;
 if(request.mode==='navigate'||url.pathname.endsWith('/index.html')||url.pathname.endsWith('/')||/\.(?:js|css|webmanifest)$/.test(url.pathname)){
  event.respondWith(fetch(request).then(response=>{
   if(response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(request,copy));}
   return response;
  }).catch(()=>caches.match(request).then(hit=>hit||caches.match(url.origin+url.pathname)).then(hit=>hit||(request.mode==='navigate'?caches.match('./index.html'):Response.error()))));
  return;
 }
 event.respondWith(caches.match(request).then(hit=>hit||fetch(request).then(response=>{
  if(response.ok){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(request,copy));}
  return response;
 })));
});
