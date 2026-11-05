#!/usr/bin/env python3
"""Verify or selectively restore retired sources/data without overwriting work."""
from pathlib import Path,PurePosixPath
import argparse,hashlib,json,tarfile
r=Path(__file__).resolve().parent.parent
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--to',type=Path,help='New empty destination directory')
p.add_argument('--prefix',action='append',default=[],help='Restore only original paths starting with this prefix; repeat as needed')
p.add_argument('--verify',action='store_true',help='Verify archive contents without extracting files')
a=p.parse_args();dest=None
if not a.verify:
 if a.to is None:p.error('--to is required unless --verify is used')
 dest=a.to.resolve()
 if dest.exists() and any(dest.iterdir()):raise SystemExit('Choose an empty destination; existing work is never overwritten.')
 dest.mkdir(parents=True,exist_ok=True)
arc=r/'archive/obsolete_20261105';manifest=json.loads((arc/'manifest.json').read_text());count=0
for part in manifest['parts']:
 wanted={x['path']:x for x in part['files'] if not a.prefix or any(x['path'].startswith(prefix) for prefix in a.prefix)}
 if not wanted:continue
 path=arc/part['file'];h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 assert h.hexdigest()==part['sha256'],path
 with tarfile.open(path,'r:gz') as t:
  for member in t:
   if member.name not in wanted:continue
   rel=PurePosixPath(member.name);assert not rel.is_absolute() and '..' not in rel.parts
   source=wanted[member.name]
   if member.issym() or member.islnk():
    assert member.issym() and member.linkname==source['symlink']
    if not a.verify:raise SystemExit('Review archived symbolic links manually before restoring.')
   else:
    stream=t.extractfile(member);assert stream is not None;h=hashlib.sha256()
    for b in iter(lambda:stream.read(1024*1024),b''):h.update(b)
    assert h.hexdigest()==source['sha256'],member.name
    if dest is not None:t.extract(member,dest,filter='data')
   count+=1
 print(('Verified' if a.verify else 'Restored'),part['file'])
print('Files:',count)
print('Historical final raw files were moved, not duplicated; current paths are in analysis/final_package_20261105/data_moves.json.')
