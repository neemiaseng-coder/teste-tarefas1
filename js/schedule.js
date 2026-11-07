/* Dates and quantities for the existing 24-month planning window. */
(function(root){
 function integer(value,min,max,label){const n=Number(value);if(!Number.isInteger(n)||n<min||n>max)throw Error(label);return n;}
 function installment(start,total){const count=integer(total,2,120,'Informe de 2 a 120 parcelas.'),first=integer(start,1,count,'A parcela atual deve estar entre 1 e o total de parcelas.');return {first,total:count,count:count-first+1};}
 function interval(value){return integer(value,1,120,'Informe um intervalo de 1 a 120 meses.');}
 function shiftMonth(date,offset){const [year,month,day]=date.split('-').map(Number),target=new Date(Date.UTC(year,month-1+offset,1)),last=new Date(Date.UTC(target.getUTCFullYear(),target.getUTCMonth()+1,0)).getUTCDate();return target.getUTCFullYear()+'-'+String(target.getUTCMonth()+1).padStart(2,'0')+'-'+String(Math.min(day,last)).padStart(2,'0');}
 function recurringDates(date,every){const step=interval(every);return Array.from({length:Math.ceil(24/step)},(_,i)=>shiftMonth(date,i*step));}
 root.FinanceSchedule={installment,interval,shiftMonth,recurringDates};
})(typeof window==='undefined'?globalThis:window);
