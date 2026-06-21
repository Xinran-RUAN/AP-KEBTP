% run kinetic tests
clc; clear;
mypara.eps = 1e-2; 
chi_N_list = 0:0.1:2;
chi_S_list = 0:0.1:2;
% chi_N_list = 1.1;
% chi_S_list = 0.5;
Nn = length(chi_N_list);
Ns = length(chi_S_list);
speed_numeric_kinetic = zeros(Nn, Ns);

%%
for jj = 1:Nn
    for kk = 1:Ns
        mypara.chi_c = chi_S_list(kk); 
        mypara.chi_n = chi_N_list(jj); 
        % % =========================================
        % % 计算新数据
        % main_kinetic_model;
        % % 加载旧数据(没存，无法运行）
        % data_file = strcat('data_kinetic/data_kinetic_ChiC_', num2str(mypara.chi_c), ...
        %     '_ChiN_', num2str(mypara.chi_n), ...
        %     '_eps_1e-02_T_60_dt_1e-02.mat');
        % load(data_file, 'speed_numeric_kinetic');
        % % =========================================
        % speed_numeric_kinetic(jj, kk) = speed_numeric_kinetic;
    end
end

%================================
% % 加载旧数据
load('data_kinetic_speed.mat');
%================================

%% 画图
pcolor(chi_N_list, chi_S_list, speed_numeric_kinetic');
shading interp;
colormap(jet);
colorbar;
xlabel('$\chi_N$', 'Interpreter', 'latex', 'FontSize', 20);
ylabel('$\chi_S$', 'Interpreter', 'latex', 'FontSize', 20);
title('Wave speed $\sigma$ from the kinetic model ($\varepsilon = 0.01$)', 'Interpreter', 'latex', 'FontSize', 20);
set(gca, 'FontSize', 20);
clim([0,2]);
