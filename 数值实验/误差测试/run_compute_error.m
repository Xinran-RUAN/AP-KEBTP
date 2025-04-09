%% 记录误差
error_table = zeros(length(T_list), length(eps_list));

for i = 1:length(eps_list)
    for j = 1:length(T_list)
        load(sprintf('rho_eps_%.0e_T_%.0f.mat', eps_list(i), T_list(j)), 'rho'); % kinetic rho
        rho_kinetic = rho;
        load(sprintf('rho_macro_T_%.0f.mat', T_list(j)), 'rho'); % macro rho
        rho_macro = rho;
        error_table(j, i) = sqrt(sum((rho_macro - rho_kinetic).^2) * domain.dx);
    end
end

writematrix(error_table, 'error_table.csv');
