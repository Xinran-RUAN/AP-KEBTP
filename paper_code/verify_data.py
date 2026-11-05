#!/usr/bin/env python3
"""Verify the frozen production kernels and the paper's immutable raw data."""
from pathlib import Path
import hashlib,json
h=Path(__file__).resolve().parent;r=h.parent

def sha(path):
 v=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):v.update(b)
 return v.hexdigest()

def main():
 for name,digest in json.loads((h/'config/source_manifest.json').read_text()).items():
  assert sha(h/name)==digest,'Changed numerical source: '+name
 m=json.loads((r/'paper_data/provenance/immutable_data_sha256.json').read_text())
 for name,digest in m.items():assert sha(r/name)==digest,'Changed raw data: '+name
 print('VERIFIED',len(m),'raw data/assets and all production numerical kernels.')
if __name__=='__main__':main()
