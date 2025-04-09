% 设置文件信息
Ts = [1, 10, 20, 50];
% epsilons = [1, 1e-1, 1e-2, 1e-3];
epsilons = [1e-1, 5e-2, 1e-2];
N_eps = length(epsilons);
colors = lines(N_eps+1); % 自动分配颜色

for i = 1:length(Ts)
    T = Ts(i);
    figure; hold on;
    % 加载宏观模型数据
    filename = sprintf('rho_macro_T_%d.mat', T);
    data = load(filename);
    rho = data.rho;
    x = data.domain.x;
    % 绘图
    plot(x, rho, '-', 'DisplayName', 'macro', ...
             'LineWidth', 2, 'Color', colors(N_eps+1, :));
    for j = 1:length(epsilons)
        eps = epsilons(j);
        % 构造文件名，例如 rho_eps_1e-03_T_1.mat
        eps_str = sprintf('%.0e', eps);
        filename = sprintf('rho_eps_%s_T_%d.mat', eps_str, T);
        
        % 加载数据
        data = load(filename);
        
        % 提取变量，变量名可能是 rho 和 x
        rho = data.rho;
        x = data.domain.x;
        
        % 绘图
        plot(x, rho, 'DisplayName', ['\epsilon = ', eps_str], ...
             'LineWidth', 2, 'Color', colors(j, :));
    end
    
    % 图像设置
    title(['T = ', num2str(T)]);
    xlabel('x');
    ylabel('\rho(x)');
    legend('Location', 'best');
    grid off;
    set(gca, 'FontSize', 20, 'LineWidth', 2)
end
