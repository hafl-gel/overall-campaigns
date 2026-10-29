from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from xml.etree import ElementTree as E
import json,hashlib,re,shutil,copy
b=Path('/Users/stefan/git/overall-campaigns/work/litter_import_aug2026')
p=json.loads((b/'payload.json').read_text())
target=Path(p['target'])
assert hashlib.sha256(target.read_bytes()).hexdigest()==p['source_sha256'][str(target)],'Zieldatei wurde inzwischen veraendert.'
backup=b/'litter_data_all_vor_aug2026.xlsx'
if not backup.exists():shutil.copy2(target,backup)
ns={'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
N='{'+ns['s']+'}'
with ZipFile(b/'litter_appended_candidate.xlsx') as z:
 strings=[]
 if 'xl/sharedStrings.xml' in z.namelist():
  strings=[''.join(t.itertext()) for t in E.fromstring(z.read('xl/sharedStrings.xml'))]
 sheet=E.fromstring(z.read('xl/worksheets/sheet1.xml'))
 new=[]
 for row in sheet.find('s:sheetData',ns):
  if int(row.attrib['r'])<=p['oldLastRow']:continue
  assert int(row.attrib['r'])<=p['newLastRow']
  row.attrib.clear();row.attrib['r']=str(p['oldLastRow']+len(new)+1)
  for c in row:
   c.attrib['s']='6'
   if c.attrib.get('t')=='s':
    v=c.find('s:v',ns);text=strings[int(v.text)];c.remove(v);c.set('t','inlineStr')
    t=E.SubElement(E.SubElement(c,N+'is'),N+'t');t.text=text
  new.append(E.tostring(row,encoding='unicode'))
 assert len(new)==31
with ZipFile(target) as z:
 original={name:z.read(name) for name in z.namelist()}
sheet=original['xl/worksheets/sheet1.xml'].decode()
assert '<dimension ref="A1:AD153"' in sheet
sheet=sheet.replace('<dimension ref="A1:AD153"','<dimension ref="A1:AD184"',1)
sheet=sheet.replace('</sheetData>',''.join(new)+'</sheetData>',1)
changed={'xl/worksheets/sheet1.xml':sheet.encode()}
table=original['xl/tables/table1.xml'].decode()
assert table.count('A1:AD153')==2
changed['xl/tables/table1.xml']=table.replace('A1:AD153','A1:AD184').encode()
cache=original['xl/pivotCache/pivotCacheDefinition1.xml'].decode()
cache=re.sub(r'(<pivotCacheDefinition\b[^>]*)(>)',r'\1 refreshOnLoad="1"\2',cache,count=1) if 'refreshOnLoad=' not in cache else re.sub(r'refreshOnLoad="[^"]*"','refreshOnLoad="1"',cache,count=1)
assert 'refreshOnLoad="1"' in cache
changed['xl/pivotCache/pivotCacheDefinition1.xml']=cache.encode()
workbook=original['xl/workbook.xml'].decode()
if 'fullCalcOnLoad=' in workbook:workbook=re.sub(r'fullCalcOnLoad="[^"]*"','fullCalcOnLoad="1"',workbook)
else:workbook=workbook.replace('<calcPr ','<calcPr fullCalcOnLoad="1" ',1)
changed['xl/workbook.xml']=workbook.encode()
stage=b/'litter_data_all_mit_aug2026.xlsx'
with ZipFile(stage,'w',ZIP_DEFLATED) as z:
 for name,data in original.items():z.writestr(name,changed.get(name,data))
with ZipFile(stage) as z:
 assert z.testzip() is None
 for name,data in original.items():
  if name not in changed:assert z.read(name)==data,name
shutil.copy2(stage,target)
print('31 Datenzeilen in Originaldatei uebernommen; bestehende Zeilen und native Pivot-Objekte erhalten; Sicherung erstellt.')
