% Solve equation
Ds = 2; alpha = 0.05;

my_equation = @(x) chi_N - x - chi_S * x / sqrt(4 * Ds * alpha + x^2); 
x0 = 1; % 初始猜测值
speed_anal_case = fzero(my_equation, x0);

