#!/usr/bin/env python3
"""Run/resume only the 14 configurations used by the current paper."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, sys, time
HERE=Path(__file__).resolve().parent

def matlab_bin():
    p=os.environ.get('MATLAB_BIN') or shutil.which('matlab') or '/Applications/MATLAB_R2023a.app/bin/matlab'
    if not Path(p).is_file(): raise SystemExit('Set MATLAB_BIN to your MATLAB executable.')
    return p

def quote_matlab(p): return str(p).replace("'", "''")

def verify_source():
    for name,digest in json.loads((HERE/'config/source_manifest.json').read_text()).items():
        if hashlib.sha256((HERE/name).read_bytes()).hexdigest()!=digest:
            raise SystemExit('Numerical source changed; review and record a new version before running: '+name)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=HERE.parent/'paper_data',help='Use a NEW directory for a fresh rerun; existing cases are checked and reused.')
    parser.add_argument('--case',action='append',dest='ids',help='Run only a named case; repeat to select several.')
    parser.add_argument('--workers',type=int,default=1)
    a=parser.parse_args();verify_source();root=a.output.resolve()
    if a.workers<1:parser.error('--workers must be positive')
    if root==(HERE.parent/'paper_data').resolve():
        subprocess.run([sys.executable,str(HERE/'verify_data.py')],check=True)
    cases=json.loads((HERE/'config/cases.json').read_text());ids=[c['id'] for c in cases]
    if a.ids:
        if set(a.ids)-set(ids):parser.error('Unknown case ID')
        ids=[i for i in ids if i in a.ids]
    (root/'logs').mkdir(parents=True,exist_ok=True)
    test=f"addpath('{quote_matlab(HERE)}');startup_paper;test_paper_solver"
    subprocess.run([matlab_bin(),'-nojvm','-nosplash','-singleCompThread','-batch',test],check=True,cwd=HERE.parent)
    active={};failed=[]
    while ids or active:
        while ids and len(active)<a.workers:
            cid=ids.pop(0);log=(root/'logs'/(cid+'.log')).open('a')
            code=f"addpath('{quote_matlab(HERE)}');startup_paper;assert(run_paper_case('{cid}','{quote_matlab(root)}'));"
            proc=subprocess.Popen([matlab_bin(),'-nojvm','-nosplash','-singleCompThread','-batch',code],cwd=HERE.parent,stdout=log,stderr=subprocess.STDOUT)
            active[cid]=(proc,log);print('Started',cid,flush=True)
        for cid,(proc,log) in list(active.items()):
            rc=proc.poll()
            if rc is not None:
                log.close();del active[cid]
                if rc:failed.append(cid)
                print('Finished',cid,'exit',rc,flush=True)
        if ids or active:time.sleep(2)
    if failed:raise SystemExit('Failed cases (other cases continued): '+', '.join(failed))
    print('All requested cases complete. Run analyze_paper_data and plot_paper_figures for postprocessing.')
if __name__=='__main__':main()
