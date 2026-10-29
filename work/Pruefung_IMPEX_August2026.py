from pathlib import Path
import json,openpyxl,hashlib,csv,math,zipfile
from lxml import etree as E
b=Path("/Users/stefan/git/overall-campaigns");d=b/"work/impex_aug2026";p=json.loads((d/"payload.json").read_text())
a=openpyxl.load_workbook(p["source"],data_only=False);f=openpyxl.load_workbook(p["target"],data_only=False);v=openpyxl.load_workbook(p["target"],data_only=True)
assert hashlib.sha256(Path(p["source"]).read_bytes()).hexdigest()==p["source_sha256"],"Originaldatei veraendert"
assert a.sheetnames==f.sheetnames
for sheet,rg in [("R","A1:AI9"),("Variante_Proben","A4:AP12"),("Variante_Spring","A4:AI12"),("Fumi","A1:I14"),("Geflügelgehalte","A1:L16"),("Detail1","A1:AK7"),("Detail2","A1:AK7")]:
 for row in a[sheet][rg]:
  for c in row:assert c.value==f[sheet][c.coordinate].value,(sheet,c.coordinate)
for i,x in enumerate(p["records"]):
 r=10+i;pr=13+i
 end=sum(x["finisher_deliveries"])+x["opening_stock"]-x["closing_stock"]
 total=x["starter_kg"]+x["grower_kg"]+end
 nfeed=(x["starter_kg"]*203.5+x["grower_kg"]*191.81+end*189.1)/6250
 nex=nfeed-(x["net_kg"]-x["placed"]*.04)*.0287
 expected={"H":x["placed"],"I":x["slaughtered"],"J":x["placed"]-x["slaughtered"],"Q":total,"V":nfeed,"Z":nex,"AA":1000*nex/x["slaughtered"]}
 for col,expected_v in expected.items():assert math.isclose(v["R"][f"{col}{r}"].value,expected_v,abs_tol=1e-9),col
 assert total==x["total_feed_kg"]
 assert v["R"][f"B{r}"].value==0
 assert f["R"][f"AA{r}"].data_type=="f"
 for c in["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S"]:assert v["Tabelle MT"][f"{c}{r}"].value is not None
for sh in v:
 assert not[(c.coordinate,c.value)for row in sh for c in row if c.data_type=="e"],sh.title
def read(name):
 return list(csv.DictReader((b/"ergebnisse_n_ausscheidung"/name).open(encoding="utf-8-sig"),delimiter=";"))
summ=read("mittelwerte_nach_stall.csv");weights=read("n_ausscheidung_mit_gewichten.csv")
for i,row in enumerate(summ):
 assert row["n_available"]=="5"and row["n_provisional"]=="1"and row["complete"]=="TRUE"
 weighted=sum(float(x["N_Ausscheidung_pro_Tier_und_Jahr_g"].replace(",","."))*float(x["gewicht"].replace(",","."))for x in weights if x["Stall"]==str(i+1))
 assert math.isclose(weighted,float(row["mean_weighted"].replace(",",".")),abs_tol=1e-9)
 assert math.isclose(weighted,v["Tabelle MT"][f"P{13+i}"].value,abs_tol=1e-9)
 for x in weights:
  if x["Stall"]==str(i+1)and x["Umtrieb"]in["Jul-24","Aug-26"]:assert float(x["gewicht"].replace(",","."))==.125
assert len(read("gepaarte_wrg_kampagnen.csv"))==3
N={"s":"http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
with zipfile.ZipFile(p["target"])as z:
 caches=[E.fromstring(z.read(n))for n in z.namelist()if n.startswith("xl/pivotCache/pivotCacheDefinition")and n.endswith(".xml")]
 assert any(c.get("recordCount")=="10"for c in caches)
print("BESTANDEN: PDF-Futtermengen, N-Rechnung, 10 Stallkampagnen, Sommergewichtung, Excel/R-Abgleich, Original und historische Eingaben/Formeln erhalten; native Pivots aktualisiert; keine Excel-Fehler.")
