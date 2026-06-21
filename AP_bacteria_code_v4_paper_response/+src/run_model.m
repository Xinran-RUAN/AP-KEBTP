function out = run_model(p, kind)
%RUN_MODEL Run either 'kinetic' AP scheme or 'macro' limiting scheme.
%
% Optional snapshot fields in p:
%   p.output_times             physical times stored in out.snap
%   p.save_snapshots_to_disk   true/false, also write each output time to .mat
%   p.snapshot_dir             directory for per-time snapshot files
%   p.snapshot_tag             extra filename tag, useful in parameter scans
%   p.save_g_snapshots         true/false, save kinetic g in disk snapshots
if nargin < 2, kind = 'kinetic'; end

% Set the epsilon multiplying q_t in phi(eps_response*q_t+v*q_x).
% The limiting macroscopic equation uses eps_response=0; kinetic AP runs
% use the finite kinetic epsilon.  A user-specified nonempty p.response_eps
% is respected.
if ~isfield(p, 'response_eps') || isempty(p.response_eps)
    if strcmpi(kind, 'macro')
        p.response_eps = 0;
    else
        p.response_eps = p.eps;
    end
end

grid = model.make_grid(p);
U = model.initial_data(grid, p);
if strcmpi(kind,'macro')
    U.g = [];
end

nt = ceil(p.Tfinal/p.dt);
out_times = p.output_times(:).';
out_times = unique(out_times(out_times <= p.Tfinal + 1e-12));
snap = struct('t',{},'rho',{},'S',{},'N',{},'mass',{},'minrho',{},'maxrho',{});
cm_t = []; cm_x = [];
next_out = 1;

% Diagnostic output interval. Default is one time unit.
if isfield(p, 'report_dt') && ~isempty(p.report_dt)
    report_dt = p.report_dt;
else
    report_dt = 1;
end
next_report = report_dt;

% Optional disk output for snapshots.
save_snapshots_to_disk = isfield(p, 'save_snapshots_to_disk') && p.save_snapshots_to_disk;
if save_snapshots_to_disk
    if ~isfield(p, 'snapshot_dir') || isempty(p.snapshot_dir)
        p.snapshot_dir = fullfile(utils.project_root(), 'data', 'snapshots');
    else
        p.snapshot_dir = utils.resolve_project_path(p.snapshot_dir);
    end
    utils.make_dir(p.snapshot_dir);
end

% Allow t=0 snapshots.
while next_out <= numel(out_times) && abs(out_times(next_out)) <= 1e-12
    snap = local_append_snapshot(snap, U, grid);
    if save_snapshots_to_disk
        local_save_snapshot(U, grid, p, kind);
    end
    next_out = next_out + 1;
end

for n = 1:nt
    if strcmpi(kind,'macro')
        U = src.step_macro(U, grid, p);
    else
        U = src.step_kinetic_AP(U, grid, p);
    end

    while next_out <= numel(out_times) && U.t >= out_times(next_out) - 0.5*p.dt
        snap = local_append_snapshot(snap, U, grid);
        if save_snapshots_to_disk
            local_save_snapshot(U, grid, p, kind);
        end
        next_out = next_out + 1;
    end

    while U.t >= next_report - 0.5*p.dt || n == nt
        cm_t(end+1) = U.t; %#ok<AGROW>
        cm_x(end+1) = sum(grid.x.*U.rho)/max(sum(U.rho),eps); %#ok<AGROW>
        if p.verbose
            if strcmpi(kind, 'macro')
                fprintf('macro t=%.2f mass=%.6e minrho=%.2e\n', ...
                    U.t, sum(U.rho)*grid.dx, min(U.rho));
            else
                fprintf('kinetic eps=%g t=%.2f mass=%.6e minrho=%.2e\n', ...
                    p.eps, U.t, sum(U.rho)*grid.dx, min(U.rho));
            end
        end
        next_report = next_report + report_dt;
        if n == nt
            break;
        end
    end
end

out = struct('grid',grid,'U',U,'snap',snap,'cm_t',cm_t,'cm_x',cm_x, ...
             'speed',src.estimate_speed(cm_t,cm_x),'params',p,'kind',kind);
end

function snap = local_append_snapshot(snap, U, grid)
% Append the fields most frequently needed for plotting and error checks.
snap(end+1).t = U.t; %#ok<AGROW>
snap(end).rho = U.rho;
snap(end).S = U.S;
snap(end).N = U.N;
snap(end).mass = grid.dx * sum(U.rho);
snap(end).minrho = min(U.rho);
snap(end).maxrho = max(U.rho);
end

function local_save_snapshot(U, grid, p, kind)
% Save one physical-time snapshot to disk.  This is useful for long runs,
% because data are available even if a later parameter case fails.
t = U.t;
x = grid.x;
rho = U.rho;
S = U.S;
N = U.N;
params = p;
model_kind = kind;
mass = grid.dx * sum(rho);
minrho = min(rho);
maxrho = max(rho);

save_g = isfield(p, 'save_g_snapshots') && p.save_g_snapshots;
if save_g
    g = U.g; %#ok<NASGU>
end

if strcmpi(kind, 'macro')
    eps_value = NaN;
    prefix = 'macro';
else
    eps_value = p.eps;
    prefix = ['kinetic_eps_' utils.num_to_tag(p.eps)];
end

if isfield(p, 'snapshot_tag') && ~isempty(p.snapshot_tag)
    tag = p.snapshot_tag;
    if isstring(tag), tag = char(tag); end
    tag = regexprep(tag, '[^A-Za-z0-9_\-]', '_');
    prefix = [prefix '_' tag];
end

time_tag = sprintf('t_%07.3f', t);
time_tag = strrep(time_tag, '.', 'p');
filename = fullfile(p.snapshot_dir, [prefix '_' time_tag '.mat']);

if save_g
    save(filename, 't', 'x', 'rho', 'S', 'N', 'g', 'grid', ...
        'params', 'model_kind', 'eps_value', 'mass', 'minrho', 'maxrho');
else
    save(filename, 't', 'x', 'rho', 'S', 'N', 'grid', ...
        'params', 'model_kind', 'eps_value', 'mass', 'minrho', 'maxrho');
end
end
