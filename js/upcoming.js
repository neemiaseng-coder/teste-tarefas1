/* Financial calendar in São Paulo; date-only arithmetic avoids UTC/DST shifts. */
(function(root){
 const DAY=86400000;
 function todayKey(now=new Date()){const parts=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Sao_Paulo',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(now);const part=type=>parts.find(p=>p.type===type).value;return part('year')+'-'+part('month')+'-'+part('day');}
 const dayNumber=value=>{const [y,m,d]=value.split('-').map(Number);return Date.UTC(y,m-1,d)/DAY};
 function select(entries,now=new Date()){
  const today=todayKey(now),start=dayNumber(today),end=new Date((start+10)*DAY).toISOString().slice(0,10);
  const rows=entries.filter(e=>e.entry_type==='expense'&&e.status==='pending'&&/^\d{4}-\d{2}-\d{2}$/.test(e.due_date)&&e.due_date<=end).map(e=>({...e,days:dayNumber(e.due_date)-start})).sort((a,b)=>a.due_date.localeCompare(b.due_date)||String(a.description||'').localeCompare(String(b.description||''),'pt-BR'));
  return {today,end,overdue:rows.filter(e=>e.days<0),upcoming:rows.filter(e=>e.days>=0)};
 }
 root.FinanceUpcoming={select,todayKey};
})(typeof window==='undefined'?globalThis:window);
