#!/usr/bin/env python3
"""Archive only the explicitly retired code/data trees, verify bytes, then remove originals."""
from pathlib import Path
import gzip,hashlib,json,os,tarfile,time
ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
DEST=ROOT/'archive/obsolete_20261105'
ALLOWED=['AP_bacteria_code_v4_paper_response','code','数值实验']
KEEP=HERE

def sha_file(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()

def digest_stream(f):
    h=hashlib.sha256()
    for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
    return h.hexdigest()

def main():
    assert (ROOT/'paper_figures/verification.json').is_file(), 'Validate the final plotting pipeline first.'
    assert json.loads((ROOT/'paper_data/diagnostics/package_validation.json').read_text())['passed']
    verified=json.loads((HERE/'pre_archive_checks.json').read_text());assert verified['all_checks_passed']
    DEST.mkdir(parents=True,exist_ok=True)
    if (DEST/'manifest.json').exists():raise SystemExit('Archive already completed; do not archive again.')
    if any(DEST.glob('part-*.tar.gz')):raise SystemExit('Partial archive exists; inspect the per-part manifests before continuing.')
    candidates=[]
    roots=[ROOT/x for x in ALLOWED]
    roots += [p for p in (ROOT/'analysis').iterdir() if p.is_dir() and p!=KEEP]
    roots += sorted(ROOT.glob('AP_bacteria_code_v*.zip'))
    for base in roots:
        seq=[base] if base.is_file() or base.is_symlink() else sorted(base.rglob('*'))
        for p in seq:
            if not(p.is_file() or p.is_symlink()):continue
            assert p.is_relative_to(ROOT) and not p.is_relative_to(ROOT/'.git') and not p.is_relative_to(ROOT/'manuscript')
            rel=str(p.relative_to(ROOT));st=p.lstat();link=os.readlink(p) if p.is_symlink() else None
            candidates.append({'path':rel,'size':st.st_size,'sha256':None if link is not None else sha_file(p),'symlink':link})
    assert len({x['path'] for x in candidates})==len(candidates)
    (DEST/'inventory_before.json').write_text(json.dumps(candidates,ensure_ascii=False,indent=2)+'\n')
    batches=[];batch=[];size=0
    for x in candidates:
        if batch and size+x['size']>64*1024**2:batches.append(batch);batch=[];size=0
        batch.append(x);size+=x['size']
    if batch:batches.append(batch)
    parts=[]
    for i,batch in enumerate(batches,1):
        name=f'part-{i:03d}.tar.gz';target=DEST/name;temp=DEST/(name+'.partial')
        with tarfile.open(temp,'w:gz',compresslevel=6) as t:
            for x in batch:t.add(ROOT/x['path'],arcname=x['path'],recursive=False)
        with tarfile.open(temp,'r:gz') as t:
            members=t.getmembers();assert len(members)==len(batch)
            for x,m in zip(batch,members):
                assert m.name==x['path']
                if x['symlink'] is not None:assert m.issym() and m.linkname==x['symlink']
                else:
                    f=t.extractfile(m);assert f is not None and digest_stream(f)==x['sha256']
        # Before unlinking, reject concurrent changes instead of archiving an older version.
        for x in batch:
            p=ROOT/x['path']
            assert (os.readlink(p)==x['symlink']) if x['symlink'] is not None else sha_file(p)==x['sha256']
        temp.rename(target)
        part={'file':name,'sha256':sha_file(target),'bytes':target.stat().st_size,'files':batch,'verified_before_removal':True}
        (DEST/(name+'.json')).write_text(json.dumps(part,ensure_ascii=False,indent=2)+'\n')
        for x in batch:(ROOT/x['path']).unlink()
        parts.append(part)
        print(f'ARCHIVED {i}/{len(batches)} files={len(batch)} original_MiB={sum(x["size"] for x in batch)/1024**2:.1f} archive_MiB={part["bytes"]/1024**2:.1f}',flush=True)
    for base in roots:
        if base.is_dir():
            for d in sorted((p for p in base.rglob('*') if p.is_dir()),key=lambda p:len(p.parts),reverse=True):
                try:d.rmdir()
                except OSError:pass
            try:base.rmdir()
            except OSError:pass
    manifest={'format':'tar.gz, paths relative to project root','original_files':len(candidates),'original_bytes':sum(x['size'] for x in candidates),'archive_bytes':sum(p['bytes'] for p in parts),'parts':parts,'active_raw_data_moves':'analysis/final_package_20261105/data_moves.json','all_members_verified_before_removal':True,'note':'Old versions are recoverable, not active dependencies. No manuscript, Git history, or unrelated documents were removed.'}
    (DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print('OBSOLETE_ARCHIVE_COMPLETE',manifest['original_files'],manifest['original_bytes'],manifest['archive_bytes'],flush=True)
if __name__=='__main__':main()
