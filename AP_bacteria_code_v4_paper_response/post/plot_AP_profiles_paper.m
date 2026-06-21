function plot_AP_profiles_paper()
%PLOT_AP_PROFILES_PAPER
% 读取 AP_profiles 数据，并重新绘制论文风格图像。
%
% 输出图像：
%   post/figures/AP_profiles.pdf/png/fig/eps
%   post/figures/AP_error_T50.pdf/png/fig/eps
%   post/figures/AP_speed_comparison.pdf/png/fig/eps
%
% 输出波速数据：
%   data/AP_profiles/AP_speed_data.mat
%   data/AP_profiles/AP_speed_by_time.csv
%   data/AP_profiles/AP_speed_error_by_time.csv
%   data/AP_profiles/AP_speed_selected_times.csv
%
% 使用说明：
%   1. data_file_name 控制读取哪个数据文件。
%   2. eps_profile_wanted 控制 profile 图中画哪些 epsilon。
%   3. eps_error_wanted 控制误差图中画哪些 epsilon。
%   4. eps_speed_wanted 控制波速比较图中画哪些 epsilon。
%   5. 若某个 eps_wanted 设为空数组 []，则使用数据文件中的所有 epsilon。
%   6. 若指定的 epsilon 在数据文件中不存在，程序会给出 warning 并自动忽略。

clear; clc; close all;

root_dir = local_find_project_root();

% ============================================================
% 用户可修改区域
% ============================================================

% 推荐使用重建后的合并数据文件。
% 如果只想用当前 AP_profiles.mat，则改成 'AP_profiles.mat'。
data_file_name = 'AP_profiles_merged.mat';

% profile 图使用的时刻。
times_group1 = [1, 10, 20, 30, 40, 50];

% profile 图中想画哪些 epsilon。
% 设为空数组 [] 表示画所有可用 epsilon。
eps_profile_wanted = [1e-1, 5e-2, 1e-2, 1e-3];

% 误差图中想画哪些 epsilon。
% 设为空数组 [] 表示画所有可用 epsilon。
eps_error_wanted = [];

% 波速比较图中想画哪些 epsilon。
% 设为空数组 [] 表示画所有可用 epsilon。
% 为了图不太乱，默认与 profile 图保持一致。
eps_speed_wanted = eps_profile_wanted;

% 误差图观测时刻。
Ttarget = 50;

% profile 图横坐标范围。
x_range_profile = [0, 40];

% 波速图时间范围。
speed_time_range = [0, 50];

% 解析预测波速。论文中为 sigma approx 0.724。
sigma_pred = 0.724;

% 是否计算并保存所有可用 epsilon 的波速数据。
save_speed_data = true;

% ============================================================
% 数据读取
% ============================================================

data_file = fullfile(root_dir, 'data', 'AP_profiles', data_file_name);
data_dir  = fullfile(root_dir, 'data', 'AP_profiles');
fig_dir   = fullfile(root_dir, 'post', 'figures');

if ~exist(data_file, 'file')
    error('Data file not found:\n%s', data_file);
end

if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end

if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

fprintf('Using data file:\n%s\n\n', data_file);

S = load(data_file);

if ~isfield(S, 'macro') || ~isfield(S, 'kins') || ~isfield(S, 'eps_list')
    error('The data file must contain macro, kins, and eps_list.');
end

macro    = S.macro;
kins_all = S.kins;
eps_all  = S.eps_list(:).';

fprintf('All eps_list in data file:\n');
disp(eps_all);

if isfield(S, 'snap_times') && ~isempty(S.snap_times)
    snap_times = S.snap_times(:).';
else
    snap_times = local_get_snap_times(macro.snap, []);
end

x  = local_get_grid_x(macro);
dx = local_get_grid_dx(macro, x);

% ============================================================
% 根据用户指定的 epsilon 进行筛选
% ============================================================

[eps_profile, kins_profile] = local_select_eps(eps_all, kins_all, eps_profile_wanted, 'profile');
[eps_error,   kins_error]   = local_select_eps(eps_all, kins_all, eps_error_wanted,   'error');
[eps_speed,   kins_speed]   = local_select_eps(eps_all, kins_all, eps_speed_wanted,   'speed');

fprintf('eps_list used for profile figure:\n');
disp(eps_profile);

fprintf('eps_list used for error figure:\n');
disp(eps_error);

fprintf('eps_list used for speed figure:\n');
disp(eps_speed);

% ============================================================
% 第一张图：profile 对比图
% ============================================================

local_plot_profiles(x, macro, kins_profile, eps_profile, snap_times, ...
    fig_dir, times_group1, x_range_profile);

% ============================================================
% 第二张图：T=Ttarget 时的 L2 误差图
% ============================================================

local_plot_error_at_time(x, dx, macro, kins_error, eps_error, snap_times, ...
    fig_dir, Ttarget);

% ============================================================
% 第三张图：波速随时间比较图
% ============================================================

local_plot_speed_comparison(x, dx, macro, kins_speed, eps_speed, snap_times, ...
    fig_dir, speed_time_range, sigma_pred);

% ============================================================
% 计算并保存波速数据，但不额外画 speed error 图
% 默认对数据文件中的所有 epsilon 计算，避免遗漏。
% ============================================================

if save_speed_data
    selected_speed_times = times_group1;
    local_compute_and_save_speed_data(x, dx, macro, kins_all, eps_all, ...
        snap_times, data_dir, selected_speed_times);
end

fprintf('\nPaper-style figures have been saved in:\n%s\n', fig_dir);
fprintf('Speed data have been saved in:\n%s\n', data_dir);

end


% =====================================================================
% epsilon 筛选函数
% =====================================================================

function [eps_use, kins_use] = local_select_eps(eps_all, kins_all, eps_wanted, label_name)
% 根据用户给定的 eps_wanted 从 eps_all 中筛选数据。
% 若 eps_wanted = []，则使用所有 epsilon。
%
% 匹配时使用相对容差，避免 0.01 和 1e-2 的浮点误差导致匹配失败。

eps_all = eps_all(:).';
kins_all = kins_all(:).';

if isempty(eps_wanted)
    eps_use = eps_all;
    kins_use = reshape(kins_all, size(eps_use));
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
        warning('For %s figure, requested eps = %g was not found in data file and will be skipped.', ...
            label_name, target);
    end
end

idx_use = idx_use(isfinite(idx_use));
idx_use = unique(idx_use, 'stable');

if isempty(idx_use)
    error('No requested epsilon values were found for %s figure.', label_name);
end

eps_use = eps_all(idx_use);
kins_use = kins_all(idx_use);
kins_use = reshape(kins_use, size(eps_use));

end


% =====================================================================
% 路径和数据读取辅助函数
% =====================================================================

function root_dir = local_find_project_root()
% 自动寻找项目根目录。
% 允许本文件放在 post, runs 或项目根目录下。

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


function x = local_get_grid_x(macro)
% 从 macro.grid 中读取空间网格。
% 如果没有显式保存 x，则根据 dx 和 rho 的长度重建网格。

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


function rho = local_rho_vec(snaps, idt)
% 取第 idt 个 snapshot 中的 rho，并统一成列向量。

rho = snaps(idt).rho(:);

end


% =====================================================================
% Profile 图
% =====================================================================

function local_plot_profiles(x, macro, kins, eps_list, snap_times, fig_dir, target_times, x_range)
% 生成 profile 对比图。
% 所有选定时刻叠加在同一个坐标系中。

font_size = 20;
basename = fullfile(fig_dir, 'AP_profiles');

nTimes = numel(target_times);

idx = zeros(1, nTimes);
actual_times = zeros(1, nTimes);

for q = 1:nTimes
    [~, idx(q)] = min(abs(snap_times - target_times(q)));
    actual_times(q) = snap_times(idx(q));
end

% 自动确定纵坐标范围。
xmask = (x >= x_range(1)) & (x <= x_range(2));
ymax_common = 0;

for q = 1:nTimes
    idt = idx(q);

    rho_macro = local_rho_vec(macro.snap, idt);
    ymax_common = max(ymax_common, max(rho_macro(xmask)));

    for m = 1:numel(eps_list)
        if numel(kins{m}.snap) >= idt
            rho_kin = local_rho_vec(kins{m}.snap, idt);
            ymax_common = max(ymax_common, max(rho_kin(xmask)));
        end
    end
end

if ymax_common <= 0 || ~isfinite(ymax_common)
    ymax_common = 0.10;
end

% 纵坐标上界取 0.05 的整数倍。
ymax_common = local_round_to_step(1.05 * ymax_common, 0.05, 'up');

% 纵坐标刻度尽量规整。
if ymax_common <= 0.30
    dy = 0.05;
elseif ymax_common <= 0.60
    dy = 0.10;
else
    dy = 0.20;
end
ytick_vals = 0:dy:ymax_common;

% 开始画图。
fig_handle = figure('Color', 'w', 'Position', [100 100 1200 620]);
hold on; box on;

% 同一个 epsilon 对应同一种颜色和同一种线型。
eps_colors = lines(max(numel(eps_list), 1));
eps_styles = {'-', '--', '-.', ':', '-', '--', '-.', ':'};
nStyle = numel(eps_styles);

macro_color = [0 0 0];
macro_style = '-';

legend_handles = gobjects(0);

for q = 1:nTimes
    idt = idx(q);

    % 画 kinetic 解。
    for m = 1:numel(eps_list)
        if numel(kins{m}.snap) < idt
            continue;
        end

        rho_kin = local_rho_vec(kins{m}.snap, idt);
        this_color = eps_colors(m,:);
        this_style = eps_styles{mod(m-1, nStyle) + 1};

        % 只在第一个时刻加入 legend，避免重复。
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

    % 画宏观极限解。
    rho_macro = local_rho_vec(macro.snap, idt);

    if q == 1
        h = plot(x, rho_macro, ...
            'Color', macro_color, ...
            'LineStyle', macro_style, ...
            'LineWidth', 3.0, ...
            'DisplayName', 'macro');
        legend_handles(end+1) = h; %#ok<AGROW>
    else
        plot(x, rho_macro, ...
            'Color', macro_color, ...
            'LineStyle', macro_style, ...
            'LineWidth', 3.0, ...
            'HandleVisibility', 'off');
    end

    % 添加时刻文字标注。
    local_add_time_label(x, rho_macro, actual_times(q), ymax_common, x_range, font_size);
end

% 坐标轴设置。
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

% 图例放在下方，避免遮挡曲线。
lgd = legend(legend_handles, 'Interpreter', 'latex', ...
    'Location', 'southoutside', ...
    'Orientation', 'horizontal', ...
    'NumColumns', min(numel(eps_list) + 1, 4), ...
    'Box', 'on');
lgd.FontSize = font_size - 4;

local_export_figure(fig_handle, basename);

end


function local_add_time_label(x, rho, tval, ymax_common, x_range, font_size)
% 在对应波峰附近添加时间标注。
% 标注没有边框。

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


function y = local_round_to_step(x, step, direction)
% 将数值按照给定 step 向上或向下取整。

switch lower(direction)
    case 'up'
        y = step * ceil(x / step);
    case 'down'
        y = step * floor(x / step);
    otherwise
        error('direction must be ''up'' or ''down''.');
end

end


% =====================================================================
% T=Ttarget 时的误差图
% =====================================================================

function local_plot_error_at_time(x, dx, macro, kins, eps_list, snap_times, fig_dir, Ttarget)
% 在指定时刻 Ttarget 计算 kinetic 解到 macro 解的 L2 误差。
% 画 log-log 图，并添加 O(epsilon) 和 O(epsilon^2) 参考线。

font_size = 16;

[~, kT] = min(abs(snap_times - Ttarget));
Tuse = snap_times(kT);

nEps = numel(eps_list);
err_T = nan(1, nEps);

rho_macro = local_rho_vec(macro.snap, kT);

for m = 1:nEps
    if numel(kins{m}.snap) < kT
        continue;
    end

    rho_kin = local_rho_vec(kins{m}.snap, kT);
    err_T(m) = sqrt(dx * sum((rho_kin - rho_macro).^2));
end

eps_col = eps_list(:);
E_col   = err_T(:);

valid = isfinite(eps_col) & eps_col > 0 & isfinite(E_col) & E_col > 0;
eps_col = eps_col(valid);
E_col   = E_col(valid);

[eps_col, id] = sort(eps_col);
E_col = E_col(id);

if numel(eps_col) < 2
    warning('Not enough valid data points to plot the error at T=%g.', Tuse);
    return;
end

% ------------------------------------------------------------
% 构造一阶和二阶参考线
% ------------------------------------------------------------
% 两条参考线都锚定在最大 epsilon 的误差点。
% 这样可以直观看出数值误差位于一阶和二阶之间。
eps_ref = eps_col(end);
E_ref   = E_col(end);

ref_order1 = E_ref * (eps_col / eps_ref);
ref_order2 = E_ref * (eps_col / eps_ref).^2;

% ------------------------------------------------------------
% 作图
% ------------------------------------------------------------
fig_handle = figure('Color', 'w', 'Position', [100 100 560 430]);
hold on; box on;

loglog(eps_col, E_col, 'o-', ...
    'LineWidth', 1.9, ...
    'MarkerSize', 7, ...
    'MarkerFaceColor', 'w', ...
    'DisplayName', 'numerical error');

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

% 在 log 坐标下给左右两端留一点边距，避免数据点贴边。
x_left  = 10^(log10(min(eps_col)) - 0.08);
x_right = 10^(log10(max(eps_col)) + 0.08);
xlim([x_left, x_right]);

legend('Interpreter', 'latex', ...
    'Location', 'northwest', ...
    'Box', 'on');

grid on;

basename = fullfile(fig_dir, sprintf('AP_error_T%g', Tuse));
local_export_figure(fig_handle, basename);

end


% =====================================================================
% 波速比较图
% =====================================================================

function local_plot_speed_comparison(x, dx, macro, kins, eps_list, snap_times, fig_dir, time_range, sigma_pred)
% 画 travelling speed 随时间变化的比较图。
%
% 说明：
%   这里的速度由密度质心 X_rho(t) 的有限差分得到。
%   该图用于展示 kinetic 波速与 macro 波速的接近程度。
%   由于速度估计对尾部和差分较敏感，不建议用该图强调收敛阶。

font_size = 16;

% ------------------------------------------------------------
% 计算 macro 波速
% ------------------------------------------------------------
xmass_macro = local_compute_center_of_mass_history(x, dx, macro.snap);
speed_macro = local_finite_diff_speed(snap_times(:), xmass_macro(:));

% ------------------------------------------------------------
% 作图
% ------------------------------------------------------------
fig_handle = figure('Color', 'w', 'Position', [100 100 680 460]);
hold on; box on;

% macro 数值波速
plot(snap_times, speed_macro, 'k-', ...
    'LineWidth', 2.4, ...
    'DisplayName', 'macro');

% 解析预测波速水平虚线
if ~isempty(time_range)
    x_pred_full = time_range;
else
    x_pred_full = [min(snap_times), max(snap_times)];
end

% 不让虚线从最左端开始，在横坐标范围内留一点距离
x_margin = 0.08 * (x_pred_full(2) - x_pred_full(1));
x_pred = [x_pred_full(1) + x_margin, x_pred_full(2)];

plot(x_pred, [sigma_pred, sigma_pred], 'k--', ...
    'LineWidth', 1.6, ...
    'DisplayName', sprintf('$\\sigma_{\\mathrm{pred}}=%.3f$', sigma_pred));

% 不同 epsilon 使用不同颜色和线型。
eps_colors = lines(max(numel(eps_list), 1));
eps_styles = {'-', '--', '-.', ':', '-', '--', '-.', ':'};
nStyle = numel(eps_styles);

for m = 1:numel(eps_list)

    this_times = local_get_snap_times(kins{m}.snap, snap_times.');
    this_times = this_times(:);

    xmass_kin = local_compute_center_of_mass_history(x, dx, kins{m}.snap);
    speed_kin = local_finite_diff_speed(this_times(:), xmass_kin(:));

    this_color = eps_colors(m,:);
    this_style = eps_styles{mod(m-1, nStyle) + 1};

    plot(this_times, speed_kin, ...
        'Color', this_color, ...
        'LineStyle', this_style, ...
        'LineWidth', 1.8, ...
        'DisplayName', sprintf('$\\varepsilon=%g$', eps_list(m)));
end

% ------------------------------------------------------------
% 坐标轴设置
% ------------------------------------------------------------
if ~isempty(time_range)
    xlim(time_range);
end

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

basename = fullfile(fig_dir, 'AP_speed_comparison');
local_export_figure(fig_handle, basename);

end


% =====================================================================
% 波速数据计算与保存
% =====================================================================

function speed_data = local_compute_and_save_speed_data(x, dx, macro, kins, eps_list, snap_times, data_dir, selected_times)
% 计算不同 epsilon 和不同时刻的 travelling speed，但不额外画误差图。
%
% 输出文件：
%   data/AP_profiles/AP_speed_data.mat
%   data/AP_profiles/AP_speed_by_time.csv
%   data/AP_profiles/AP_speed_error_by_time.csv
%   data/AP_profiles/AP_speed_selected_times.csv

if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

snap_times = snap_times(:);
nT = numel(snap_times);
nEps = numel(eps_list);

% ------------------------------------------------------------
% 宏观解质心和波速
% ------------------------------------------------------------
xmass_macro = local_compute_center_of_mass_history(x, dx, macro.snap);
speed_macro = local_finite_diff_speed(snap_times, xmass_macro(:));

% ------------------------------------------------------------
% kinetic 解质心和波速
% ------------------------------------------------------------
xmass_kinetic = nan(nT, nEps);
speed_kinetic = nan(nT, nEps);

for m = 1:nEps
    this_times = local_get_snap_times(kins{m}.snap, snap_times.');
    this_times = this_times(:);

    xmass_tmp = local_compute_center_of_mass_history(x, dx, kins{m}.snap);
    xmass_tmp = xmass_tmp(:);

    speed_tmp = local_finite_diff_speed(this_times, xmass_tmp);

    % 通常 this_times 与 snap_times 完全一致。
    % 这里做一下兼容处理。
    if numel(this_times) == nT && max(abs(this_times - snap_times)) < 1e-12
        xmass_kinetic(:,m) = xmass_tmp;
        speed_kinetic(:,m) = speed_tmp;
    else
        xmass_kinetic(:,m) = interp1(this_times, xmass_tmp, snap_times, 'linear', NaN);
        speed_kinetic(:,m) = interp1(this_times, speed_tmp, snap_times, 'linear', NaN);
    end
end

speed_error = abs(speed_kinetic - speed_macro(:));

% ------------------------------------------------------------
% 保存为结构体
% ------------------------------------------------------------
speed_data = struct();
speed_data.t = snap_times;
speed_data.eps_list = eps_list(:);
speed_data.xmass_macro = xmass_macro(:);
speed_data.speed_macro = speed_macro(:);
speed_data.xmass_kinetic = xmass_kinetic;
speed_data.speed_kinetic = speed_kinetic;
speed_data.speed_error = speed_error;

% 选定时刻的数据，便于后续写表格或检查。
selected_idx = zeros(numel(selected_times), 1);
selected_times_used = zeros(numel(selected_times), 1);

for k = 1:numel(selected_times)
    [~, id] = min(abs(snap_times - selected_times(k)));
    selected_idx(k) = id;
    selected_times_used(k) = snap_times(id);
end

speed_data.selected_times = selected_times_used;
speed_data.selected_idx = selected_idx;
speed_data.speed_macro_selected = speed_macro(selected_idx);
speed_data.speed_kinetic_selected = speed_kinetic(selected_idx,:);
speed_data.speed_error_selected = speed_error(selected_idx,:);

save(fullfile(data_dir, 'AP_speed_data.mat'), 'speed_data');

% ------------------------------------------------------------
% 保存全部时刻的 speed table
% ------------------------------------------------------------
Tspeed = table(snap_times, speed_macro(:), ...
    'VariableNames', {'time', 'speed_macro'});

for m = 1:nEps
    vname = local_eps_varname('speed_eps', eps_list(m));
    Tspeed.(vname) = speed_kinetic(:,m);
end

writetable(Tspeed, fullfile(data_dir, 'AP_speed_by_time.csv'));

% ------------------------------------------------------------
% 保存全部时刻的 speed error table
% ------------------------------------------------------------
Terr = table(snap_times, ...
    'VariableNames', {'time'});

for m = 1:nEps
    vname = local_eps_varname('speed_error_eps', eps_list(m));
    Terr.(vname) = speed_error(:,m);
end

writetable(Terr, fullfile(data_dir, 'AP_speed_error_by_time.csv'));

% ------------------------------------------------------------
% 保存 selected times 的 speed table
% ------------------------------------------------------------
Tsel = table(selected_times_used, speed_macro(selected_idx), ...
    'VariableNames', {'time', 'speed_macro'});

for m = 1:nEps
    vname1 = local_eps_varname('speed_eps', eps_list(m));
    vname2 = local_eps_varname('speed_error_eps', eps_list(m));

    Tsel.(vname1) = speed_kinetic(selected_idx,m);
    Tsel.(vname2) = speed_error(selected_idx,m);
end

writetable(Tsel, fullfile(data_dir, 'AP_speed_selected_times.csv'));

fprintf('Saved speed data: %s\n', fullfile(data_dir, 'AP_speed_data.mat'));
fprintf('Saved speed tables in: %s\n', data_dir);

end


function name = local_eps_varname(prefix, epsval)
% 根据 epsilon 生成合法的 MATLAB table 变量名。

s = sprintf('%.0e', epsval);
s = strrep(s, '-', 'm');
s = strrep(s, '+', '');
s = strrep(s, '.', 'p');

name = matlab.lang.makeValidName([prefix, '_', s]);

end


% =====================================================================
% 质心与波速辅助函数
% =====================================================================

function xmass = local_compute_center_of_mass_history(x, dx, snaps)
% 计算每个 snapshot 中密度的质心位置。

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
% 用差分计算瞬时波速。

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
% 图像输出
% =====================================================================

function local_export_figure(fig_handle, basename)
% 同时保存 PDF, PNG, MATLAB FIG 和 EPS 文件。
% FIG 文件方便后续在 MATLAB 中手动调整。
% EPS 文件方便直接用于 LaTeX。

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