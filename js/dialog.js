/* In-app dialogs (Android / Material style) replacing the browser's own pop-ups. */
(function(root){
 let queue=Promise.resolve();
 function show({title,message,ok='OK',cancel=null,value=null,danger=false}){
  return new Promise(resolve=>{
   const previous=document.activeElement,wrap=document.createElement('div');wrap.className='app-dialog';
   const box=document.createElement('div');box.className='app-dialog-box';box.setAttribute('role',cancel?'alertdialog':'dialog');box.setAttribute('aria-modal','true');box.setAttribute('aria-labelledby','appDialogTitle');box.setAttribute('aria-describedby','appDialogMessage');
   const add=(tag,props)=>{const el=document.createElement(tag);Object.assign(el,props);box.append(el);return el};
   add('h3',{id:'appDialogTitle',textContent:title});add('p',{id:'appDialogMessage',textContent:message});
   const input=value===null?null:add('input',{type:'text',value,maxLength:60});if(input)input.setAttribute('aria-label',message);
   const actions=add('div',{className:'app-dialog-actions'});
   const button=(label,kind)=>{const b=document.createElement('button');b.type='button';b.textContent=label;b.dataset.dialog=kind;actions.append(b);return b};
   const no=cancel?button(cancel,'cancel'):null,yes=button(ok,'ok');if(danger)yes.classList.add('is-danger');
   function close(accepted){document.removeEventListener('keydown',key,true);removeEventListener('popstate',back);wrap.remove();if(previous?.isConnected)previous.focus({preventScroll:true});resolve(input?(accepted?input.value:null):accepted)}
   function key(ev){
    if(ev.key==='Escape'){ev.preventDefault();ev.stopPropagation();close(false)}
    else if(ev.key==='Enter'&&input&&ev.target===input){ev.preventDefault();close(true)}
    else if(ev.key==='Tab'){const items=[...box.querySelectorAll('input,button')],i=items.indexOf(document.activeElement);ev.preventDefault();items[(i+(ev.shiftKey?-1:1)+items.length)%items.length].focus()}
   }
   function back(){close(false)}
   yes.onclick=()=>close(true);if(no)no.onclick=()=>close(false);
   wrap.addEventListener('click',ev=>{ev.stopPropagation();if(ev.target===wrap)close(false)});
   document.addEventListener('keydown',key,true);addEventListener('popstate',back);
   wrap.append(box);document.body.append(wrap);(input||no||yes).focus({preventScroll:true});
  });
 }
 const enqueue=options=>{const next=queue.then(()=>show(options));queue=next.catch(()=>{});return next};
 root.AppDialog={
  confirm:(message,o={})=>enqueue({title:'Confirmar',ok:'Confirmar',cancel:'Cancelar',...o,message}),
  alert:(message,o={})=>enqueue({title:'Aviso',...o,message}),
  prompt:(message,value='',o={})=>enqueue({title:'Editar',ok:'Salvar',cancel:'Cancelar',...o,message,value})
 };
})(window);
