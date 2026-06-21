function [myfunc, mypara] = prepare_v_vectors(domain, mypara, myfunc)
% Prepare Nv×1 vectors and moments used in OneStep
v  = domain.v(:);
dv = domain.dv;

% build raw vectors
psi_v  = myfunc.psi(v);
phi_c  = myfunc.phi_c(v);
phi_n  = myfunc.phi_n(v);

% normalize psi: ∫ psi dv = 1
I0 = trapz(v, psi_v);
psi_v = psi_v / I0;

myfunc.Psi_vec   = psi_v;    % Nv×1
myfunc.Phi_c_vec = phi_c;    % Nv×1
myfunc.Phi_n_vec = phi_n;    % Nv×1

% precompute moments (avoid integration_v_meshgrid inside time loop)
mypara.D     = trapz(v, (v.^2).*psi_v);
mypara.chi_c = trapz(v, v.*phi_c);
mypara.chi_n = trapz(v, v.*phi_n);

end