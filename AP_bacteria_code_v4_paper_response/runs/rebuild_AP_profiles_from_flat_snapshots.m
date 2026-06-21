function rebuild_AP_profiles_from_flat_snapshots()
%REBUILD_AP_PROFILES_FROM_FLAT_SNAPSHOTS
% 从 data/AP_profiles/snapshots 中的平铺 snapshot 文件重建合并数据。
%
% 适用情形：
%   AP_profiles.mat 被覆盖，但 snapshots 中仍然保留不同 epsilon 的
%   kinetic snapshot 文件。
%
% 文件名示例：
%   kinetic_eps_0p1_t_001p000.mat
%   kinetic_eps_0p01_t_050p000.mat
%   kinetic_eps_0p001_t_050p000.mat
%
% 输出：
%   data/AP_profiles/AP_profiles_merged.mat
%   data/AP_profiles/AP_error_summary_merged.csv
%   data/AP_profiles/AP_error_by_time_merged.csv
%   data/AP_profiles/AP_relative_error_by_time_merged.csv
%
% 使用方式：
%   在 MATLAB 中运行
%       rebuild_AP_profiles_from_flat_snapshots
%   然后再运行
%       plot_AP_profiles_paper

clear; clc;

root_dir = local_find_project_root();
data_dir = fullfile(root_dir, 'data', 'AP_profiles');
snap_dir = fullfile(data_dir, 'snapshots');

base_file = fullfile(data_dir, 'AP_profiles.mat');
out_file  = fullfile(data_dir, 'AP_profiles_merged.mat');

if ~exist(base_file, 'file')
    error('Cannot find base file:\n%s', base_file);
end

if ~exist(snap_dir, 'dir')
    error('Cannot find snapshot directory:\n%s', snap_dir);
end

fprintf('Project root:\n%s\n\n', root_dir);
fprintf('Snapshot directory:\n%s\n\n', snap_dir);

% ------------------------------------------------------------
% 读取当前 AP_profiles.mat 中的 macro 数据。
% macro 与 epsilon 无关，通常覆盖后仍可用。
% ------------------------------------------------------------
Sbase = load(base_file);

if ~isfield(Sbase, 'macro')
    error('The current AP_profiles.mat must contain macro.');
end

macro = Sbase.macro;

if isfield(Sbase, 'p')
    p = Sbase.p;
else
    p = struct();
end

if isfield(Sbase, 'snap_times') && ~isempty(Sbase.snap_times)
    snap_times = Sbase.snap_times(:).';
else
    snap_times = local_get_snap_times(macro.snap, []);
end

if isfield(Sbase, 'macro_speed')
    macro_speed = Sbase.macro_speed;
elseif isfield(macro, 'speed')
    macro_speed = macro.speed;
else
    macro_speed = NaN;
end

% ------------------------------------------------------------
% 扫描 snapshots 文件夹下所有 .mat 文件。
% 不使用 kinetic_eps_*_t_*.mat 通配符，以避免某些文件名匹配失败。
% ------------------------------------------------------------
all_files = dir(fullfile(snap_dir, '*.mat'));

if isempty(all_files)
    error('No .mat files found in snapshot directory:\n%s', snap_dir);
end

eps_vals = nan(numel(all_files), 1);
t_vals   = nan(numel(all_files), 1);
is_kinetic_snapshot = false(numel(all_files), 1);

for k = 1:numel(all_files)
    fname = all_files(k).name;
    [eps_val, t_val, ok] = local_parse_eps_time_from_filename(fname);

    if ok
        eps_vals(k) = eps_val;
        t_vals(k)   = t_val;
        is_kinetic_snapshot(k) = true;
    end
end

files = all_files(is_kinetic_snapshot);
eps_vals = eps_vals(is_kinetic_snapshot);
t_vals = t_vals(is_kinetic_snapshot);

if isempty(files)
    fprintf('\nFirst 20 files in snapshot directory are:\n');
    for k = 1:min(20, numel(all_files))
        fprintf('  %s\n', all_files(k).name);
    end
    error('No valid kinetic snapshot files were recognized.');
end

not_recognized = all_files(~is_kinetic_snapshot);
bad_names = {};
for k = 1:numel(not_recognized)
    if contains(not_recognized(k).name, 'kinetic')
        bad_names{end+1} = not_recognized(k).name; %#ok<AGROW>
    end
end

if ~isempty(bad_names)
    fprintf('\nSome files contain "kinetic" but were not parsed:\n');
    for k = 1:min(20, numel(bad_names))
        fprintf('  %s\n', bad_names{k});
    end
end

% ------------------------------------------------------------
% 获取 epsilon 列表。
% ------------------------------------------------------------
eps_list = unique(eps_vals(:));
eps_list = sort(eps_list, 'descend').';

fprintf('\nDetected eps_list:\n');
disp(eps_list);

expected_eps = [1e-1, 5e-2, 2e-2, 1e-2, 5e-3, 2e-3, 1e-3];
% expected_eps = [1e-1, 5e-2, 1e-2];
missing_eps = [];
for j = 1:numel(expected_eps)
    if ~any(abs(eps_list - expected_eps(j)) <= max(1e-14, 1e-10*expected_eps(j)))
        missing_eps(end+1) = expected_eps(j); %#ok<AGROW>
    end
end

if ~isempty(missing_eps)
    fprintf('\nWarning: the following expected eps values were not detected:\n');
    disp(missing_eps);
    fprintf('Try checking with absolute path in MATLAB:\n');
    fprintf('dir(fullfile(''%s'', ''*0p001*.mat''))\n\n', snap_dir);
end

% ------------------------------------------------------------
% 逐个 epsilon 重建 kins{m}。
% ------------------------------------------------------------
kins = cell(size(eps_list));

x  = local_get_grid_x(macro);
dx = local_get_grid_dx(macro, x);

for m = 1:numel(eps_list)

    eps_val = eps_list(m);
    idx_eps = find(abs(eps_vals - eps_val) <= max(1e-14, 1e-10 * max(eps_val, 1)));

    if isempty(idx_eps)
        error('No snapshots found for eps = %g.', eps_val);
    end

    [~, order] = sort(t_vals(idx_eps));
    idx_eps = idx_eps(order);

    % 注意：每个 snap item 必须有完全相同的字段。
    snap = struct('t', {}, 'rho', {}, 'S', {}, 'N', {});

    for j = 1:numel(idx_eps)
        id = idx_eps(j);
        fname = fullfile(snap_dir, files(id).name);

        A = load(fname);
        [tval, rho, Sval, Nval] = local_extract_snapshot(A, files(id).name);

        item = struct();
        item.t   = tval;
        item.rho = rho(:);
        item.S   = [];
        item.N   = [];

        if ~isempty(Sval)
            item.S = Sval(:);
        end

        if ~isempty(Nval)
            item.N = Nval(:);
        end

        snap(end+1) = item; %#ok<AGROW>
    end

    tt = [snap.t];
    [~, order2] = sort(tt);
    snap = snap(order2);

    kin = struct();
    kin.eps = eps_val;
    kin.snap = snap;

    kin.U = struct();
    kin.U.rho = snap(end).rho(:);

    if isfield(snap(end), 'S') && ~isempty(snap(end).S)
        kin.U.S = snap(end).S(:);
    end

    if isfield(snap(end), 'N') && ~isempty(snap(end).N)
        kin.U.N = snap(end).N(:);
    end

    if isfield(macro, 'grid')
        kin.grid = macro.grid;
    end

    % 估计摘要波速。
    try
        t_kin = local_get_snap_times(snap, []);
        xmass = local_compute_center_of_mass_history(x, dx, snap);
        vhist = local_finite_diff_speed(t_kin(:), xmass(:));
        tailN = min(6, numel(vhist));
        kin.speed = mean(vhist(end-tailN+1:end), 'omitnan');
    catch
        kin.speed = NaN;
    end

    kins{m} = kin;

    fprintf('eps = %-10g  snapshots = %d, t from %g to %g\n', ...
        eps_val, numel(snap), snap(1).t, snap(end).t);
end

% ------------------------------------------------------------
% 重新计算误差、相对误差和速度摘要。
% ------------------------------------------------------------
[err_final, relerr_final, err_snap, relerr_snap, speeds] = ...
    local_recompute_diagnostics(macro, kins, eps_list, snap_times);

% ------------------------------------------------------------
% 生成表格。
% ------------------------------------------------------------
Tfinal = table(eps_list(:), err_final(:), relerr_final(:), speeds(:), ...
    repmat(macro_speed, numel(eps_list), 1), abs(speeds(:) - macro_speed), ...
    'VariableNames', {'eps', 'L2_error_final', 'relative_L2_error_final', ...
    'speed_kinetic', 'speed_macro', 'speed_difference'});

Ttime = array2table([eps_list(:), err_snap], ...
    'VariableNames', [{'eps'}, local_time_varnames(snap_times)]);

TtimeRel = array2table([eps_list(:), relerr_snap], ...
    'VariableNames', [{'eps'}, local_time_varnames(snap_times)]);

summary = struct();
summary.p = p;
summary.eps_list = eps_list;
summary.snap_times = snap_times;
summary.err_final = err_final;
summary.relerr_final = relerr_final;
summary.err_snap = err_snap;
summary.relerr_snap = relerr_snap;
summary.speeds = speeds;
summary.macro_speed = macro_speed;
summary.final_table = Tfinal;
summary.error_by_time_table = Ttime;
summary.relative_error_by_time_table = TtimeRel;
summary.data_dir = data_dir;
summary.fig_dir = fullfile(root_dir, 'post', 'figures');

% ------------------------------------------------------------
% 保存合并文件。
% ------------------------------------------------------------
save(out_file, 'p', 'eps_list', 'macro', 'kins', ...
    'err_final', 'relerr_final', 'err_snap', 'relerr_snap', ...
    'speeds', 'macro_speed', 'snap_times', ...
    'Tfinal', 'Ttime', 'TtimeRel', 'summary', '-v7.3');

writetable(Tfinal, fullfile(data_dir, 'AP_error_summary_merged.csv'));
writetable(Ttime, fullfile(data_dir, 'AP_error_by_time_merged.csv'));
writetable(TtimeRel, fullfile(data_dir, 'AP_relative_error_by_time_merged.csv'));

fprintf('\nMerged file saved:\n%s\n', out_file);

end


% =====================================================================
% 文件名解析
% =====================================================================

function [eps_val, t_val, ok] = local_parse_eps_time_from_filename(filename)
% 从文件名解析 epsilon 和时间。
%
% 支持：
%   kinetic_eps_0p1_t_001p000.mat
%   kinetic_eps_0p001_t_050p000.mat
%   xxx_kinetic_eps_0p001_t_050p000_xxx.mat

eps_val = NaN;
t_val   = NaN;
ok = false;

[~, name_no_ext, ~] = fileparts(filename);

tok = regexp(name_no_ext, 'kinetic_eps_([^_]+)_t_([0-9]+p[0-9]+|[0-9]+)', ...
    'tokens', 'once');

if isempty(tok)
    return;
end

eps_str = strrep(tok{1}, 'p', '.');
t_str   = strrep(tok{2}, 'p', '.');

eps_val = str2double(eps_str);
t_val   = str2double(t_str);

ok = isfinite(eps_val) && isfinite(t_val);

end


% =====================================================================
% 读取单个 snapshot 文件
% =====================================================================

function [tval, rho, Sval, Nval] = local_extract_snapshot(A, filename)
% 尽量从 snapshot 文件中提取 t, rho, S, N。

tval = [];
rho = [];
Sval = [];
Nval = [];

if isfield(A, 't')
    tval = A.t;
elseif isfield(A, 'time')
    tval = A.time;
elseif isfield(A, 'tn')
    tval = A.tn;
end

if isfield(A, 'rho')
    rho = A.rho;
end

if isfield(A, 'S')
    Sval = A.S;
end

if isfield(A, 'N')
    Nval = A.N;
end

if isempty(rho) && isfield(A, 'U') && isstruct(A.U)
    if isfield(A.U, 'rho')
        rho = A.U.rho;
    end
    if isempty(Sval) && isfield(A.U, 'S')
        Sval = A.U.S;
    end
    if isempty(Nval) && isfield(A.U, 'N')
        Nval = A.U.N;
    end
end

if isempty(rho) && isfield(A, 'snap') && isstruct(A.snap)
    ss = A.snap;

    if isfield(ss, 't') && isempty(tval)
        tval = ss.t;
    end
    if isfield(ss, 'rho')
        rho = ss.rho;
    end
    if isempty(Sval) && isfield(ss, 'S')
        Sval = ss.S;
    end
    if isempty(Nval) && isfield(ss, 'N')
        Nval = ss.N;
    end
end

if isempty(rho)
    names = fieldnames(A);

    for j = 1:numel(names)
        obj = A.(names{j});

        if isstruct(obj)
            if isfield(obj, 't') && isempty(tval)
                tval = obj.t;
            end
            if isfield(obj, 'rho')
                rho = obj.rho;
            end
            if isempty(Sval) && isfield(obj, 'S')
                Sval = obj.S;
            end
            if isempty(Nval) && isfield(obj, 'N')
                Nval = obj.N;
            end
        end

        if ~isempty(rho)
            break;
        end
    end
end

if isempty(tval)
    [~, tval, ok] = local_parse_eps_time_from_filename(filename);
    if ~ok
        error('Cannot parse time from filename: %s', filename);
    end
end

if isempty(rho)
    error('Cannot find rho in snapshot file: %s', filename);
end

tval = double(tval);

end


% =====================================================================
% 误差重算
% =====================================================================

function [err_final, relerr_final, err_snap, relerr_snap, speeds] = ...
    local_recompute_diagnostics(macro, kins, eps_list, snap_times)

nEps = numel(eps_list);
nT = numel(macro.snap);

x = local_get_grid_x(macro);
dx = local_get_grid_dx(macro, x);

err_final = nan(1, nEps);
relerr_final = nan(1, nEps);
err_snap = nan(nEps, nT);
relerr_snap = nan(nEps, nT);
speeds = nan(1, nEps);

rho_ref_norm_final = sqrt(dx * sum(macro.U.rho(:).^2));

for m = 1:nEps

    rho_k = kins{m}.U.rho(:);
    rho_m = macro.U.rho(:);

    err_final(m) = sqrt(dx * sum((rho_k - rho_m).^2));
    relerr_final(m) = err_final(m) / max(rho_ref_norm_final, eps);

    if isfield(kins{m}, 'speed')
        speeds(m) = kins{m}.speed;
    end

    t_kin = local_get_snap_times(kins{m}.snap, []);

    for k = 1:nT
        t_target = snap_times(k);

        rho_ks = local_get_rho_at_time(kins{m}.snap, t_kin, t_target);
        rho_ms = macro.snap(k).rho(:);

        err_snap(m,k) = sqrt(dx * sum((rho_ks - rho_ms).^2));

        rho_ref_norm = sqrt(dx * sum(rho_ms.^2));
        relerr_snap(m,k) = err_snap(m,k) / max(rho_ref_norm, eps);
    end
end

end


function rho = local_get_rho_at_time(snap, times, t_target)
% 在 snap 中找到最接近 t_target 的 rho。

[dtmin, id] = min(abs(times - t_target));

if dtmin > 1e-8
    warning('Using nearest snapshot t=%g for target t=%g.', times(id), t_target);
end

rho = snap(id).rho(:);

end


% =====================================================================
% 网格和时间辅助函数
% =====================================================================

function x = local_get_grid_x(macro)

if ~isfield(macro, 'grid')
    error('macro.grid does not exist.');
end

g = macro.grid;

if isfield(g, 'x')
    x = g.x(:);
elseif isfield(g, 'xc')
    x = g.xc(:);
elseif isfield(g, 'xr')
    x = g.xr(:);
elseif isfield(g, 'xrho')
    x = g.xrho(:);
else
    if isfield(macro, 'U') && isfield(macro.U, 'rho')
        Nx = numel(macro.U.rho);
    elseif isfield(macro, 'snap') && ~isempty(macro.snap)
        Nx = numel(macro.snap(1).rho);
    else
        error('Cannot infer grid size from macro.');
    end

    if isfield(g, 'dx')
        dx = g.dx;
    else
        error('Cannot infer x because macro.grid.dx is missing.');
    end

    x = ((0:Nx-1)' + 0.5) * dx;
end

end


function dx = local_get_grid_dx(macro, x)

if isfield(macro, 'grid') && isfield(macro.grid, 'dx')
    dx = macro.grid.dx;
elseif numel(x) >= 2
    dx = mean(diff(x));
else
    error('Cannot determine dx.');
end

end


function times = local_get_snap_times(snaps, fallback)

if isempty(snaps)
    times = fallback;
    return;
end

nT = numel(snaps);
times = nan(1, nT);

for k = 1:nT
    if isfield(snaps(k), 't')
        times(k) = snaps(k).t;
    elseif ~isempty(fallback) && numel(fallback) >= k
        times(k) = fallback(k);
    else
        times(k) = k - 1;
    end
end

end


% =====================================================================
% 质心与波速
% =====================================================================

function xmass = local_compute_center_of_mass_history(x, dx, snaps)

nT = numel(snaps);
xmass = nan(1, nT);

for k = 1:nT
    rho = snaps(k).rho(:);
    mass = dx * sum(rho);

    if mass <= 0 || ~isfinite(mass)
        xmass(k) = NaN;
    else
        xmass(k) = dx * sum(x(:).*rho) / mass;
    end
end

end


function speed = local_finite_diff_speed(t, xmass)

t = t(:);
xmass = xmass(:);

n = numel(t);
speed = nan(n,1);

if n == 1
    return;
elseif n == 2
    speed(1) = (xmass(2)-xmass(1)) / (t(2)-t(1));
    speed(2) = speed(1);
    return;
end

speed(1)   = (xmass(2)-xmass(1)) / (t(2)-t(1));
speed(end) = (xmass(end)-xmass(end-1)) / (t(end)-t(end-1));

for k = 2:n-1
    speed(k) = (xmass(k+1)-xmass(k-1)) / (t(k+1)-t(k-1));
end

end


% =====================================================================
% 变量名辅助函数
% =====================================================================

function names = local_time_varnames(times)

names = cell(1, numel(times));

for k = 1:numel(times)
    s = sprintf('t_%g', times(k));
    s = strrep(s, '.', 'p');
    s = strrep(s, '-', 'm');
    names{k} = matlab.lang.makeValidName(s);
end

end


function root_dir = local_find_project_root()

this_file = mfilename('fullpath');
this_dir  = fileparts(this_file);

candidates = { ...
    this_dir, ...
    fileparts(this_dir), ...
    fileparts(fileparts(this_dir))};

for k = 1:numel(candidates)
    cand = candidates{k};

    if isempty(cand)
        continue;
    end

    if exist(fullfile(cand, 'data'), 'dir') || ...
       exist(fullfile(cand, 'startup_AP_bacteria.m'), 'file')
        root_dir = cand;
        return;
    end
end

root_dir = fileparts(this_dir);

end
