function save_final(io_cfg, state, dom, para, func, diag_data)
% src/+io/save_final.m
fn = fullfile(io_cfg.out.dir, 'final.mat');
save(fn, 'state', 'dom', 'para', 'func', 'diag_data', 'io_cfg');
fprintf('[save] final saved to %s\n', fn);
end