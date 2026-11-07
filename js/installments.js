/* Display-only reconciliation. Never writes or assumes a payment status. */
(function(root){
 const cents=value=>Math.round(Number(value)*100)||0;
 const title=value=>String(value||'').replace(/\s*\(\d+\/\d+\)\s*$/,'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,' ').trim().replace(/\bnubanck\b/g,'nubank');
 const month=value=>{const [year,m]=String(value).slice(0,7).split('-').map(Number);return year*12+m-1};
 function sameTitle(a,b){if(a===b)return true;if(Math.min(a.length,b.length)<16||Math.abs(a.length-b.length)>1)return false;let i=0,j=0,differences=0;while(i<a.length&&j<b.length){if(a[i]===b[j]){i++;j++;continue}if(++differences>1)return false;if(a.length>=b.length)i++;if(b.length>=a.length)j++}return differences+(a.length-i)+(b.length-j)<=1;}
 function reconcile(entries){
  const grouped=new Map();
  entries.filter(e=>e.recurrence_type==='installments').forEach(e=>{const key=e.series_id||e.id;if(!grouped.has(key))grouped.set(key,{key,current:[],history:[],review:[]});grouped.get(key).current.push(e)});
  const groups=[...grouped.values()];
  groups.forEach(g=>{g.anchor=[...g.current].sort((a,b)=>a.due_date.localeCompare(b.due_date))[0];g.name=title(g.anchor.description);g.declared=Math.max(...g.current.map(e=>Number(e.installment_total)||0));const offsets=new Set(g.current.map(e=>month(e.due_date)-Number(e.installment_number)));g.offset=offsets.size===1?[...offsets][0]:null;g.slots=new Set(g.current.map(e=>Number(e.installment_number)));});
  const suggestions=[];
  entries.filter(e=>e.recurrence_type!=='installments'&&String(e.notes||'').includes('IMPORT_GRANNA_2026_FEV_OUT_V1')).forEach(e=>{
   const names=groups.filter(g=>e.entry_type===g.anchor.entry_type&&e.due_date<g.anchor.due_date&&sameTitle(title(e.description),g.name));
   const eligible=names.filter(g=>{const n=month(e.due_date)-g.offset;return title(e.description)===g.name&&g.offset!==null&&Number.isInteger(n)&&n>=1&&n<=g.declared&&!g.slots.has(n)&&e.due_date.slice(8,10)===g.anchor.due_date.slice(8,10)&&cents(e.amount)>1&&cents(e.amount)===cents(g.anchor.amount)});
   if(eligible.length===1){const g=eligible[0];suggestions.push({group:g,entry:e,number:month(e.due_date)-g.offset})}else names.forEach(g=>g.review.push(e));
  });
  const slotCounts=new Map();suggestions.forEach(s=>{const key=s.group.key+':'+s.number;slotCounts.set(key,(slotCounts.get(key)||0)+1)});
  suggestions.forEach(s=>{if(slotCounts.get(s.group.key+':'+s.number)!==1){s.group.review.push(s.entry);return}s.group.history.push({...s.entry,installment_number:s.number,installment_total:s.group.declared})});
  return groups;
 }
 function summarize(entries){return reconcile(entries).map(g=>{
  const rows=g.current.concat(g.history),pending=rows.filter(e=>e.status==='pending').sort((a,b)=>a.due_date.localeCompare(b.due_date)||(a.installment_number||0)-(b.installment_number||0)),paid=rows.filter(e=>e.status==='paid'),sum=list=>list.reduce((n,e)=>n+cents(e.amount),0),paidAmount=sum(paid),remaining=sum(pending),total=paidAmount+remaining;
  return {title:String(g.anchor.description||'Parcelamento').replace(/\s*\(\d+\/\d+\)\s*$/,''),next:pending[0],paidCount:paid.length,pendingCount:pending.length,registeredCount:rows.length,declaredCount:Math.max(rows.length,g.declared),paidAmount,remaining,total,paidPercent:total?paidAmount/total*100:0,historyCount:g.history.length,historyRows:g.history.sort((a,b)=>a.due_date.localeCompare(b.due_date)),reviewCount:g.review.length,reviewRows:g.review.sort((a,b)=>a.due_date.localeCompare(b.due_date))};
 }).filter(s=>s.next).sort((a,b)=>a.next.due_date.localeCompare(b.next.due_date));}
 root.FinanceInstallments={summarize,reconcile};
})(typeof window==='undefined'?globalThis:window);
