function plot_speed_from_snapshots_direct()
%PLOT_SPEED_FROM_SNAPSHOTS_DIRECT
% 直接从 data/AP_profiles/snapshots 中读取 kinetic snapshot，
% 计算不同 epsilon 的质心和 travelling speed，并绘制波速比较图。
%
% 这个程序不依赖 AP_profiles_merged.mat，也不做 merge。
%
% 输出：
%   post/figures/AP_speed_direct.pdf
%   post/figures/AP_speed_direct.png
%   post/figures/AP_speed_direct.fig
%   post/figures/AP_speed_direct.eps
%
%   data/AP_profiles/AP_speed_direct.mat
%   data/AP_profiles/AP_speed_direct.csv
%
% 说明：
%   1. 速度由密度质心 X_rho(t) 得到。
%   2. 为了避免相邻差分抖动，使用局部线性拟合得到波速。
%   3. 若 snapshot 时间间隔为 0.1，则输出波速也按 0.1 间隔画图。

clear; clc; close all;

root_dir = local_find_project_root();

data_dir = fullfile(root_dir, 'data', 'AP_profiles');
snap_dir = fullfile(data_dir, 'snapshots');
fig_dir  = fullfile(root_dir, 'post', 'figures');

if ~exist(snap_dir, 'dir')
    error('Cannot find snapshot directory:\n%s', snap_dir);
end

if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

% ============================================================
% 用户可修改区域
% ============================================================

% 只画这些 epsilon 的波速。
% 建议只画你已经保存了 0.1 时间间隔的几组。
eps_wanted = [1e-1, 5e-2, 1e-2];

% 时间范围。
time_range = [0, 50];

% 波速输出时间间隔。
% 如果你的 snapshot 是 0.1 间隔，就设为 0.1。
speed_plot_dt = 0.1;

% 局部拟合窗口长度。
% 例如 1.0 表示在 [t-0.5,t+0.5] 中拟合质心斜率。
% 如果想更平滑可设为 1.5 或 2.0。
% 如果想更接近原始差分，可设为 0.4 或 0.5。
fit_window = 1.0;

% 解析预测波速。
sigma_pred = 0.724;

% 是否画 macro 波速。
% macro 这里从 AP_profiles.mat 中读取 macro.snap。
plot_macro = true;

% ============================================================
% 读取基础网格和 macro 数据
% ============================================================

base_file = fullfile(data_dir, 'AP_profiles.mat');

if exist(base_file, 'file')
    Sbase = load(base_file);
else
    Sbase = struct();
end

if isfield(Sbase, 'macro')
    macro = Sbase.macro;
else
    macro = [];
end

% 从 macro.grid 或 snapshot 文件中获取网格
if ~isempty(macro)
    x = local_get_grid_x(macro);
    dx = local_get_grid_dx(macro, x);
else
    error(['Cannot find macro data in AP_profiles.mat. ', ...
           'Need macro.grid to reconstruct x for center of mass.']);
end

% ============================================================
% 直接扫描 kinetic snapshot 文件
% ============================================================

files_all = dir(fullfile(snap_dir, '*.mat'));

if isempty(files_all)
    error('No .mat files found in:\n%s', snap_dir);
end

file_info = struct('name', {}, 'eps', {}, 't', {}, 'path', {});

for k = 1:numel(files_all)
    fname = files_all(k).name;
    [eps_val, t_val, ok] = local_parse_kinetic_filename(fname);

    if ok
        item = struct();
        item.name = fname;
        item.eps  = eps_val;
        item.t    = t_val;
        item.path = fullfile(snap_dir, fname);
        file_info(end+1) = item; %#ok<AGROW>
    end
end

if isempty(file_info)
    error('No kinetic snapshot files were recognized in:\n%s', snap_dir);
end

eps_all = unique([file_info.eps]);
eps_all = sort(eps_all, 'descend');

fprintf('Detected eps in snapshots:\n');
disp(eps_all);

% 筛选用户指定 epsilon
eps_use = local_select_eps_values(eps_all, eps_wanted);

fprintf('eps used for speed plot:\n');
disp(eps_use);

% ============================================================
% 计算 macro 波速
% ============================================================

t_plot = (time_range(1):speed_plot_dt:time_range(2)).';

macro_speed_plot = [];
macro_t = [];
macro_xmass = [];

if plot_macro && ~isempty(macro) && isfield(macro, 'snap') && ~isempty(macro.snap)
    macro_t = local_get_snap_times(macro.snap, []);
    macro_xmass = local_compute_center_of_mass_history(x, dx, macro.snap);
    macro_speed_plot = local_fit_speed_on_grid(macro_t(:), macro_xmass(:), t_plot, fit_window);
end

% ============================================================
% 计算每个 epsilon 的质心和波速
% ============================================================

speed_data = struct();
speed_data.t_plot = t_plot;
speed_data.eps_list = eps_use(:);
speed_data.sigma_pred = sigma_pred;
speed_data.fit_window = fit_window;
speed_data.speed_plot_dt = speed_plot_dt;
speed_data.time_range = time_range;

if ~isempty(macro_speed_plot)
    speed_data.macro_t = macro_t(:);
    speed_data.macro_xmass = macro_xmass(:);
    speed_data.macro_speed_plot = macro_speed_plot(:);
end

kin_speed_plot = nan(numel(t_plot), numel(eps_use));
kin_xmass_cell = cell(1, numel(eps_use));
kin_t_cell = cell(1, numel(eps_use));

for m = 1:numel(eps_use)

    eps_val = eps_use(m);

    idx_eps = find(abs([file_info.eps] - eps_val) <= max(1e-14, 1e-10 * max(1, abs(eps_val))));

    if isempty(idx_eps)
        warning('No snapshot files found for eps = %g.', eps_val);
        continue;
    end

    % 按时间排序
    [~, order] = sort([file_info(idx_eps).t]);
    idx_eps = idx_eps(order);

    t_list = nan(numel(idx_eps), 1);
    xmass_list = nan(numel(idx_eps), 1);

    for j = 1:numel(idx_eps)
        id = idx_eps(j);
        fname = file_info(id).path;

        A = load(fname);
        rho = local_extract_rho(A, file_info(id).name);
        rho = rho(:);

        t_list(j) = file_info(id).t;
        xmass_list(j) = local_center_of_mass(x, dx, rho);
    end

    % 去除 NaN 并去重
    valid = isfinite(t_list) & isfinite(xmass_list);
    t_list = t_list(valid);
    xmass_list = xmass_list(valid);

    [t_list, ia] = unique(t_list, 'stable');
    xmass_list = xmass_list(ia);

    kin_t_cell{m} = t_list;
    kin_xmass_cell{m} = xmass_list;

    kin_speed_plot(:,m) = local_fit_speed_on_grid(t_list, xmass_list, t_plot, fit_window);

    fprintf('eps = %-10g  Nt = %d, t from %g to %g, min dt = %g\n', ...
        eps_val, numel(t_list), min(t_list), max(t_list), min(diff(t_list)));
end

speed_data.kin_t = kin_t_cell;
speed_data.kin_xmass = kin_xmass_cell;
speed_data.kin_speed_plot = kin_speed_plot;

% ============================================================
% 保存数据
% ============================================================

save(fullfile(data_dir, 'AP_speed_direct.mat'), 'speed_data');

Tsave = table(t_plot, 'VariableNames', {'time'});

if ~isempty(macro_speed_plot)
    Tsave.speed_macro = macro_speed_plot(:);
end

for m = 1:numel(eps_use)
    vname = local_eps_varname('speed_eps', eps_use(m));
    Tsave.(vname) = kin_speed_plot(:,m);
end

writetable(Tsave, fullfile(data_dir, 'AP_speed_direct.csv'));

% ============================================================
% 画图
% ============================================================

font_size = 16;

fig = figure('Color', 'w', 'Position', [100 100 720 460]);
hold on; box on;

if ~isempty(macro_speed_plot)
    plot(t_plot, macro_speed_plot, 'k-', ...
        'LineWidth', 2.4, ...
        'DisplayName', 'macro');
end

% 解析预测波速水平虚线，不从最左端开始
x_margin = 0.08 * (time_range(2) - time_range(1));
x_pred = [time_range(1) + x_margin, time_range(2)];

plot(x_pred, [sigma_pred, sigma_pred], 'k--', ...
    'LineWidth', 1.6, ...
    'DisplayName', sprintf('$\\sigma_{\\mathrm{pred}}=%.3f$', sigma_pred));

eps_colors = lines(max(numel(eps_use), 1));
eps_styles = {'-', '--', '-.', ':', '-', '--', '-.', ':'};
nStyle = numel(eps_styles);

for m = 1:numel(eps_use)
    plot(t_plot, kin_speed_plot(:,m), ...
        'Color', eps_colors(m,:), ...
        'LineStyle', eps_styles{mod(m-1, nStyle)+1}, ...
        'LineWidth', 1.8, ...
        'DisplayName', sprintf('$\\varepsilon=%g$', eps_use(m)));
end

xlim(time_range);

xlabel('$t$', 'Interpreter', 'latex', 'FontSize', font_size);
ylabel('wave speed', 'Interpreter', 'latex', 'FontSize', font_size);

title('Travelling speed comparison', ...
    'Interpreter', 'latex', ...
    'FontWeight', 'normal');

set(gca, ...
    'FontSize', font_size, ...
    'LineWidth', 1.0, ...
    'TickLabelInterpreter', 'latex');

legend('Interpreter', 'latex', ...
    'Location', 'best', ...
    'Box', 'on');

grid on;

basename = fullfile(fig_dir, 'AP_speed_direct');
local_export_figure(fig, basename);

fprintf('\nSaved speed figure:\n%s\n', [basename, '.eps']);
fprintf('Saved speed data:\n%s\n', fullfile(data_dir, 'AP_speed_direct.mat'));
fprintf('Saved speed table:\n%s\n', fullfile(data_dir, 'AP_speed_direct.csv'));

end


% =====================================================================
% 文件名解析
% =====================================================================

function [eps_val, t_val, ok] = local_parse_kinetic_filename(filename)
% 从 kinetic_eps_0p1_t_001p000.mat 解析 epsilon 和时间。

eps_val = NaN;
t_val = NaN;
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


function eps_use = local_select_eps_values(eps_all, eps_wanted)
% 从 eps_all 中筛选 eps_wanted。
% 若 eps_wanted = []，则使用所有 epsilon。

eps_all = eps_all(:).';

if isempty(eps_wanted)
    eps_use = eps_all;
    return;
end

eps_wanted = eps_wanted(:).';
idx_use = nan(size(eps_wanted));

for j = 1:numel(eps_wanted)
    target = eps_wanted(j);

    tol = max(1e-14, 1e-10 * max(1, abs(target)));
    [dist_min, idx] = min(abs(eps_all - target));

    if dist_min <= tol
        idx_use(j) = idx;
    else
        warning('Requested eps = %g was not found in snapshots and will be skipped.', target);
    end
end

idx_use = idx_use(isfinite(idx_use));
idx_use = unique(idx_use, 'stable');

if isempty(idx_use)
    error('No requested epsilon values were found in snapshots.');
end

eps_use = eps_all(idx_use);

end


% =====================================================================
% 读取 rho
% =====================================================================

function rho = local_extract_rho(A, filename)
% 从 snapshot 文件中读取 rho。
% 兼容直接变量 rho、结构体 U.rho、结构体 snap.rho。

rho = [];

if isfield(A, 'rho')
    rho = A.rho;
end

if isempty(rho) && isfield(A, 'U') && isstruct(A.U) && isfield(A.U, 'rho')
    rho = A.U.rho;
end

if isempty(rho) && isfield(A, 'snap') && isstruct(A.snap) && isfield(A.snap, 'rho')
    rho = A.snap.rho;
end

if isempty(rho)
    names = fieldnames(A);

    for j = 1:numel(names)
        obj = A.(names{j});

        if isstruct(obj) && isfield(obj, 'rho')
            rho = obj.rho;
            break;
        end
    end
end

if isempty(rho)
    error('Cannot find rho in snapshot file: %s', filename);
end

end


% =====================================================================
% 网格和质心
% =====================================================================

function x = local_get_grid_x(macro)
% 从 macro.grid 中读取空间网格。

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
% 获取空间步长 dx。

if isfield(macro, 'grid') && isfield(macro.grid, 'dx')
    dx = macro.grid.dx;
elseif numel(x) >= 2
    dx = mean(diff(x));
else
    error('Cannot determine dx.');
end

end


function times = local_get_snap_times(snaps, fallback)
% 从 snapshots 中读取时间列表。

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


function xmass = local_compute_center_of_mass_history(x, dx, snaps)
% 计算 macro.snap 中的质心轨迹。

nT = numel(snaps);
xmass = nan(1, nT);

for k = 1:nT
    rho = snaps(k).rho(:);
    xmass(k) = local_center_of_mass(x, dx, rho);
end

end


function xm = local_center_of_mass(x, dx, rho)
% 计算一个密度 profile 的质心。

mass = dx * sum(rho);

if mass <= 0 || ~isfinite(mass)
    xm = NaN;
else
    xm = dx * sum(x(:).*rho(:)) / mass;
end

end


% =====================================================================
% 局部拟合波速
% =====================================================================

function speed_plot = local_fit_speed_on_grid(t_raw, xmass_raw, t_plot, fit_window)
% 在统一的 t_plot 网格上计算平滑波速。
%
% 思路：
%   先将质心轨迹插值到 t_plot。
%   然后对每个 t0，在 [t0-fit_window/2, t0+fit_window/2]
%   内做线性拟合，拟合斜率作为 t0 处的波速。

t_raw = t_raw(:);
xmass_raw = xmass_raw(:);
t_plot = t_plot(:);

valid = isfinite(t_raw) & isfinite(xmass_raw);
t_raw = t_raw(valid);
xmass_raw = xmass_raw(valid);

speed_plot = nan(size(t_plot));

if numel(t_raw) < 2
    return;
end

[t_raw, ia] = unique(t_raw, 'stable');
xmass_raw = xmass_raw(ia);

xmass_plot = interp1(t_raw, xmass_raw, t_plot, 'pchip', NaN);

half_window = 0.5 * fit_window;

for k = 1:numel(t_plot)
    t0 = t_plot(k);

    idx = abs(t_plot - t0) <= half_window & isfinite(xmass_plot);

    if sum(idx) >= 2
        pp = polyfit(t_plot(idx), xmass_plot(idx), 1);
        speed_plot(k) = pp(1);
    end
end

end


% =====================================================================
% 变量名和图像输出
% =====================================================================

function name = local_eps_varname(prefix, epsval)
% 根据 epsilon 生成合法变量名。

s = sprintf('%.0e', epsval);
s = strrep(s, '-', 'm');
s = strrep(s, '+', '');
s = strrep(s, '.', 'p');

name = matlab.lang.makeValidName([prefix, '_', s]);

end


function local_export_figure(fig_handle, basename)
% 同时保存 PDF, PNG, MATLAB FIG 和 EPS 文件。

try
    savefig(fig_handle, [basename, '.fig']);
catch
    warning('savefig failed for %s.fig.', basename);
end

try
    exportgraphics(fig_handle, [basename, '.pdf'], 'ContentType', 'vector');
catch
    warning('exportgraphics PDF failed. Falling back to saveas.');
    saveas(fig_handle, [basename, '.pdf']);
end

try
    exportgraphics(fig_handle, [basename, '.png'], 'Resolution', 300);
catch
    warning('exportgraphics PNG failed. Falling back to saveas.');
    saveas(fig_handle, [basename, '.png']);
end

try
    exportgraphics(fig_handle, [basename, '.eps'], 'ContentType', 'vector');
catch
    warning('exportgraphics EPS failed. Falling back to print.');
    print(fig_handle, [basename, '.eps'], '-depsc2');
end

end


function root_dir = local_find_project_root()
% 自动寻找项目根目录。

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