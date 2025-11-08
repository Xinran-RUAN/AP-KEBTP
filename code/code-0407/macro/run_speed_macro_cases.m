% run macro tests
clc; clear;
chi_N_list = 0:0.1:2;
chi_S_list = 0:0.1:2;
% chi_N_list = 0:0.05:2;
% chi_S_list = 0:0.05:2;
Nn = length(chi_N_list);
Ns = length(chi_S_list);
speed_numeric = zeros(Nn, Ns);

%%
for jj = 1:Nn
    for kk = 1:Ns
        mypara.chi_c = chi_S_list(kk); 
        mypara.chi_n = chi_N_list(jj); 
        %=======================================
        % % 计算新数据
        % main_macro; 
        % % 加载旧数据
        data_file = strcat('data_macro/data_chiN_', num2str(mypara.chi_n), '_chiS_', num2str(mypara.chi_c),'.mat');
        load(data_file, 'speed_numer_case');
        %=======================================
        speed_numeric(jj, kk) = speed_numer_case;
    end
end
%% plot
pcolor(chi_N_list, chi_S_list, speed_numeric');
shading interp;      % 插值使图像更平滑
colormap(jet);      % 更换颜色方案
colorbar;            % 加颜色条
xlabel('$\chi_N$', 'Interpreter', 'latex', 'FontSize', 20); 
ylabel('$\chi_S$', 'Interpreter', 'latex', 'FontSize', 20); 
title('Wave speed $\sigma$ from the macro model', 'Interpreter', 'latex', 'FontSize', 20);
set(gca, 'FontSize', 20);
% domain_bound = 5;
% xlim([-domain_bound, domain_bound]);
% ylim([-domain_bound, domain_bound]);
clim([0, 2]) 
