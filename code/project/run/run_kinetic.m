% run/main_kinetic.m
clc; clear;

% add src to path
this = fileparts(mfilename('fullpath'));   % .../project_root/runs
root = fileparts(this);                    % .../project_root
addpath(root);  

% ---- 参数设定 ----
para = model.default_params();
dom  = model.default_domain();
func = model.default_functions(para);

% ---- validate / derived quantities ----
[para, func] = src.validate_all(para, dom, func);

% ---- init ----
state = model.init_kinetic(dom, para, func);

% ---- io cfg ----
io_cfg = struct();
io_cfg.dt        = 1e-2;
io_cfg.Tn        = 100;
io_cfg.NT        = round(io_cfg.Tn / io_cfg.dt);
io_cfg.output_dt = 1.0;                 % 每 1.0 时间输出一次（对应你原来的 T_plot=1:Tn）
io_cfg.print     = true;
io_cfg.do_plot   = true;
io_cfg.do_save   = true;

io_cfg.out = utils.setup_output('kinetic');  % 自动创建输出文件夹

% ---- diag buffers ----
diag_data = struct();
diag_data.t_list      = (0:io_cfg.output_dt:io_cfg.Tn);
diag_data.x_mass      = nan(size(diag_data.t_list));
diag_data.mass_index  = 1;

% ---- initial output ----
diag_data = utils.maybe_output(io_cfg, state, dom, para, func, diag_data);

% ---- time loop ----
dt = io_cfg.dt;
[func, para] = src.prepare_v_vectors(dom, para, func);
for n = 1:io_cfg.NT
    state = src.onestep_kinetic_IMEX(state, dom, dt, para, func);
    state.t = state.t + dt;

    diag_data = utils.maybe_output(io_cfg, state, dom, para, func, diag_data);
end

% ---- final save ----
utils.save_final(io_cfg, state, dom, para, func, diag_data);

% ---- estimate speed ----
speed = analysis.estimate_speed(diag_data.t_list, diag_data.x_mass, struct('tailN', 6));
fprintf("chi_C=%.2f, chi_N=%.2f, speed=%.4f\n", para.chi_c, para.chi_n, speed);