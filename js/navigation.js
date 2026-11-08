/* One back step to Home; the next step remains native browser/PWA navigation. */
(function(root){
 root.FinanceNavigation={create(onHome,isActive){
  const key='financeNavigation';let started=false,handlingBack=false;
  function start(){
   started=true;
   if(history.state?.[key]==='guard')return;
   history.replaceState({...history.state,[key]:'base'},'',location.href);
   history.pushState({...history.state,[key]:'guard'},'',location.href);
  }
  function visit(view){if(started&&!handlingBack&&view!=='startView'&&history.state?.[key]!=='guard')start();}
  addEventListener('popstate',()=>{
   if(!started||!isActive())return;
   if(!['base','guard'].includes(history.state?.[key]))return;
   handlingBack=true;try{onHome();}finally{handlingBack=false;}
  });
  return {start,visit};
 }};
})(window);
