import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const root="/Users/stefan/git/overall-campaigns/work/impex_aug2026";
const p=JSON.parse(await fs.readFile(root+'/payload.json','utf8'));
const mode=process.argv[2]??'inspect';
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(mode==='verify'?p.target:p.source));
const pro=wb.worksheets.getItem('Variante_Proben'),spring=wb.worksheets.getItem('Variante_Spring'),rr=wb.worksheets.getItem('R'),mt=wb.worksheets.getItem('Tabelle MT');
const edits={};function touch(sh,ref){(edits[sh.name]??=[]).push(ref);}
function value(sh,ref,v){sh.getRange(ref).values=[[v]];touch(sh,ref);}
function formula(sh,ref,v){sh.getRange(ref).formulas=[[v]];touch(sh,ref);}
if(mode==='edit'){
 pro.tables.items.find(t=>t.name==='Table1').rows.add(null,[Array(42).fill(null),Array(42).fill(null)]);
 spring.tables.items.find(t=>t.name==='Table14').rows.add(null,[Array(35).fill(null),Array(35).fill(null)]);
 for(const [i,x] of p.records.entries()){
  const r=13+i,er=10+i;
  for(const sh of [pro,spring]){
   sh.getRange('A'+r+':'+(sh===pro?'AP':'AI')+r).copyFrom(sh.getRange('A'+(11+i)+':'+(sh===pro?'AP':'AI')+(11+i)),'all');
   for(const [c,v] of Object.entries({A:x.barn,B:0,C:'Sommer',D:'Aug-26',E:new Date('2026-07-24T00:00:00Z'),F:new Date(x.slaughter_date+'T00:00:00Z'),G:x.days,H:x.placed,I:x.slaughtered,L:x.net_kg}))value(sh,c+r,v);
   sh.getRange('E'+r+':F'+r).setNumberFormat('dd.mm.yyyy');
   for(const [c,f] of Object.entries({J:'=H'+r+'-I'+r,K:'=H'+r+'*$D$21'}))formula(sh,c+r,f);
  }
  const pp='=';
  for(const [c,f]of Object.entries({
   M:'=L'+r+'/500',N:'=J'+r+'*$D$22',Q:'='+[...x.finisher_deliveries,x.opening_stock].join('+')+'-'+x.closing_stock,
   R:'=SUM(O'+r+':Q'+r+')',S:'=R'+r+'/L'+r,T:'=O'+r+'*Fumi!$F$3/1000',U:'=P'+r+'*Fumi!$F$4/1000',V:'=Q'+r+'*Fumi!$F$5/1000',W:'=SUM(T'+r+':V'+r+')',
   X:'=K'+r+"*'Geflügelgehalte'!$H$6/1000",Y:'=L'+r+"*'Geflügelgehalte'!$H$6/1000",Z:'=Y'+r+'-X'+r,AA:'=W'+r+'-Z'+r,
   AB:'=AA'+r+'/I'+r+'*1000',AC:'=AB'+r+'*$D$29',AD:'=AB'+r+'*$D$23',AE:'=AD'+r+'*$D$29',AF:'=AE'+r+'*$D$28',
   AH:'=AG'+r+'/M'+r+'/(G'+r+'-1)',AJ:'=AI'+r+'*$D$26',AK:'=AI'+r+'*$D$23',AL:'=AJ'+r+'*$D$23',AM:'=AL'+r+'/AE'+r,AN:'=AJ'+r+'/AC'+r
  }))formula(pro,c+r,f);
  value(pro,'O'+r,x.starter_kg);value(pro,'P'+r,x.grower_kg);
  value(pro,'AG'+r,x.nh3_total_g);value(pro,'AI'+r,x.nh3_g_animal);value(pro,'AO'+r,'Aug-26-'+x.barn);value(pro,'AP'+r,9+i);
  value(pro,'F'+(29+i),'Aug-26-'+x.barn);formula(pro,'G'+(29+i),'=I'+r);
  for(const [c,f] of Object.entries({
   M:'=J'+r+'*$D$22',P:'='+[...x.finisher_deliveries,x.opening_stock].join('+')+'-'+x.closing_stock,Q:'=SUM(N'+r+':P'+r+')',R:'=Q'+r+'/L'+r,
   S:'=N'+r+'*Fumi!$F$12/1000',T:'=O'+r+'*Fumi!$F$13/1000',U:'=P'+r+'*Fumi!$F$14/1000',V:'=SUM(S'+r+':U'+r+')',
   W:'=K'+r+"*'Geflügelgehalte'!$H$6/1000",X:'=L'+r+"*'Geflügelgehalte'!$H$6/1000",Y:'=X'+r+'-W'+r,Z:'=V'+r+'-Y'+r,
   AA:'=Z'+r+'/(H'+r+'+J'+r+'/2)*1000',AB:'=AA'+r+'*$D$23',AC:'=AB'+r+'*$D$29',AD:'=AC'+r+'*$D$28',AF:'=AE'+r+'*$D$26',AG:'=AE'+r+'*$D$23',AH:'=AF'+r+'*$D$23',AI:'=AH'+r+'/AC'+r
  }))formula(spring,c+r,f);
  value(spring,'N'+r,x.starter_kg);value(spring,'O'+r,x.grower_kg);value(spring,'AE'+r,x.nh3_g_animal);
  rr.getRange('A'+er+':AI'+er).copyFrom(rr.getRange('A'+(8+i)+':AI'+(8+i)),'all');
  const pc=['A','B','C','D','E','F','G','H','I','J','K','L','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AD','AE','AF','AI','AJ','AK','AL','AM'];
  rr.getRange('E'+er+':F'+er).setNumberFormat('dd.mm.yyyy');
  const cols=Array.from({length:35},(_,j)=>j<26?String.fromCharCode(65+j):'A'+String.fromCharCode(65+j-26));
  cols.forEach((c,j)=>formula(rr,c+er,"='Variante_Proben'!"+pc[j]+r));
  mt.getRange('A'+er+':S'+er).copyFrom(mt.getRange('A'+(8+i)+':S'+(8+i)),'all');
  const rc=['D','A','W','X','Y','V','Z','AA','AB','AC','AD',null,'AF','AH','AI'];
  for(let j=0;j<15;j++)formula(mt,String.fromCharCode(65+j)+er,rc[j]?"='R'!"+rc[j]+er:"='Variante_Proben'!AH"+r);
  value(mt,'P'+er,.125);formula(mt,'Q'+er,'=P'+er+'*I'+er);formula(mt,'R'+er,'=P'+er+'*O'+er);formula(mt,'S'+er,'=P'+er+'*L'+er);
 }
 value(rr,'AJ1','Bilanzstatus');value(rr,'AK1','Quelle');
 for(const r of [10,11]){value(rr,'AJ'+r,'VORLÄUFIG: Futtergehalte 2024, Bestandsfutter als Endmastfutter');value(rr,'AK'+r,p.records[r-10].pdf+'; Variante_Proben Zeile '+(r+3));}
 rr.getRange('AJ1:AK1').copyFrom(rr.getRange('AH1:AI1'),'all');
 value(rr,'AJ1','Bilanzstatus');value(rr,'AK1','Quelle');
 rr.getRange('AJ1:AK11').format.columnWidth=64;
 for(const r of [6,7])value(mt,'P'+r,.125);
 for(const r of [13,14,18,19])for(const c of ['P','Q','S']){
  const rg=mt.getRange(c+r);const f=rg.formulas[0][0];if(f)formula(mt,c+r,f.replaceAll('$9','$11').replaceAll(':B9',':B11').replaceAll(':I9',':I11').replaceAll(':O9',':O11'));
 }
 const notes=[
 'August 2026: Quellen und vorläufige Annahmen',
 'Stall 1 = Halle 9500989; Stall 2 = Halle 9500960.',
 'Tier-/Futtermengen: PDF S. 1, 4-8; Originaldateien im Ordner Mastauswertungen/August 26.',
 'Stall 1: 9500989_27082026.pdf',
 'Stall 2: 9500960_28082026.pdf',
 'Vorläufig: Futter-N aus Laborgehalten 2024 (Fumi F3:F5), vom Nutzer am 29.10.2026 bestätigt.',
 'Annahme wie bisher: Anfangs-/Restbestand gehört zum Endmastfutter; Phase im PDF nicht genannt.',
 'Stall 1: 7 000 + 17 920 + 6 000 - 6 000 = 24 920 kg Futter.',
 'Stall 2: 4 000 + 17 920 + 11 800 - 7 500 = 26 220 kg Futter.',
 'N pro Tier: wie in bisherigen R-Zeilen durch ausgestallte Tiere (8 600 bzw. 8 384).',
 'NH3: kumulierter Messendwert Tag 33,42 aus ergebnisse_bericht/tabelle5_offsetkampagnen_ungerundet.csv.',
 'N-Bilanz: ganzer Mastumtrieb (35/36 Tage). NH3-Quote deckt nur Messperiode ab.',
 'Beide Ställe ohne WRG. N-Jahresfaktor Variante_Proben D23; TAN-Anteil D29.',
 'Variante_Spring bleibt historische Alternative (andere Futtergehalte, Nenner und Jahresfaktor).',
 'Detail1/Detail2 sind historische Pivot-Detailauszüge und werden nicht als laufende Eingabe verwendet.'
 ];
 pro.getRange('AR4:AR18').values=notes.map(t=>[t]);touch(pro,'AR4:AR18');
 pro.getRange('AR4:AR18').format.columnWidth=85;pro.getRange('AR4:AR18').format.wrapText=true;pro.getRange('AR4:AR18').format.rowHeight=32;
 pro.getRange('AR4').format.font.bold=true;
 value(spring,'AK4','August 2026 vorläufig: bisherige Herstellergehalte 2024; Bestandsfutter als Endmastfutter.');
 spring.getRange('AK4').format.columnWidth=80;spring.getRange('AK4').format.wrapText=true;spring.getRange('AK4').format.rowHeight=34;
 wb.recalculate();
 console.log((await wb.inspect({kind:'table',range:"'R'!Z10:AI11",include:'values,formulas',tableMaxRows:2,tableMaxCols:10,maxChars:2500})).ndjson);
 console.log((await wb.inspect({kind:'match',range:"'R'!A10:AI11",searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!|#NULL!',options:{useRegex:true,maxResults:20},maxChars:1000})).ndjson);
 await fs.writeFile(root+'/edits.json',JSON.stringify(edits,null,2));
 await (await SpreadsheetFile.exportXlsx(wb)).save(root+'/candidate.xlsx');
}else{console.log((await wb.inspect({kind:'table',range:"'R'!Z10:AI11",include:'values,formulas',tableMaxRows:2,tableMaxCols:10,maxChars:1800})).ndjson);}
for(const [name,sheetName,range]of(mode==='inspect'?[['vorher','Variante_Proben','A4:J14']]:[['tiere','Variante_Proben','A10:J14'],['bilanz','R','Z8:AC11'],['futter','Variante_Proben','O10:W14']])){
 const img=await wb.render({sheetName,range,scale:1.5,format:'png'});
 await fs.writeFile(root+'/'+mode+'_'+name+'.png',new Uint8Array(await img.arrayBuffer()));
}
