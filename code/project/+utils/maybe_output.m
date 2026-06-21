function diag_data = maybe_output(io_cfg, state, dom, para, func, diag_data)
% src/+io/maybe_output.m
% 按“时间表”输出：t 命中 diag_data.t_list 时触发一次
t = state.t;

k = diag_data.mass_index;
if k > numel(diag_data.t_list)
    return;
end

t_next = diag_data.t_list(k);
if abs(t - t_next) <= io_cfg.dt/2
    % --- diag ---
    diag_data.x_mass(k) = analysis.mass_center(dom.x, state.rho);
    diag_data.mass_index = k + 1;

    % --- print ---
    if io_cfg.print
        fprintf("chi_C=%.2f, chi_N=%.2f, t=%.2f, x_mass=%.6g\n", ...
            para.chi_c, para.chi_n, t, diag_data.x_mass(k));
    end

    % --- plot ---
    if io_cfg.do_plot
        utils.plot_data(state, dom);
        drawnow;
    end

    % --- save snapshot (optional) ---
    if io_cfg.do_save
        fn = fullfile(io_cfg.out.dir, sprintf('snap_t_%06.1f.mat', t_next));
        save(fn, 'state', 'dom', 'para', 'func');
    end
end

end