function plot_macro_compare_time(tTarget)
%PLOT_MACRO_COMPARE_TIME
% Compare the numerical macro profile at a given time with the predicted
% travelling-wave profile.
%
% Usage:
%   plot_macro_compare_time(50) （ xlim([28, 47]);ylim([0, 0.115]) ）

%   plot_macro_compare_time(30) （ xlim([14, 33]);ylim([0, 0.115]) ）
%
% Data file name convention:
%   macro_t_050p000.mat
%   macro_t_030p000.mat
%
% The code first searches in:
%   data/macro_travelling_wave/snapshots/
% then in:
%   data/macro_travelling_wave/
%
% Output figures:
%   post/figures/macro_compare_t_050p000.png
%   post/figures/macro_compare_t_050p000.eps
%   post/figures/macro_compare_t_050p000.fig

    if nargin < 1
        tTarget = 50;
    end

    close all; clc;

    %% ============================================================
    %  Locate project root
    % =============================================================

    this_file = mfilename('fullpath');

    if isempty(this_file)
        root_dir = pwd;
    else
        this_dir = fileparts(this_file);

        if exist(fullfile(this_dir, 'data'), 'dir')
            root_dir = this_dir;
        elseif exist(fullfile(fileparts(this_dir), 'data'), 'dir')
            root_dir = fileparts(this_dir);
        else
            root_dir = pwd;
        end
    end

    data_dir_1 = fullfile(root_dir, 'data', 'macro_travelling_wave', 'snapshots');
    data_dir_2 = fullfile(root_dir, 'data', 'macro_travelling_wave');

    fig_dir = fullfile(root_dir, 'post', 'figures');

    if ~exist(fig_dir, 'dir')
        mkdir(fig_dir);
    end

    %% ============================================================
    %  Build data filename
    % =============================================================

    time_tag = make_time_tag(tTarget);
    file_name = ['macro_t_', time_tag, '.mat'];

    data_file_1 = fullfile(data_dir_1, file_name);
    data_file_2 = fullfile(data_dir_2, file_name);

    if exist(data_file_1, 'file')
        data_file = data_file_1;
    elseif exist(data_file_2, 'file')
        data_file = data_file_2;
    else
        error(['Cannot find data file for t = %.6f.\n', ...
               'Tried:\n  %s\n  %s'], ...
               tTarget, data_file_1, data_file_2);
    end

    %% ============================================================
    %  Load data
    % =============================================================

    data = load(data_file);

    x   = extract_x(data);
    rho = extract_rho(data);

    x   = x(:);
    rho = rho(:);

    if numel(x) ~= numel(rho)
        error('The lengths of x and rho are not consistent.');
    end

    if isfield(data, 'params')
        p = data.params;
    elseif isfield(data, 'p')
        p = data.p;
    else
        p = struct();
    end

    %% ============================================================
    %  Parameters
    % =============================================================

    chiS  = get_param_any(p, {'chiS', 'chi_S'}, 0.5);
    chiN  = get_param_any(p, {'chiN', 'chi_N'}, 1.1);
    DS    = get_param_any(p, {'DS', 'D_S', 'DeS'}, 2.0);
    alpha = get_param_any(p, {'alpha', 'alphaS', 'alpha_S'}, 0.05);

    % Diffusion coefficient of rho.
    % For V = [-1,1], D_rho = int v^2 dv / |V| = 1/3.
    D_rho = get_param_any(p, {'D_rho', 'Drho', 'D_rho_h', 'Drho_h'}, 1/3);

    dx = mean(diff(x));

    %% ============================================================
    %  Predicted wave speed
    % =============================================================

    sigma = solve_sigma(chiS, chiN, DS, alpha);

    %% ============================================================
    %  Predicted travelling-wave profile
    % =============================================================

    [~, idx_peak] = max(rho);
    x_peak = x(idx_peak);

    lambda_left  = (-sigma + chiS + chiN) / D_rho;
    lambda_right = (-sigma - chiS + chiN) / D_rho;

    rho_unit = zeros(size(rho));

    idx_left  = x <= x_peak;
    idx_right = x >= x_peak;

    rho_unit(idx_left)  = exp(lambda_left  * (x(idx_left)  - x_peak));
    rho_unit(idx_right) = exp(lambda_right * (x(idx_right) - x_peak));

    mass_num  = sum(rho) * dx;
    mass_unit = sum(rho_unit) * dx;

    rho_peak_pred = mass_num / mass_unit;
    rho_pred = rho_peak_pred * rho_unit;

    %% ============================================================
    %  Plot
    % =============================================================

    fig = figure('Color', 'w');
    set(fig, 'Position', [100, 100, 760, 560]);

    plot(x, rho, 'b-', 'LineWidth', 2.2);
    hold on;

    plot(x, rho_pred, '--', ...
        'LineWidth', 2.2, ...
        'Color', [0.8500 0.3250 0.0980]);

    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 20);
    ylabel('$\rho$', 'Interpreter', 'latex', 'FontSize', 20);

    legend({'Numerical', 'Analytical'}, ...
        'Interpreter', 'latex', ...
        'FontSize', 20, ...
        'Location', 'northeast');

    box on;
    set(gca, ...
        'FontSize', 20, ...
        'LineWidth', 1.2, ...
        'TickLabelInterpreter', 'latex');

    % Automatically show the pulse region.
    x_left_margin  = 10;
    x_right_margin = 15;

    x_min_plot = max(min(x), x_peak - x_left_margin);
    x_max_plot = min(max(x), x_peak + x_right_margin);
    xlim([x_min_plot, x_max_plot]);

    ymax = 1.15 * max([rho; rho_pred]);
    ylim([0, ymax]);

    % title(sprintf('Comparison of numerical and predicted profiles at $t=%.0f$', tTarget), ...
    %     'Interpreter', 'latex', ...
    %     'FontSize', 17);

    %% ============================================================
    %  Save figures
    % =============================================================

    out_png = fullfile(fig_dir, ['macro_compare_t_', time_tag, '.png']);
    out_eps = fullfile(fig_dir, ['macro_compare_t_', time_tag, '.eps']);
    out_fig = fullfile(fig_dir, ['macro_compare_t_', time_tag, '.fig']);

    savefig(fig, out_fig);
    print(fig, out_png, '-dpng', '-r300');
    print(fig, out_eps, '-depsc', '-r300');

    fprintf('\nFigures saved to:\n');
    fprintf('  %s\n', out_png);
    fprintf('  %s\n', out_eps);
    fprintf('  %s\n', out_fig);

    %% ============================================================
    %  Diagnostics
    % =============================================================

    fprintf('\n===== Diagnostic information =====\n');
    fprintf('Data file       = %s\n', data_file);
    fprintf('target time     = %.8f\n', tTarget);
    fprintf('chiS            = %.8f\n', chiS);
    fprintf('chiN            = %.8f\n', chiN);
    fprintf('DS              = %.8f\n', DS);
    fprintf('alpha           = %.8f\n', alpha);
    fprintf('D_rho           = %.8f\n', D_rho);
    fprintf('dx              = %.8f\n', dx);
    fprintf('sigma predicted = %.8f\n', sigma);
    fprintf('x_peak          = %.8f\n', x_peak);
    fprintf('rho_peak_pred   = %.8e\n', rho_peak_pred);
    fprintf('mass numerical  = %.12e\n', mass_num);
    fprintf('mass predicted  = %.12e\n', sum(rho_pred) * dx);
    fprintf('lambda_left     = %.8f\n', lambda_left);
    fprintf('lambda_right    = %.8f\n', lambda_right);
end


%% ================================================================
function tag = make_time_tag(t)
%MAKE_TIME_TAG
% Convert time value to file tag.
%
% Examples:
%   t = 50    -> 050p000
%   t = 20    -> 020p000
%   t = 1     -> 001p000
%   t = 0.5   -> 000p500

    tag = sprintf('%07.3f', t);
    tag = strrep(tag, '.', 'p');
end


%% ================================================================
function x = extract_x(data)
%EXTRACT_X
% Extract spatial grid from loaded mat data.

    if isfield(data, 'x')
        x = data.x;
    elseif isfield(data, 'xc')
        x = data.xc;
    elseif isfield(data, 'xx')
        x = data.xx;
    elseif isfield(data, 'grid') && isstruct(data.grid) && isfield(data.grid, 'x')
        x = data.grid.x;
    elseif isfield(data, 'grid') && isstruct(data.grid) && isfield(data.grid, 'xc')
        x = data.grid.xc;
    else
        error('Cannot find spatial grid variable x in the data file.');
    end
end


%% ================================================================
function rho = extract_rho(data)
%EXTRACT_RHO
% Extract density from loaded mat data.

    if isfield(data, 'rho')
        rho = data.rho;
    elseif isfield(data, 'sol_rho')
        rho = data.sol_rho;
    elseif isfield(data, 'rho_num')
        rho = data.rho_num;
    elseif isfield(data, 'density')
        rho = data.density;
    else
        error('Cannot find density variable rho in the data file.');
    end
end


%% ================================================================
function val = get_param_any(p, names, default_val)
%GET_PARAM_ANY
% Read parameter from struct p using several possible names.

    val = default_val;

    if ~isstruct(p)
        return;
    end

    for k = 1:numel(names)
        name = names{k};
        if isfield(p, name)
            val = p.(name);
            return;
        end
    end
end


%% ================================================================
function sigma = solve_sigma(chiS, chiN, DS, alpha)
%SOLVE_SIGMA
% Solve the predicted travelling-wave speed.
%
% Equation:
%   chiN - sigma = chiS * sigma / sqrt(4*DS*alpha + sigma^2)

    F = @(s) chiN - s - chiS .* s ./ sqrt(4 * DS * alpha + s.^2);

    a = 0;
    b = chiN;

    Fa = F(a);
    Fb = F(b);

    if Fa * Fb < 0
        sigma = fzero(F, [a, b]);
        return;
    end

    b = max(2 * chiN, 2);
    Fb = F(b);

    if Fa * Fb < 0
        sigma = fzero(F, [a, b]);
    else
        sigma = fzero(F, 0.7);
    end
end