% Plot rho
figure(1)
plot(domain.x, rho, 'LineWidth', 2, 'Color', 'b');
% hold on;
% plot(domain.x, c, '--', 'LineWidth', 2);
% hold on;
% plot(domain.x, n, '-.', 'LineWidth', 2);
% hold off   
title(strcat('time =', num2str(T)));
xlabel('$x$', 'Interpreter', 'latex');
set(gca, 'FontSize', 20, 'LineWidth', 2);
axis([0 domain.x_max 0 0.1])
% legend('$\rho(x)$', '$c(x)$', '$n(x)$', 'Interpreter', 'latex', 'Location', 'best');
pause(0.1)