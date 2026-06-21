function para = default_params()
% src/+cfg/default_params.m
para = struct();
para.chi_c = 1/2;
para.chi_n = 1.1;
para.eps   = 1e-2;

% c(M)
para.DM = 2;
para.alpha = 0.05;
para.beta = 1;

% n(N)
para.DN = 0;
para.gamma = 1;
end
