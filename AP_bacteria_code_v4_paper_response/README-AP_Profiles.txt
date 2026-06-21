AP plotting and rebuild scripts

Recommended workflow in MATLAB:

1. Put rebuild_AP_profiles_from_flat_snapshots.m in the runs folder.
2. Put plot_AP_profiles_paper.m in the post folder.
3. Run:

   rebuild_AP_profiles_from_flat_snapshots
   plot_AP_profiles_paper

The plotting script reads:
   data/AP_profiles/AP_profiles_merged.mat

In plot_AP_profiles_paper.m, edit these lines to select which epsilon values are plotted:

   eps_profile_wanted = [1e-1, 5e-2, 1e-2, 1e-3];
   eps_error_wanted = [];

Use [] to plot all available epsilon values.

### 重新运行 `run_AP_profiles.m` 前的注意事项

目前 AP profiles 的数据暂时没有按照 `dx`、`dt`、`epsilon` 等参数分别存储。重新运行 `run_AP_profiles.m` 时，`snapshots` 文件夹以外的部分结果通常只会保留最近一次运行的数据，因此如果之前的数据仍然需要使用，请务必先手动备份 `data/AP_profiles` 文件夹。

特别需要注意的是，当前 snapshot 文件名主要记录 `epsilon`，没有记录 `dx`、`dt` 等参数；因此如果修改 `dx` 后直接重新运行，`snapshots` 中的数据也可能被覆盖，或者与不同网格参数下的数据混在一起。

在程序存储结构尚未改成按参数自动区分之前，建议每次修改参数前先手动复制并重命名已有数据文件夹，例如备份为 `data/AP_profiles_backup_dx0p1_dt0p1`，然后再运行新的测试。新数据生成后，再运行 `rebuild_AP_profiles_from_flat_snapshots` 和 `plot_AP_profiles_paper` 重新合并并绘图。