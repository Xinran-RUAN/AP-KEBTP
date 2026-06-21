function p = default_params()
%DEFAULT_PARAMS Baseline parameters for the AP bacteria travelling-pulse tests.
%
% The defaults below are chosen to match the macroscopic travelling-pulse
% tests in the manuscript: V=[-1,1], D_rho=<v^2>/<1>, chiS=0.5,
% chiN=1.1, DS=2, alpha=0.05.  The response is the normalized sign
% response, so that in the macro limit
%
%      uS = chiS*sign(S_x),     uN = chiN*sign(N_x).
%
% This normalization is important for comparing with the analytical formula
% used in the paper.

p = struct();

% domain and time
p.L = 150;
p.dx = 0.1;
p.dt = 1e-2;
p.Tfinal = 50;
p.output_times = [1 10 20 50];

% velocity grid
p.vmin = -1;
p.vmax = 1;
p.dv = 0.02;
p.velocity_mode = 'continuous';

% model parameters in the normalized micro-macro formulation mu*|V|=1
p.eps = 1e-2;
p.chiS = 0.5;
p.chiN = 1.1;
p.DS = 2;
p.DN = 0;
p.alpha = 0.05;
p.beta = 1;
p.gamma = 1;

% response function phi(y)
% Use the discontinuous response used by the analytical travelling pulse.
% If a smooth run is desired, change this to 'tanh'.
p.phi_type = 'sign';     % 'sign', 'tanh', 'linear'
p.phi_delta = 1e-2;      % used only by 'tanh'

% Scale phi so that for phi(y)=-sign(y) and V=[-1,1], the effective drift
% is exactly chi*sign(q_x), not chi/2*sign(q_x).  For the continuous
% velocity grid this multiplies phi by |V|/int_V |v|dv = 2.
p.phi_scale = 1;
p.normalize_phi_amplitude = true;

% Response time-scale coefficient in phi(eps_response*q_t + v*q_x).
% Leave empty: src.run_model sets it to 0 for the macro limit and to p.eps
% for kinetic AP runs.  This is what is needed for the epsilon->0 macro
% profile and for the finite-epsilon kinetic tests.
p.response_eps = [];

% initial data.  rho0_lambda=3 gives total mass about 1/3 on [0,150],
% matching the vertical scale of the manuscript figures.  If you want the
% older mass-one tests, set p.rho0_lambda = 1.
p.rho0_amp = 1;
p.rho0_lambda = 3;
p.S0 = 0;
p.N0 = 1e3;

% numerics
p.use_limiter = true;
p.macro_limiter = false;
p.update_chem_with_new_rho = true;
p.verbose = true;
p.report_dt = 1;

% Snapshot output is disabled by default; run scripts turn it on where needed.
p.save_snapshots_to_disk = false;
p.snapshot_dir = '';
p.snapshot_tag = '';
p.save_g_snapshots = false;
end
