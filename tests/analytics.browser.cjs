const {chromium}=require('playwright');
const fs=require('fs');const assert=require('assert/strict');
(async()=>{
 const path=require('path');const root=path.resolve(__dirname,'..');const artifacts=fs.mkdtempSync(require('os').tmpdir()+'/finance-analytics-');let html=fs.readFileSync(root+'/index.html','utf8');
 const stub=`window.supabase={createClient:()=>({auth:{onAuthStateChange:()=>{},getSession:async()=>({data:{session:null}})}})};`;
 html=html.replace(/<script src="https:[^>]+><\/script>/g,'').replace(/<script>if\(!window.supabase\)[\s\S]*?<\/script>/,'<script>'+stub+'</script>').replace('<script src="./js/analytics.js"></script>','<script>'+fs.readFileSync(root+'/js/analytics.js','utf8')+'</script>');
 const fixture=`
 categories=[{id:'a',name:'Moradia'},{id:'b',name:'Alimentação'},{id:'i',name:'Receitas'}];
 entries=[{id:'1',description:'Salário demonstrativo',amount:5000,entry_type:'income',status:'paid',category_id:'i',month_ref:'2026-11-01',due_date:'2026-11-05'},{id:'2',description:'Aluguel demonstrativo',amount:1500,entry_type:'expense',status:'pending',category_id:'a',month_ref:'2026-11-01',due_date:'2026-11-01'},{id:'3',description:'Mercado demonstrativo',amount:600,entry_type:'expense',status:'paid',category_id:'b',month_ref:'2026-11-01',due_date:'2026-11-03'},{id:'4',description:'Aluguel anterior',amount:1400,entry_type:'expense',status:'paid',category_id:'a',month_ref:'2026-10-01',due_date:'2026-10-01'}];
 month=new Date(2026,10,1);$('authView').classList.add('hidden');$('app').classList.remove('hidden');$('analyticsMonth').value='2026-11';render();setView('analytics');
 `;
 html=html.replace("if('serviceWorker'in navigator)","if(false)").replace('})();\n</script>',fixture+'\n})();\n</script>');
 fs.writeFileSync(artifacts+'/demo.html',html);
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',args:['--no-sandbox']});
 for(const width of [1440,390]){
 const context=await browser.newContext({viewport:{width,height:1000},serviceWorkers:'block'});const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route('**/*',r=>r.abort());await page.setContent(html);
 await page.locator('#analytics.active').waitFor();
 assert.match(await page.locator('#analyticsContent').innerText(),/5\.000,00/);
 await page.selectOption('#analyticsCategory','a');assert.match(await page.locator('#analyticsContent').innerText(),/1\.500,00/);assert.doesNotMatch(await page.locator('#analyticsContent').innerText(),/600,00/);
 await page.selectOption('#analyticsPeriod','12');assert.equal(await page.locator('.analytics-table tbody tr').count(),12);
 await page.locator('#toggleValues').click();assert.doesNotMatch(await page.locator('#analyticsContent').innerText(),/R\$/);assert.equal(await page.locator('#analyticsContent .analytics-bar').count(),0);
 await page.locator('#toggleValues').click();await page.selectOption('#analyticsCategory','');await page.selectOption('#analyticsPeriod','6');
 assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'page overflow '+width);
 await page.screenshot({path:artifacts+'/'+width+'.png',fullPage:true});
 await page.fill('#analyticsMonth','2027-01');assert.match(await page.locator('#analyticsContent').innerText(),/Nenhuma despesa/);
 assert.deepEqual(errors,[]);console.log('PASS browser '+width+': render, category, period, privacy, empty month, no overflow or runtime errors');await context.close();
 }
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
