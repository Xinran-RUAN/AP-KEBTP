# 最新论文代码（manuscript/20261103）

这是本项目唯一的现行求解与绘图入口。数值内核来自已验证的反射边界、完整零通量和保正提前返回版本，整理时没有修改内核公式。

## 目录

- `+model/`、`+src/`、`+utils/`：论文实际需要的数值内核。
- `config/cases.json`：Figure 3–7 的全部 14 组算例；`baseline.mat` 保存实际基准参数及空间、速度网格。
- `templates/`：最新版论文的原生 MATLAB FIG 模板。保留布局、曲线样式、字体和范围；Figure 7 纵轴为 `[0,0.12]`。
- `tests/test_paper_solver.m`：保正提前返回、含零输入、负值修正、两步演化以及短跑检查。
- `../paper_data/`：当前论文使用的数据；`../paper_figures/`：由本入口生成的 EPS、可见可编辑 FIG 和预览图。

MATLAB R2023a 已验证。所有路径相对于本代码目录定位，不依赖旧 `analysis`、旧 `code` 或归档目录。无需 Python 第三方包。

## 读取已有数据重新作图（不求解 PDE）

从项目根目录执行：

```bash
./paper_code/reproduce.sh
```

或在 MATLAB 中：

```matlab
addpath('paper_code'); startup_paper;
analyze_paper_data;
plot_paper_figures;
```

输出到 `paper_figures/`，每个图形均有同名 `.fig`、`.eps`、`.png`。双联图为一个 FIG。脚本自动重新打开 FIG，核对可见性、数据和样式。Figure 1 的数值解与 Figure 3 共享新计算的 `sign_macro`；解析曲线仍按原峰位置和离散质量匹配规则生成。Figure 4 采用全部七个 epsilon 与全域误差；Figure 5 保留原滑动时间窗拟合算法，不增加平滑。

只有确认新结果及正文解释一致后，才复制到论文：

```bash
LC_ALL=C python3 paper_code/publish_figures.py
(cd manuscript/20261103 && LC_ALL=C latexmk -pdf -interaction=nonstopmode -halt-on-error main_Gissell.tex)
```

发布脚本仅复制经验证的图片和转换 PDF，不重写 TeX 正文。整理工作本身没有修改论文及正式图片。

## 正式重算或断点恢复

已有数据默认校验后复用。需要重新求解时，明确指定新的输出目录，避免覆盖现有原始结果：

```bash
python3 paper_code/run_experiments.py --output paper_data/recomputed --workers 1
```

单组算例示例：

```bash
python3 paper_code/run_experiments.py --output paper_data/recomputed --case exp_a0p001_kinetic_e0p01
```

每组记录原始状态、rho/S/N 快照、微观量、质心、质量、保正触发、诊断和检查点；失败状态单独保存。默认一次运行一组。可通过 `MATLAB_BIN` 指定 MATLAB 可执行文件。数值内核哈希在求解前验证，改动内核时必须先审核和更新版本记录，不能把旧缓存当作新版本结果。

新目录全部算完后的后处理：

```matlab
analyze_paper_data(fullfile(pwd,'paper_data','recomputed'));
plot_paper_figures(fullfile(pwd,'paper_data','recomputed'),fullfile(pwd,'paper_figures_recomputed'));
```

当前基准为 `(0,150)`、dx=0.025、dt=0.001、dv=0.02、T=50。kinetic 响应时间系数等于 epsilon，macro 为零；指数参数 a 与化学降解率 alpha 分开。

## Figure 2 的来源限制

Figure 2 仍使用论文保留的旧扫描，绘图只读取 `paper_data/figure2/legacy_speed_scan.mat`。两个数值面板的敏感度间隔为0.1（441组），解析面板为0.02。旧宏观数据为 dx=0.1、dt=0.01、区域(0,300)、T=100；可追溯旧动理学数据为 dx=0.1、dv=0.02、dt=0.01、区域(0,150)、T=60、epsilon=0.01。动理学 dt 来自文件名和入口，未独立保存于 MAT。现存单算例文件中有一处速度与旧表不一致，详见数据目录核查报告。不得把这些旧扫描标为由本次新内核重算。

## 历史版本

过时代码、旧数据、探索实验和历史分析脚本已从现行目录移入 `archive/obsolete_20261105/`。每个归档分卷均逐文件校验后才清出原路径。完整清单、原路径和 SHA-256 均保留。

恢复到一个新的空目录：

```bash
python3 paper_code/restore_archive.py --to /path/to/an/empty/directory
```

可仅恢复某个历史目录，避免展开全部旧数据：

```bash
python3 paper_code/restore_archive.py --to /path/to/an/empty/directory --prefix code/code-0407/kinetic/
python3 paper_code/restore_archive.py --verify
```

恢复内容仅供历史核查，不要用 `genpath` 将归档/恢复目录加入 MATLAB 路径。旧目录引用与当前原始数据的移动关系记录于 `analysis/final_package_20261105/data_moves.json`。
