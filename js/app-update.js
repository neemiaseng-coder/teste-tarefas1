/* Offer an update without clearing sessions or discarding unsaved forms. */
(function(){
 if(!('serviceWorker' in navigator))return;
 function offerUpdate(){
  if(document.getElementById('appUpdateBanner'))return;
  const banner=document.createElement('div');banner.id='appUpdateBanner';banner.setAttribute('role','status');
  const text=document.createElement('span');text.textContent='Uma nova versão está pronta.';
  const button=document.createElement('button');button.type='button';button.textContent='Atualizar agora';
  button.onclick=()=>{if(document.querySelector('.modal.open')&&!confirm('Há uma janela aberta. Atualizar pode descartar alterações ainda não salvas. Continuar?'))return;location.reload()};
  banner.append(text,button);document.body.append(banner);
 }
 let hadController=!!navigator.serviceWorker.controller;
 navigator.serviceWorker.addEventListener('controllerchange',()=>{if(hadController)offerUpdate();hadController=true});
 window.addEventListener('load',async()=>{try{
  const registration=await navigator.serviceWorker.register('./sw.js',{updateViaCache:'none'});
  if(registration.waiting&&navigator.serviceWorker.controller)offerUpdate();
  await registration.update();
  document.addEventListener('visibilitychange',()=>{if(!document.hidden)registration.update().catch(()=>{})});
 }catch(error){console.warn('Não foi possível verificar a atualização:',error)}});
})();
