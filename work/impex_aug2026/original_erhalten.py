from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from lxml import etree as E
from openpyxl.utils.cell import range_boundaries,get_column_letter
import json,copy,hashlib,re
b=Path("/Users/stefan/git/overall-campaigns/work/impex_aug2026");p=json.loads((b/"payload.json").read_text());edits=json.loads((b/"edits.json").read_text())
assert hashlib.sha256(Path(p["source"]).read_bytes()).hexdigest()==p["source_sha256"]
with ZipFile(p["source"]) as z:orig={n:z.read(n)for n in z.namelist()}
with ZipFile(b/"candidate.xlsx")as z:cand={n:z.read(n)for n in z.namelist()}
N="http://schemas.openxmlformats.org/spreadsheetml/2006/main"; ns={"s":N}
tag=lambda n:"{"+N+"}"+n
def strings(z):
 return ["".join(t.itertext())for t in E.fromstring(z["xl/sharedStrings.xml"])]if"xl/sharedStrings.xml"in z else []
ss=strings(cand);changed={}
styles=E.fromstring(orig["xl/styles.xml"]);xfs=styles.find("s:cellXfs",ns)
def wrapped(index):
 st=copy.deepcopy(xfs[index]);a=st.find("s:alignment",ns)
 if a is None:a=E.SubElement(st,tag("alignment"))
 a.set("wrapText","1");a.set("vertical","center");xfs.append(st);xfs.set("count",str(len(xfs)));return str(len(xfs)-1)
sheetids={"Variante_Proben":3,"R":4,"Tabelle MT":5,"Variante_Spring":6}
for name,sid in sheetids.items():
 path=f"xl/worksheets/sheet{sid}.xml";a=E.fromstring(orig[path]);c=E.fromstring(cand[path]);sd=a.find("s:sheetData",ns)
 oldcells={v.get("r"):v for v in sd.iter(tag("c"))};newcells={v.get("r"):v for v in c.iter(tag("c"))};rows={int(r.get("r")):r for r in sd}
 refs=set()
 for rg in edits[name]:
  c1,r1,c2,r2=range_boundaries(rg)
  refs.update(f"{get_column_letter(col)}{row}"for col in range(c1,c2+1)for row in range(r1,r2+1))
 for ref in sorted(refs,key=lambda k:(range_boundaries(k)[1],range_boundaries(k)[0])):
  cell=copy.deepcopy(newcells[ref]);col=re.sub(r"\d","",ref);row=int(re.sub(r"\D","",ref))
  origcell=oldcells.get(ref)
  template=origcell
  if template is None:
   tr=(11+(row-13))if name in["Variante_Proben","Variante_Spring"]and row in[13,14]else(8+(row-10))if row in[10,11]else 1
   template=oldcells.get(col+str(tr),oldcells.get("A21",oldcells.get("A1")))
  style=template.get("s","0")if template is not None else"0"
  if name in["Variante_Proben","Variante_Spring"]and row in[13,14]and col in["E","F"]:style=oldcells["E11"].get("s","0")
  if name=="R"and row in[10,11]and col in["E","F"]:style=oldcells["E8"].get("s","0")
  if col in["AJ","AK"]and name=="R":
   style=oldcells["AI1"if row==1 else"AI9"].get("s","0")
   if row>1:style=wrapped(int(style))
  if col=="AR":
   style=oldcells["A4"if row==4 else"A21"].get("s","0");style=wrapped(int(style))
  if name=="Variante_Spring"and col=="AK":style=wrapped(int(oldcells["A21"].get("s","0")))
  cell.set("s",style)
  if cell.get("t")=="s":
   v=cell.find("s:v",ns);s=ss[int(v.text)];cell.remove(v);cell.set("t","inlineStr");E.SubElement(E.SubElement(cell,tag("is")),tag("t")).text=s
  if row not in rows:
   r=E.Element(tag("row"),r=str(row));rows[row]=r;sd.append(r)
  r=rows[row]
  if origcell is not None:r.remove(origcell)
  r.append(cell)
  if col=="AR"or(name=="R"and col in["AJ","AK"]):r.set("ht","32");r.set("customHeight","1")
 for r in sd:r[:]=sorted(r,key=lambda v:range_boundaries(v.get("r"))[0])
 sd[:]=sorted(sd,key=lambda v:int(v.get("r")))
 dims={"Variante_Proben":"A4:AR47","R":"A1:AK11","Tabelle MT":"A1:AD20","Variante_Spring":"A4:AK29"}
 a.find("s:dimension",ns).set("ref",dims[name])
 if name in["Variante_Proben","Variante_Spring","R"]:
  cols=a.find("s:cols",ns)
  if cols is None:cols=E.Element(tag("cols"));a.insert(list(a).index(sd),cols)
  nc=44 if name=="Variante_Proben"else 37
  for cc in list(cols):
   if int(cc.get("min"))<=nc<=int(cc.get("max")):
    if int(cc.get("min"))<nc:cc.set("max",str(nc-1))
    else:cols.remove(cc)
  E.SubElement(cols,tag("col"),min=str(nc),max=str(nc if name!="R"else 38),width=str(95 if name!="R"else 64),customWidth="1")
 changed[path]=E.tostring(a,xml_declaration=True,encoding="UTF-8",standalone=True)
for name,data in orig.items():
 if name.startswith("xl/tables/table")and name.endswith(".xml"):
  a=E.fromstring(data);tn=a.get("displayName")
  if tn in["Table1","Table14"]:
   old=a.get("ref");new=old.replace("12","14");a.set("ref",new);af=a.find("s:autoFilter",ns)
   if af is not None:af.set("ref",new)
   changed[name]=E.tostring(a,xml_declaration=True,encoding="UTF-8",standalone=True)
 if name.startswith("xl/pivotCache/pivotCacheDefinition")and name.endswith(".xml"):
  a=E.fromstring(data);a.set("refreshOnLoad","1");changed[name]=E.tostring(a,xml_declaration=True,encoding="UTF-8",standalone=True)
changed["xl/styles.xml"]=E.tostring(styles,xml_declaration=True,encoding="UTF-8",standalone=True)
a=E.fromstring(orig["xl/workbook.xml"]);calc=a.find("s:calcPr",ns)
if calc is None:calc=E.SubElement(a,tag("calcPr"))
calc.set("fullCalcOnLoad","1");calc.set("forceFullCalc","1")
changed["xl/workbook.xml"]=E.tostring(a,xml_declaration=True,encoding="UTF-8",standalone=True)
target=Path(p["target"]);assert not target.exists(),"Vorhandenes Ziel bitte zuerst auf Veraenderungen pruefen."
with ZipFile(target,"w",ZIP_DEFLATED)as z:
 for name,data in orig.items():z.writestr(name,changed.get(name,data))
with ZipFile(target)as z:
 assert z.testzip()is None
 for name,data in orig.items():
  if name not in changed:assert z.read(name)==data,name
print("Excel-Arbeitsdatei im Git-Projekt erstellt; Original sowie native Tabellen, Pivot-Objekte und historische Eingabezellen erhalten.")
