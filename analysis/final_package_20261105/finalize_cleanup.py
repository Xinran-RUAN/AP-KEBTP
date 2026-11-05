from pathlib import Path
import json,hashlib
r=Path(__file__).resolve().parents[2];h=Path(__file__).resolve().parent

def sha(p):
 d=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):d.update(b)
 return d.hexdigest()

before=json.loads((h/'manuscript_before_sha256.json').read_text());protected={p:d for p,d in before.items() if Path(p).name!='.DS_Store'}
changed=[p for p,d in protected.items() if not(r/p).is_file() or sha(r/p)!=d];assert not changed,changed
metadata_changed=[p for p,d in before.items() if Path(p).name=='.DS_Store' and (not(r/p).exists() or sha(r/p)!=d)]
m=json.loads((r/'archive/obsolete_20261105/manifest.json').read_text());assert m['all_members_verified_before_removal'] and len(m['parts'])==53
assert all((r/'archive/obsolete_20261105'/v['file']).stat().st_size==v['bytes'] for v in m['parts'])
assert all(not(r/n).exists() for n in ['AP_bacteria_code_v4_paper_response','code','数值实验'])
assert list((r/'analysis').iterdir())==[h]
assert 'ALL_TEN_PAPER_FIGURE_FILES_REGENERATED_AND_REOPENED' in (h/'end_to_end_reproduction.log').read_text()
assert json.loads((r/'paper_data/diagnostics/package_validation.json').read_text())['passed']
assert (r/'paper_data/derived/wave_speed_full_precision.csv').read_bytes()==(r/'paper_data/provenance/wave_speed_full_precision.csv').read_bytes()
codefiles={str(p.relative_to(r)):sha(p) for p in (r/'paper_code').rglob('*') if p.is_file() and '__pycache__' not in p.parts}
(h/'final_code_sha256.json').write_text(json.dumps(codefiles,ensure_ascii=False,indent=2)+'\n')
result={'complete':True,'numerical_kernels':25,'raw_cases':14,'immutable_data_verified':True,'manuscript_preserved_files':len(protected),'Finder_metadata_changed_without_overwrite':metadata_changed,'end_to_end_reproduction_after_archive':True,'native_FIG_files':10,'selective_restore_passed':True,'archived_files':m['original_files'],'archive_parts':len(m['parts']),'original_obsolete_bytes':m['original_bytes'],'compressed_archive_bytes':m['archive_bytes'],'bytes_saved':m['original_bytes']-m['archive_bytes'],'all_archive_members_verified_before_removal':True,'no_long_experiments_rerun':True,'no_commit_or_push':True}
(h/'final_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
(r/'archive/README.md').write_text('''# 可恢复历史归档

`obsolete_20261105/` 包含已从现行工作目录清出的旧代码、旧数据、旧分析脚本和先前探索结果。

8974 个文件分为 53 个 tar.gz 分卷，原始大小约 3.39 GiB，压缩后约 2.85 GiB。每个文件的归档内容均在清出原路径之前进行 SHA-256 比对，源文件并发变化会阻止清除。`manifest.json` 和每卷同名 JSON 保存完整原路径、大小与哈希。

这些文件不属于当前计算/绘图依赖，不要加入 MATLAB 路径。恢复时使用 `paper_code/restore_archive.py`，只能写入新的空目录，不覆盖现行代码或数据；可用 `--prefix` 选择单个文件或旧目录。已经实际验证单个源码文件能按原路径恢复且字节一致。

最新14组正式原始结果已移动至 `paper_data/cases/`，未被重复压入归档；原路径对应关系见 `analysis/final_package_20261105/data_moves.json`。

旧日期论文、研究笔记、项目外文件以及 Git 历史均未清除。本次没有不可恢复删除历史代码和数据，也未提交或推送。
''')
(h/'整理报告.txt').write_text(f'''最终论文代码及数据整理（2026-11-05）

已完成。现行求解与绘图入口：paper_code/；论文数据：paper_data/；EPS、原生FIG及预览：paper_figures/。

一、保留和集中
25个实际需要的model/src/utils数值内核函数，与整理前已验证的最新生产版本逐字节一致。
14组正式求解/断点恢复入口、已有数据后处理、独立绘图、原生FIG验证、短测试、数据哈希核验与选择性恢复工具。
Figure 3–7的14个最终原始MAT全部移动保留，SHA-256与正式交付记录完全相同。没有插值替换或修改原始结果。
Figure 1原始t=30、50宏观快照及与新sign_macro共享数据的绘图逻辑；Figure 2三块旧速度矩阵及441组参数核查记录。
完整精度波速表、全域L2误差、正式日志、来源版本和必要诊断。当前图形模板包括Figure 7纵轴[0,0.12]。

二、旧资料处置
旧AP代码包、code/、数值实验/和先前analysis各轮源码、旧结果、缓存移至archive/obsolete_20261105/，不再位于现行运行目录。
共{m['original_files']}个文件、{len(m['parts'])}卷。逐文件校验归档后才清出原路径，保留恢复能力。全部人工源码修改也保存于归档和worktree_before.patch。
原始旧资料{m['original_bytes']/1024**3:.3f} GiB，压缩后{m['archive_bytes']/1024**3:.3f} GiB，实际减少{(m['original_bytes']-m['archive_bytes'])/1024**3:.3f} GiB。
原始数据移动关系见data_moves.json。不可变MAT的provenance中可能保留历史绝对路径，属于来源记录，不是现行代码依赖。
旧日期论文、笔记和.git未清除，未提交或推送。Finder显示元数据.DS_Store有变化，未回滚或覆盖；所有论文源稿、图片、PDF等{len(protected)}个非Finder元数据文件哈希不变。

三、验证
MATLAB R2023a：严格正状态、含零状态提前返回；负分布和负密度修正；NaN/Inf拒绝；两步有/无后处理一致性；各epsilon短跑均通过。
14个现有正式缓存由新入口校验接受，未启动长时间实验。
旧目录归档后，实际执行 ./paper_code/reproduce.sh 成功。只依赖新代码与保留的数据，重新生成全部Figure 1–7（10个图形文件），每个FIG重开核对Visible=on、可编辑对象、数据和样式。
全部曲线与当前论文模板差异小于1e-13，完整精度波速表和结果汇总完全一致。Figure 7预览已目视检查。
本次未改论文正文、正式图片和PDF，因此未重新编译稿件。
选择性恢复测试通过：positivity_limiter.m按原路径恢复后与现行文件逐字节一致，临时恢复副本已清理。
Python及shell入口语法检查通过。

四、使用
已有数据重新作图：./paper_code/reproduce.sh。
新目录正式重算：python3 paper_code/run_experiments.py --output paper_data/recomputed --workers 1。
新目录隔离输出，不覆盖现有原始结果。
使用说明：paper_code/README.md；数据说明：paper_data/README.md；跨图配置：paper_code/config/figure_data_map.json。

五、保留的来源限制
Figure 2仍是此前获准保留的旧扫描，不能称为用当前修正求解器重算。可追溯的441组动理学参数均显示dv=0.02，440/441个速度与现存单组文件逐位一致；chiS=0.5、chiN=1.1处有旧表与现存文件差异。详情见paper_data/figure2/检查报告.txt。
两份指数原始MAT是完整T=50检查点恢复结构，保持原样，由read_completed_case.m在内存中统一读取。

附件：final_verification.json、final_code_sha256.json、pre_archive_checks.json、curve_equivalence.json、restore_test_result.json、MATLAB日志、archive.log。
''')
print(json.dumps(result,ensure_ascii=False))
