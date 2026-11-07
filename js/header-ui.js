/* Keep header popovers inside the visible viewport, including on-screen keyboards. */
(()=>{
 const pairs=[['notificationPanel','notificationBtn'],['globalSearchResults','globalSearch']];
 function place(panel,anchor){
  if(panel.classList.contains('hidden'))return;
  const view=window.visualViewport,left=view?.offsetLeft||0,top=view?.offsetTop||0,width=view?.width||innerWidth,height=view?.height||innerHeight;
  const rect=anchor.getBoundingClientRect(),gap=12,panelWidth=Math.min(380,width-gap*2);
  const x=Math.max(left+gap,Math.min(rect.right-panelWidth,left+width-panelWidth-gap));
  const menu=document.querySelector('#app:not(.hidden) .bottom-nav'),menuTop=menu?.getBoundingClientRect().top;
  const bottom=menuTop>top?Math.min(top+height,menuTop-8):top+height;
  const desired=rect.bottom+10,available=bottom-gap-desired;
  const y=available>=140?desired:top+gap;
  Object.assign(panel.style,{left:x+'px',right:'auto',top:y+'px',width:panelWidth+'px',maxHeight:Math.max(0,bottom-y-gap)+'px'});
 }
 function refresh(){pairs.forEach(([id,anchorId])=>{const panel=document.getElementById(id),anchor=document.getElementById(anchorId);if(panel&&anchor){anchor.setAttribute('aria-expanded',String(!panel.classList.contains('hidden')));place(panel,anchor)}})}
 window.addEventListener('DOMContentLoaded',()=>{
  pairs.forEach(([id,anchorId])=>{const panel=document.getElementById(id),anchor=document.getElementById(anchorId);if(!panel||!anchor)return;anchor.setAttribute('aria-controls',id);anchor.setAttribute('aria-expanded','false');new MutationObserver(refresh).observe(panel,{attributes:true,attributeFilter:['class'],childList:true,subtree:true});});
  document.addEventListener('keydown',event=>{if(event.key!=='Escape')return;pairs.forEach(([id,anchorId])=>{const panel=document.getElementById(id);if(panel&&!panel.classList.contains('hidden')){panel.classList.add('hidden');document.getElementById(anchorId)?.focus()}})});
  refresh();
 });
 window.addEventListener('resize',refresh);window.addEventListener('scroll',refresh,true);
 window.visualViewport?.addEventListener('resize',refresh);window.visualViewport?.addEventListener('scroll',refresh);
})();
