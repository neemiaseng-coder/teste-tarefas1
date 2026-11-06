/* Pure calculations; amounts use integer cents. No database writes. */
(function(root){
 const cents=value=>Math.round(Number(value)*100)||0;
 const shift=(month,offset)=>{const [y,m]=month.slice(0,7).split('-').map(Number);const d=new Date(y,m-1+offset,1);return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')};
 function summarize(entries,{month,category='',months=6,today}){
  const eligible=entries.filter(e=>!category||e.category_id===category);
  function totals(key){const rows=eligible.filter(e=>e.month_ref.slice(0,7)===key);const sum=predicate=>rows.filter(predicate).reduce((n,e)=>n+cents(e.amount),0);const income=sum(e=>e.entry_type==='income'),expense=sum(e=>e.entry_type==='expense'),reserve=sum(e=>e.entry_type==='reserve');return {month:key,count:rows.length,income,expense,reserve,balance:income-expense-reserve,received:sum(e=>e.entry_type==='income'&&e.status==='paid'),paid:sum(e=>e.entry_type==='expense'&&e.status==='paid'),pending:sum(e=>e.entry_type==='expense'&&e.status==='pending'),overdue:sum(e=>e.entry_type==='expense'&&e.status==='pending'&&e.due_date<today),installments:sum(e=>e.entry_type==='expense'&&e.recurrence_type==='installments')};}
  const current=totals(month),previous=totals(shift(month,-1)),groups=new Map();
  eligible.filter(e=>e.month_ref.slice(0,7)===month&&e.entry_type==='expense').forEach(e=>groups.set(e.category_id,(groups.get(e.category_id)||0)+cents(e.amount)));
  return {current,previous,variation:previous.expense?(current.expense-previous.expense)/previous.expense*100:null,commitment:current.income?current.installments/current.income*100:null,groups:[...groups].map(([id,value])=>({id,value})).sort((a,b)=>b.value-a.value),trend:Array.from({length:months},(_,i)=>totals(shift(month,i-months+1)))};
 }
 root.FinanceAnalytics={summarize,shift};
})(typeof window==='undefined'?globalThis:window);
