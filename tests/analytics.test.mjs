import test from 'node:test';
import assert from 'node:assert/strict';
import '../js/analytics.js';
const {summarize,shift}=globalThis.FinanceAnalytics;
const entry=(amount,entry_type='expense',other={})=>({amount,entry_type,month_ref:'2026-11-01',due_date:'2026-11-05',status:'pending',category_id:'a',...other});
const analyze=entries=>summarize(entries,{month:'2026-11',today:'2026-11-06',months:6});
test('separates cash received, commitments and reserves in cents',()=>{
 const d=analyze([entry(1000,'income',{status:'paid'}),entry(100.10),entry(0.20),entry(50,'expense',{status:'paid'}),entry(80,'reserve')]).current;
 assert.equal(d.income,100000);assert.equal(d.received,100000);assert.equal(d.expense,15030);assert.equal(d.pending,10030);assert.equal(d.paid,5000);assert.equal(d.balance,76970);assert.equal(d.overdue,10030);
});
test('due today and paid entries are not overdue',()=>{assert.equal(analyze([entry(20,'expense',{due_date:'2026-11-06'}),entry(40,'expense',{status:'paid'})]).current.overdue,0)});
test('category filter also applies to previous month and trend',()=>{
 const d=summarize([entry(100),entry(50,'expense',{month_ref:'2026-10-01'}),entry(900,'expense',{category_id:'b'})],{month:'2026-11',category:'a',months:6,today:'2026-11-06'});
 assert.equal(d.current.expense,10000);assert.equal(d.variation,100);assert.equal(d.groups.length,1);assert.equal(d.trend.length,6);assert.equal(d.trend.at(-1).expense,10000);
});
test('empty history and zero income do not create invalid percentages',()=>{const d=analyze([]);assert.equal(d.variation,null);assert.equal(d.commitment,null);assert.equal(d.current.balance,0)});
test('installment commitment and year boundaries',()=>{const d=analyze([entry(1000,'income'),entry(250,'expense',{recurrence_type:'installments'})]);assert.equal(d.commitment,25);assert.equal(shift('2026-01',-1),'2025-12');assert.equal(shift('2026-12',1),'2027-01')});
