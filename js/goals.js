/* Read-only goal calculations. Paid reserves remain separate from extra savings. */
(function(root){
 const cents=value=>Math.round(Number(value)*100);
 function totals(plan,entries){const extra=cents(plan.saved_amount),paid=entries.filter(e=>e.plan_id===plan.id&&e.status==='paid').reduce((n,e)=>n+cents(e.amount),0),target=cents(plan.target_amount),saved=extra+paid;return {saved,target,remaining:Math.max(0,target-saved),percent:target?Math.min(100,saved/target*100):0};}
 function add(plan,amount){const value=cents(amount),existing=cents(plan.saved_amount);if(!Number.isSafeInteger(value)||value<=0||!Number.isSafeInteger(existing+value))throw Error('Informe um valor adicional válido maior que zero.');return (existing+value)/100;}
 root.FinanceGoals={totals,add};
})(typeof window==='undefined'?globalThis:window);
