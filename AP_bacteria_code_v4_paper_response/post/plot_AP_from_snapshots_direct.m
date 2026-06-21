function plot_AP_from_snapshots_direct()
%PLOT_AP_FROM_SNAPSHOTS_DIRECT
% 直接从 data/AP_profiles/snapshots 中读取 kinetic snapshot，
% 并绘制 AP profile 比较图、指定时刻 L2 误差图和波速比较图。
%
% 说明：
%   1. kinetic 数据直接从 snapshot 文件读取。
%   2. macro 数据和网格从 data/AP_profiles/AP_profiles.mat 中读取。
%   3. 可分别指定 profile、error、speed 使用哪些 epsilon。
%   4. 可分别指定 profile、error 使用的 snapshot 时间间隔。
%   5. 波速图可指定输出时间间隔和局部拟合窗口。
%
% 输出：
%   post/figures/AP_profiles_direct.pdf/png/fig/eps
%   post/figures/AP_error_T50_direct.pdf/png/fig/eps
%   post/figures/AP_speed_direct.pdf/png/fig/eps
%
% 数据输出：
%   data/AP_profiles/AP_direct_data.mat
%   data/AP_profiles/AP_error_T50_direct.csv
%   data/AP_profiles/AP_speed_direct.csv
%   data/AP_profiles/AP_speed_direct.mat

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

if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

% ============================================================
% 用户可修改区域
% ============================================================

% profile 图使用的时刻
times_profile = [1, 10, 20, 30, 40, 50];

% profile 图中想画哪些 epsilon
% 设为空数组 [] 表示使用 snapshots 中所有识别到的 epsilon
eps_profile_wanted = [1e-1, 5e-2, 1e-2, 1e-3];

% 误差图中想画哪些 epsilon
% 设为空数组 [] 表示使用所有识别到的 epsilon
eps_error_wanted = [];

% 波速图中想画哪些 epsilon
% 如果只有 0.1 时间间隔的数据适合画波速，建议只写这些
eps_speed_wanted = [1e-1, 5e-2, 1e-2];

% 误差图观测时刻
Ttarget = 30;

% profile 图横坐标范围
x_range_profile = [0, 40];

% 波速图时间范围
speed_time_range = [0, 30];

% 波速图输出时间间隔
speed_plot_dt = 0.5;

% 局部拟合窗口长度
% 每个 t0 使用 [t0-fit_window/2, t0+fit_window/2] 中的质心做线性拟合
% 想更平滑可设为 1.5 或 2.0，想更贴近原始差分可设为 0.4 或 0.5
speed_fit_window = 1.0;

% 解析预测波速
sigma_pred = 0.724;

% 指定读取哪些 snapshot 时间
% [] 表示不筛选，读取全部
% 1 表示只使用整数时刻
% 0.1 表示只使用 0.1 间隔时刻
dt_filter_profile = 1;
dt_filter_error   = 1;
dt_filter_speed   = 0.1;

% 判断时间是否落在 dt_filter 整数倍上的容差
time_tol = 1e-8;

% ============================================================
% 读取 macro 和网格
% ============================================================

base_file = fullfile(data_dir, 'AP_profiles.mat');

if ~exist(base_file, 'file')
    error(['Cannot find data/AP_profiles/AP_profiles.mat.\n', ...
           'This file is needed to provide macro.snap and grid information.']);
end

Sbase = load(base_file);

if ~isfield(Sbase, 'macro')
    error('AP_profiles.mat must contain macro.');
end

macro = Sbase.macro;

x  = local_get_grid_x(macro);
dx = local_get_grid_dx(macro, x);

macro_times = local_get_snap_times(macro.snap, []);

% ============================================================
% 扫描 kinetic snapshot 文件
% ============================================================

snapshot_db = local_scan_kinetic_snapshots(snap_dir);

fprintf('\nDetected epsilon values in snapshots:\n');
disp(snapshot_db.eps_all);

% ============================================================
% 按用户指定 epsilon 和 dt 读取数据
% ============================================================

eps_profile = local_select_eps_values(snapshot_db.eps_all, eps_profile_wanted, 'profile');
eps_error   = local_select_eps_values(snapshot_db.eps_all, eps_error_wanted,   'error');
eps_speed   = local_select_eps_values(snapshot_db.eps_all, eps_speed_wanted,   'speed');

fprintf('eps used for profile figure:\n');
disp(eps_profile);

fprintf('eps used for error figure:\n');
disp(eps_error);

fprintf('eps used for speed figure:\n');
disp(eps_speed);

kin_profile = local_read_kinetic_set(snapshot_db, eps_profile, dt_filter_profile, time_tol);
kin_error   = local_read_kinetic_set(snapshot_db, eps_error,   dt_filter_error,   time_tol);
kin_speed   = local_read_kinetic_set(snapshot_db, eps_speed,   dt_filter_speed,   time_tol);

% ============================================================
% 画 profile 图
% ============================================================

local_plot_profiles_direct(x, macro, kin_profile, eps_profile, times_profile, ...
    x_range_profile, fig_dir);

% ============================================================
% 画 T=Ttarget 的 L2 误差图
% ============================================================

local_plot_error_at_time_direct(x, dx, macro, kin_error, eps_error, Ttarget, fig_dir);

% ============================================================
% 画波速图
% ============================================================

local_plot_speed_direct(x, dx, macro, kin_speed, eps_speed, speed_time_range, ...
    speed_plot_dt, speed_fit_window, sigma_pred, fig_dir);

% ============================================================
% 保存直接读取后的数据
% ============================================================

direct_data = struct();
direct_data.x = x;
direct_data.dx = dx;
direct_data.macro = macro;
direct_data.macro_times = macro_times;
direct_data.snapshot_db = snapshot_db;
direct_data.eps_profile = eps_profile;
direct_data.eps_error = eps_error;
direct_data.eps_speed = eps_speed;
direct_data.kin_profile = kin_profile;
direct_data.kin_error = kin_error;
direct_data.kin_speed = kin_speed;
direct_data.times_profile = times_profile;
direct_data.Ttarget = Ttarget;
direct_data.speed_time_range = speed_time_range;
direct_data.speed_plot_dt = speed_plot_dt;
direct_data.speed_fit_window = speed_fit_window;
direct_data.sigma_pred = sigma_pred;
direct_data.dt_filter_profile = dt_filter_profile;
direct_data.dt_filter_error = dt_filter_error;
direct_data.dt_filter_speed = dt_filter_speed;

save(fullfile(data_dir, 'AP_direct_data.mat'), 'direct_data', '-v7.3');

fprintf('\nDirect AP plotting completed.\n');
fprintf('Figures saved in:\n%s\n', fig_dir);
fprintf('Data saved as:\n%s\n', fullfile(data_dir, 'AP_direct_data.mat'));

end


% =====================================================================
% 扫描 snapshot 文件
% =====================================================================

function snapshot_db = local_scan_kinetic_snapshots(snap_dir)
% 扫描 snapshots 文件夹中的 kinetic_eps_..._t_....mat 文件

files_all = dir(fullfile(snap_dir, '*.mat'));

if isempty(files_all)
    error('No .mat files found in:\n%s', snap_dir);
end

items = struct('eps', {}, 't', {}, 'name', {}, 'path', {});

for k = 1:numel(files_all)
    fname = files_all(k).name;
    [eps_val, t_val, ok] = local_parse_kinetic_filename(fname);

    if ok
        item = struct();
        item.eps = eps_val;
        item.t = t_val;
        item.name = fname;
        item.path = fullfile(snap_dir, fname);
        items(end+1) = item; %#ok<AGROW>
    end
end

if isempty(items)
    error('No kinetic snapshot files were recognized in:\n%s', snap_dir);
end

eps_all = unique([items.eps]);
eps_all = sort(eps_all, 'descend');

snapshot_db = struct();
snapshot_db.snap_dir = snap_dir;
snapshot_db.items = items;
snapshot_db.eps_all = eps_all;

end


function [eps_val, t_val, ok] = local_parse_kinetic_filename(filename)
% 从 kinetic_eps_0p1_t_001p000.mat 解析 epsilon 和时间

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


% =====================================================================
% 读取指定 epsilon 的 kinetic 数据
% =====================================================================

function kin_set = local_read_kinetic_set(snapshot_db, eps_list, dt_filter, time_tol)
% 从 snapshot_db 中读取指定 epsilon 的 kinetic snapshots
%
% dt_filter:
%   []  不筛选时间
%   1   只取整数时刻
%   0.1 只取 0.1 间隔时刻

kin_set = cell(size(eps_list));

items = snapshot_db.items;
eps_all_files = [items.eps];
t_all_files = [items.t];

for m = 1:numel(eps_list)

    eps_val = eps_list(m);

    idx_eps = find(abs(eps_all_files - eps_val) <= ...
        max(1e-14, 1e-10 * max(1, abs(eps_val))));

    if isempty(idx_eps)
        error('No snapshot files found for eps = %g.', eps_val);
    end

    if ~isempty(dt_filter)
        keep = false(size(idx_eps));

        for j = 1:numel(idx_eps)
            tval = t_all_files(idx_eps(j));
            keep(j) = abs(tval/dt_filter - round(tval/dt_filter)) <= time_tol;
        end

        idx_eps = idx_eps(keep);
    end

    if isempty(idx_eps)
        error('No snapshots remain for eps = %g after dt_filter = %g.', eps_val, dt_filter);
    end

    [~, order] = sort(t_all_files(idx_eps));
    idx_eps = idx_eps(order);

    snap = struct('t', {}, 'rho', {}, 'S', {}, 'N', {});

    for j = 1:numel(idx_eps)
        id = idx_eps(j);
        A = load(items(id).path);

        [rho, Sval, Nval] = local_extract_snapshot_data(A, items(id).name);

        item = struct();
        item.t = items(id).t;
        item.rho = rho(:);
        item.S = [];
        item.N = [];

        if ~isempty(Sval)
            item.S = Sval(:);
        end

        if ~isempty(Nval)
            item.N = Nval(:);
        end

        snap(end+1) = item; %#ok<AGROW>
    end

    kin = struct();
    kin.eps = eps_val;
    kin.snap = snap;
    kin.times = [snap.t];

    kin.U = struct();
    kin.U.rho = snap(end).rho(:);

    if isfield(snap(end), 'S') && ~isempty(snap(end).S)
        kin.U.S = snap(end).S(:);
    end

    if isfield(snap(end), 'N') && ~isempty(snap(end).N)
        kin.U.N = snap(end).N(:);
    end

    kin_set{m} = kin;

    if numel(kin.times) >= 2
        fprintf('Read eps = %-10g  Nt = %-5d  t = [%g,%g], min dt = %g, max dt = %g\n', ...
            eps_val, numel(kin.times), min(kin.times), max(kin.times), ...
            min(diff(kin.times)), max(diff(kin.times)));
    else
        fprintf('Read eps = %-10g  Nt = %-5d\n', eps_val, numel(kin.times));
    end
end

end


function [rho, Sval, Nval] = local_extract_snapshot_data(A, filename)
% 从 snapshot 文件中读取 rho, S, N
% 兼容直接变量 rho/S/N、结构体 U.rho、结构体 snap.rho

rho = [];
Sval = [];
Nval = [];

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
    if isfield(A.snap, 'rho')
        rho = A.snap.rho;
    end
    if isempty(Sval) && isfield(A.snap, 'S')
        Sval = A.snap.S;
    end
    if isempty(Nval) && isfield(A.snap, 'N')
        Nval = A.snap.N;
    end
end

if isempty(rho)
    names = fieldnames(A);

    for j = 1:numel(names)
        obj = A.(names{j});

        if isstruct(obj) && isfield(obj, 'rho')
            rho = obj.rho;

            if isempty(Sval) && isfield(obj, 'S')
                Sval = obj.S;
            end
            if isempty(Nval) && isfield(obj, 'N')
                Nval = obj.N;
            end

            break;
        end
    end
end

if isempty(rho)
    error('Cannot find rho in snapshot file: %s', filename);
end

end


% =====================================================================
% epsilon 筛选
% =====================================================================

function eps_use = local_select_eps_values(eps_all, eps_wanted, label_name)
% 从 eps_all 中筛选 eps_wanted
% 若 eps_wanted = []，则使用所有 epsilon

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
        warning('For %s, requested eps = %g was not found and will be skipped.', ...
            label_name, target);
    end
end

idx_use = idx_use(isfinite(idx_use));
idx_use = unique(idx_use, 'stable');

if isempty(idx_use)
    error('No requested epsilon values were found for %s.', label_name);
end

eps_use = eps_all(idx_use);

end


% =====================================================================
% Profile 图
% =====================================================================

function local_plot_profiles_direct(x, macro, kin_set, eps_list, target_times, x_range, fig_dir)
% 直接由 snapshot 数据画 profile 对比图

font_size = 20;
basename = fullfile(fig_dir, 'AP_profiles_direct');

nTimes = numel(target_times);

macro_times = local_get_snap_times(macro.snap, []);
idx_macro = zeros(1, nTimes);
actual_times = zeros(1, nTimes);

for q = 1:nTimes
    [~, idx_macro(q)] = min(abs(macro_times - target_times(q)));
    actual_times(q) = macro_times(idx_macro(q));
end

xmask = (x >= x_range(1)) & (x <= x_range(2));
ymax_common = 0;

for q = 1:nTimes
    rho_macro = macro.snap(idx_macro(q)).rho(:);
    ymax_common = max(ymax_common, max(rho_macro(xmask)));

    for m = 1:numel(eps_list)
        rho_kin = local_get_rho_at_time(kin_set{m}.snap, target_times(q));
        ymax_common = max(ymax_common, max(rho_kin(xmask)));
    end
end

if ymax_common <= 0 || ~isfinite(ymax_common)
    ymax_common = 0.10;
end

ymax_common = local_round_to_step(1.05 * ymax_common, 0.05, 'up');

if ymax_common <= 0.30
    dy = 0.05;
elseif ymax_common <= 0.60
    dy = 0.10;
else
    dy = 0.20;
end

ytick_vals = 0:dy:ymax_common;

fig = figure('Color', 'w', 'Position', [100 100 1200 620]);
hold on; box on;

eps_colors = lines(max(numel(eps_list), 1));
eps_styles = {'-', '--', '-.', ':', '-', '--', '-.', ':'};
nStyle = numel(eps_styles);

legend_handles = gobjects(0);

for q = 1:nTimes

    for m = 1:numel(eps_list)
        rho_kin = local_get_rho_at_time(kin_set{m}.snap, target_times(q));

        this_color = eps_colors(m,:);
        this_style = eps_styles{mod(m-1, nStyle) + 1};

        if q == 1
            h = plot(x, rho_kin, ...
                'Color', this_color, ...
                'LineStyle', this_style, ...
                'LineWidth', 2.2, ...
                'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
            legend_handles(end+1) = h; %#ok<AGROW>
        else
            plot(x, rho_kin, ...
                'Color', this_color, ...
                'LineStyle', this_style, ...
                'LineWidth', 2.2, ...
                'HandleVisibility', 'off');
        end
    end

    rho_macro = macro.snap(idx_macro(q)).rho(:);

    if q == 1
        h = plot(x, rho_macro, 'k-', ...
            'LineWidth', 3.0, ...
            'DisplayName', 'macro');
        legend_handles(end+1) = h; %#ok<AGROW>
    else
        plot(x, rho_macro, 'k-', ...
            'LineWidth', 3.0, ...
            'HandleVisibility', 'off');
    end

    local_add_time_label(x, rho_macro, actual_times(q), ymax_common, x_range, font_size);
end

xlim(x_range);
ylim([0, ymax_common]);

xticks(x_range(1):10:x_range(2));
yticks(ytick_vals);
yticklabels(arrayfun(@(z) sprintf('%.2f', z), ytick_vals, 'UniformOutput', false));

xlabel('$x$', 'Interpreter', 'latex', 'FontSize', font_size);
ylabel('$\rho(x,t)$', 'Interpreter', 'latex', 'FontSize', font_size);

set(gca, ...
    'FontSize', font_size, ...
    'LineWidth', 1.2, ...
    'TickLabelInterpreter', 'latex');

grid on;

lgd = legend(legend_handles, 'Interpreter', 'latex', ...
    'Location', 'southoutside', ...
    'Orientation', 'horizontal', ...
    'NumColumns', min(numel(eps_list) + 1, 4), ...
    'Box', 'on');
lgd.FontSize = font_size - 4;

local_export_figure(fig, basename);

end


function local_add_time_label(x, rho, tval, ymax_common, x_range, font_size)
% 在对应波峰附近添加时间标注

[peak_val, peak_idx] = max(rho);
x_peak = x(peak_idx);

x_text = x_peak - 2.5;
y_text = min(ymax_common * 0.88, peak_val + 0.08 * ymax_common);

if x_text < x_range(1) + 1
    x_text = x_peak + 1.5;
end

if x_text > x_range(2) - 5
    x_text = x_range(2) - 5;
end

if y_text < 0.10 * ymax_common
    y_text = 0.18 * ymax_common;
end

text(x_text, y_text, sprintf('$t=%g$', tval), ...
    'Interpreter', 'latex', ...
    'FontSize', font_size, ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'none', ...
    'Margin', 4);

end


% =====================================================================
% 误差图
% =====================================================================

function local_plot_error_at_time_direct(x, dx, macro, kin_set, eps_list, Ttarget, fig_dir)
% 直接由 snapshot 数据画 T=Ttarget 时的误差图

font_size = 16;
basename = fullfile(fig_dir, sprintf('AP_error_T%g_direct', Ttarget));

macro_times = local_get_snap_times(macro.snap, []);
[~, idx_macro] = min(abs(macro_times - Ttarget));
Tuse = macro_times(idx_macro);

rho_macro = macro.snap(idx_macro).rho(:);

err_T = nan(1, numel(eps_list));

for m = 1:numel(eps_list)
    rho_kin = local_get_rho_at_time(kin_set{m}.snap, Tuse);
    err_T(m) = sqrt(dx * sum((rho_kin - rho_macro).^2));
end

eps_col = eps_list(:);
E_col = err_T(:);

valid = isfinite(eps_col) & eps_col > 0 & isfinite(E_col) & E_col > 0;
eps_col = eps_col(valid);
E_col = E_col(valid);

[eps_col, id] = sort(eps_col);
E_col = E_col(id);

fig = figure('Color', 'w', 'Position', [100 100 560 430]);
hold on; box on;

loglog(eps_col, E_col, 'o-', ...
    'LineWidth', 1.9, ...
    'MarkerSize', 7, ...
    'MarkerFaceColor', 'w', ...
    'DisplayName', 'numerical error');

% 一阶和二阶参考线
eps_ref = eps_col(end);
E_ref = E_col(end);

ref_order1 = E_ref * (eps_col / eps_ref);
ref_order2 = E_ref * (eps_col / eps_ref).^2;

loglog(eps_col, ref_order1, 'k--', ...
    'LineWidth', 1.3, ...
    'DisplayName', '$O(\varepsilon)$');

loglog(eps_col, ref_order2, 'k-.', ...
    'LineWidth', 1.3, ...
    'DisplayName', '$O(\varepsilon^2)$');

xlabel('$\varepsilon$', 'Interpreter', 'latex', 'FontSize', font_size);
ylabel('$\|\rho^\varepsilon(\cdot,T)-\rho(\cdot,T)\|_{L^2}$', ...
    'Interpreter', 'latex', ...
    'FontSize', font_size);

title(sprintf('Density error at $T=%g$', Tuse), ...
    'Interpreter', 'latex', ...
    'FontWeight', 'normal');

set(gca, ...
    'XScale', 'log', ...
    'YScale', 'log', ...
    'FontSize', font_size, ...
    'LineWidth', 1.0, ...
    'TickLabelInterpreter', 'latex');

x_left  = 10^(log10(min(eps_col)) - 0.08);
x_right = 10^(log10(max(eps_col)) + 0.08);
xlim([x_left, x_right]);

legend('Interpreter', 'latex', ...
    'Location', 'northwest', ...
    'Box', 'on');

grid on;

local_export_figure(fig, basename);

% 保存误差数据
data_dir = fullfile(local_find_project_root(), 'data', 'AP_profiles');
Terror = table(eps_col, E_col, ...
    'VariableNames', {'eps', 'L2_error'});
writetable(Terror, fullfile(data_dir, sprintf('AP_error_T%g_direct.csv', Tuse)));

end


% =====================================================================
% 波速图
% =====================================================================

function local_plot_speed_direct(x, dx, macro, kin_set, eps_list, time_range, speed_plot_dt, fit_window, sigma_pred, fig_dir)
% 直接由 snapshot 数据画 travelling speed 图
% 波速由质心轨迹局部线性拟合得到

font_size = 16;
basename = fullfile(fig_dir, 'AP_speed_direct');

t_plot = (time_range(1):speed_plot_dt:time_range(2)).';

% macro 波速
macro_times = local_get_snap_times(macro.snap, []);
xmass_macro = local_compute_center_of_mass_history(x, dx, macro.snap);
speed_macro = local_fit_speed_on_grid(macro_times(:), xmass_macro(:), t_plot, fit_window);

fig = figure('Color', 'w', 'Position', [100 100 720 460]);
hold on; box on;

plot(t_plot, speed_macro, 'k-', ...
    'LineWidth', 2.4, ...
    'DisplayName', 'macro');

% 解析预测波速，不从最左端开始
x_margin = 0.08 * (time_range(2) - time_range(1));
x_pred = [time_range(1) + x_margin, time_range(2)];

plot(x_pred, [sigma_pred, sigma_pred], 'k--', ...
    'LineWidth', 1.6, ...
    'DisplayName', sprintf('$\\sigma_{\\mathrm{pred}}=%.3f$', sigma_pred));

eps_colors = lines(max(numel(eps_list), 1));
eps_styles = {'-', '--', '-.', ':', '-', '--', '-.', ':'};
nStyle = numel(eps_styles);

speed_mat = nan(numel(t_plot), numel(eps_list));

for m = 1:numel(eps_list)
    t_raw = [kin_set{m}.snap.t].';
    xmass_raw = local_compute_center_of_mass_history(x, dx, kin_set{m}.snap);

    speed_plot = local_fit_speed_on_grid(t_raw, xmass_raw(:), t_plot, fit_window);
    speed_mat(:,m) = speed_plot;

    plot(t_plot, speed_plot, ...
        'Color', eps_colors(m,:), ...
        'LineStyle', eps_styles{mod(m-1,nStyle)+1}, ...
        'LineWidth', 1.8, ...
        'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
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

local_export_figure(fig, basename);

% 保存速度数据
data_dir = fullfile(local_find_project_root(), 'data', 'AP_profiles');
Tsave = table(t_plot, speed_macro(:), ...
    'VariableNames', {'time', 'speed_macro'});

for m = 1:numel(eps_list)
    vname = local_eps_varname('speed_eps', eps_list(m));
    Tsave.(vname) = speed_mat(:,m);
end

writetable(Tsave, fullfile(data_dir, 'AP_speed_direct.csv'));

speed_data = struct();
speed_data.t_plot = t_plot;
speed_data.eps_list = eps_list(:);
speed_data.speed_macro = speed_macro(:);
speed_data.speed_kinetic = speed_mat;
speed_data.sigma_pred = sigma_pred;
speed_data.fit_window = fit_window;
speed_data.speed_plot_dt = speed_plot_dt;

save(fullfile(data_dir, 'AP_speed_direct.mat'), 'speed_data');

end


% =====================================================================
% 从 snap 中取指定时刻 rho
% =====================================================================

function rho = local_get_rho_at_time(snap, target_time)
% 在 snap 中找到最接近 target_time 的 rho

times = [snap.t];
[dtmin, id] = min(abs(times - target_time));

if dtmin > 1e-8
    warning('Using nearest snapshot t=%g for target t=%g.', times(id), target_time);
end

rho = snap(id).rho(:);

end


% =====================================================================
% 网格、质心、波速辅助函数
% =====================================================================

function x = local_get_grid_x(macro)
% 从 macro.grid 中读取空间网格

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
% 获取空间步长 dx

if isfield(macro, 'grid') && isfield(macro.grid, 'dx')
    dx = macro.grid.dx;
elseif numel(x) >= 2
    dx = mean(diff(x));
else
    error('Cannot determine dx.');
end

end


function times = local_get_snap_times(snaps, fallback)
% 从 snapshots 中读取时间列表

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
% 计算质心轨迹

nT = numel(snaps);
xmass = nan(1, nT);

for k = 1:nT
    rho = snaps(k).rho(:);
    xmass(k) = local_center_of_mass(x, dx, rho);
end

end


function xm = local_center_of_mass(x, dx, rho)
% 计算一个密度 profile 的质心

mass = dx * sum(rho);

if mass <= 0 || ~isfinite(mass)
    xm = NaN;
else
    xm = dx * sum(x(:).*rho(:)) / mass;
end

end


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
% 其他辅助函数
% =====================================================================

function y = local_round_to_step(x, step, direction)
% 将数值按照给定 step 向上或向下取整

switch lower(direction)
    case 'up'
        y = step * ceil(x / step);
    case 'down'
        y = step * floor(x / step);
    otherwise
        error('direction must be ''up'' or ''down''.');
end

end


function name = local_eps_varname(prefix, epsval)
% 根据 epsilon 生成合法变量名

s = sprintf('%.0e', epsval);
s = strrep(s, '-', 'm');
s = strrep(s, '+', '');
s = strrep(s, '.', 'p');

name = matlab.lang.makeValidName([prefix, '_', s]);

end


function local_export_figure(fig_handle, basename)
% 同时保存 PDF, PNG, MATLAB FIG 和 EPS 文件

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
% 自动寻找项目根目录

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