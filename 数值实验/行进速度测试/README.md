展示不同$\varepsilon$与在不同时刻$T$下，PDE与kinetic方程解的行进速度比较：

|   | $T=1$ | $T=5$ |$T=10$|$T=50$|
|-------|-------|-------|-------|-------|
| Macro |  |  |  |  |
| Kinetic $\varepsilon=10^{-1}$ |  |  |  |  |
| Kinetic $\varepsilon=10^{-2}$ |  |  |  |  |
| Kinetic $\varepsilon=10^{-3}$ |  |  |  |  |


该测试中的程序与误差测试中的程序完全相同

以下是相关代码设置：
##Marker方法

```
% marker设置
threshold = 0.05; % 需要自己设置
marker_position = zeros(1, NT);
```
```
% 记录marker位置 
wave_front_idx = find(rho >= threshold, 1, 'last');
marker_position(kT) = wave_front_idx * domain.dx;
```
```
% 计算travelling speed并输出为csv文件
travel_speed = (marker_position(2:end) - marker_position(1:end-1)) / dt;
T_values = (2:Nt) * dt; % 时间点
speed_with_time = [T_values; travel_speed]'; % 将时间与速度结合
```
###结论
因空间步长较大，csv文件显示marker的位置因mesh较大，经常好几步才移动一次，导致前几步都没有速度，最后移动的一步才有，因此marker方法不适用于该实验

## 用质心替代marker
```
% 初始化质心位置数组
centroid_positions = zeros(1, NT); 
```
```
% 计算质心位置
numerator = sum(domain.x .* rho) * domain.dx;  % x * rho(x) 的积分
denominator = sum(rho) * domain.dx;  % rho(x) 的积分
centroid_position = numerator / denominator;  % 计算质心位置
centroid_positions(kT) = centroid_position;
```
```
% 计算travelling speed并输出为csv文件
travel_speed = (centroid_positions(2:end) - centroid_positions(1:end-1)) / dt;
T_values = (2:NT) * dt; % 时间点
speed_with_time = [T_values; travel_speed]'; % 将时间与速度结合
```
###结论
相比marker方法结论更平滑准确

##生成csv文件

**PDE模型**

```
% 保存为带时间戳的 CSV 文件
writematrix(speed_with_time, sprintf('travel_speed_with_time_macro_T_%.0f.csv', Tn));
```
**kinetic模型**

```
% 保存为带时间戳的 CSV 文件
writematrix(speed_with_time, sprintf('travel_speed_with_time_eps_%.0e_T_%.0f.csv', eps_val, Tn));
```
