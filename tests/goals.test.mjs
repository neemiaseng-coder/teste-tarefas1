import test from 'node:test';import assert from 'node:assert/strict';import '../js/goals.js';
const {totals,add}=globalThis.FinanceGoals;const plan={id:'dream',saved_amount:100.1,target_amount:1000};
test('extra savings add to stored value, not to paid entries',()=>{const updated={...plan,saved_amount:add(plan,25.2)};assert.equal(updated.saved_amount,125.3);const t=totals(updated,[{plan_id:'dream',status:'paid',amount:50},{plan_id:'dream',status:'pending',amount:200},{plan_id:'other',status:'paid',amount:999}]);assert.equal(t.saved,17530);assert.equal(t.remaining,82470)});
test('invalid and zero contributions are rejected',()=>{for(const n of [0,-1,NaN,Infinity])assert.throws(()=>add(plan,n))});
test('goal can be exceeded without changing target; progress capped',()=>{const p={...plan,saved_amount:add(plan,1000)};assert.equal(p.target_amount,1000);assert.equal(totals(p,[]).percent,100);assert.equal(totals(p,[]).remaining,0)});
