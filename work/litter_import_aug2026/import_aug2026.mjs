import fs from 'node:fs/promises';
import {FileBlob,SpreadsheetFile} from '@oai/artifact-tool';
const root='/Users/stefan/git/overall-campaigns/work/litter_import_aug2026';
const p=JSON.parse(await fs.readFile(root+'/payload.json','utf8'));
const mode=process.argv[2]??'inspect';
const input=mode==='verify'?p.target:p.target;
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(input));
const sh=wb.worksheets.getItem(p.sheet);
if(mode==='inspect'){
 console.log((await wb.inspect({kind:'workbook,sheet,table',maxChars:2200,tableMaxRows:2,tableMaxCols:4})).ndjson);
 const preview=await wb.render({sheetName:p.sheet,range:'A1:I8',scale:1.5,format:'png'});
 await fs.writeFile(root+'/vorher.png',new Uint8Array(await preview.arrayBuffer()));
 console.log('Vorschau vor Bearbeitung erstellt.');
}else if(mode==='edit'){
 const table=sh.tables.items.find(t=>t.name===p.table);
 if(!table)throw new Error('Bestehende Tabelle nicht gefunden');
 table.rows.add(null,p.rows);
 for(let r=p.oldLastRow+1;r<=p.newLastRow;r++)sh.getRange('A'+r+':AD'+r).copyFrom(sh.getRange('A'+p.oldLastRow+':AD'+p.oldLastRow),'all');
 sh.getRange('A154:AD184').values=p.rows;
 sh.getRange('AC154').formulas=[['=100-G154']];
 sh.getRange('AC154:AC184').fillDown();
 sh.getRange('AD154').formulas=[['=H154*G154/100']];
 sh.getRange('AD154:AD184').fillDown();
 wb.recalculate();
 console.log((await wb.inspect({kind:'table',range:"'Sheet 1'!AB154:AD158",include:'values,formulas',tableMaxRows:5,tableMaxCols:3,maxChars:1800})).ndjson);
 const errors=await wb.inspect({kind:'match',range:"'Sheet 1'!A154:AD184",searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\\\?|#N/A|#NUM!|#NULL!',options:{useRegex:true,maxResults:20},maxChars:1200});
 console.log(errors.ndjson);
 for(const [name,range] of [['nachher','A150:I163'],['kennzahlen','AB150:AD163']]){
  const preview=await wb.render({sheetName:p.sheet,range,scale:1.5,format:'png'});
  await fs.writeFile(root+'/'+name+'.png',new Uint8Array(await preview.arrayBuffer()));
 }
 const out=await SpreadsheetFile.exportXlsx(wb);
 await out.save(root+'/litter_appended_candidate.xlsx');
 console.log('31 Datensaetze ergaenzt und Berechnungen geprueft; Zwischenexport fuer Erhalt der nativen Excel-Pivots erstellt.');
}else{
 console.log((await wb.inspect({kind:'table',range:"'Sheet 1'!AB180:AD184",include:'values,formulas',tableMaxRows:5,tableMaxCols:3,maxChars:1800})).ndjson);
 const preview=await wb.render({sheetName:p.sheet,range:'A174:I184',scale:1.5,format:'png'});
 await fs.writeFile(root+'/gespeichert.png',new Uint8Array(await preview.arrayBuffer()));
}
