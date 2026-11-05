#!/usr/bin/env python3
"""Copy verified FIG/EPS output to the current manuscript. Does not edit TeX."""
from pathlib import Path
import json,shutil,subprocess
r=Path(__file__).resolve().parent.parent;figs=r/'paper_figures';paper=r/'manuscript/20261103'
records=json.loads((figs/'verification.json').read_text())
assert len(records)==10 and all(x['native_visible_editable_fig'] and x['exact_saved_curve_data'] and x['style_preserved'] for x in records)
for record in records:
 n=record['name']
 for ext in ['fig','eps']:shutil.copy2(figs/(n+'.'+ext),paper/(n+'.'+ext))
 subprocess.run(['epstopdf',str(paper/(n+'.eps')),'--outfile='+str(paper/(n+'-eps-converted-to.pdf'))],check=True)
print('Verified figure pairs copied. Review changed results before editing any prose; compile TeX separately.')
