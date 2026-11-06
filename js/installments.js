/* Display summaries only. No writes or payment inference. Amounts in cents. */
(function(root){
 function summarize(entries){
  const grouped=new Map();
  entries.filter(e=>e.recurrence_type==='installments').forEach(e=>{const key=e.series_id||e.id;if(!grouped.has(key))grouped.set(key,[]);grouped.get(key).push(e)});
  return [...grouped.values()].map(rows=>{
   const pending=rows.filter(e=>e.status==='pending').sort((a,b)=>a.due_date.localeCompare(b.due_date)||(a.installment_number||0)-(b.installment_number||0));
   const paid=rows.filter(e=>e.status==='paid');
   const sum=list=>list.reduce((n,e)=>n+Math.round(Number(e.amount)*100),0);
   const paidAmount=sum(paid),remaining=sum(pending),total=paidAmount+remaining;
   return {next:pending[0],paidCount:paid.length,pendingCount:pending.length,registeredCount:rows.length,declaredCount:Math.max(rows.length,...rows.map(e=>Number(e.installment_total)||0)),paidAmount,remaining,total,paidPercent:total?paidAmount/total*100:0};
  }).filter(s=>s.next).sort((a,b)=>a.next.due_date.localeCompare(b.next.due_date));
 }
 root.FinanceInstallments={summarize};
})(typeof window==='undefined'?globalThis:window);
