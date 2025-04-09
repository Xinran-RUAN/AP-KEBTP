# 行进速度测试

展示不同$\varepsilon$与在不同时刻$T$下，PDE与kinetic方程解的行进速度比较：

|   | $T=1$ |$T=10$|$T=20$|$T=30$|$T=40$|$T=50$|
|-------|-------|-------|-------|-------|-------|-------|-------|
| Macro | 0.880333028 | 0.599239839 | 0.727553803 | 0.733532824 | 0.725697528 | 0.722771112 |
| Kinetic $\varepsilon=1$ | 0.518963817 | 0.337444262 | 0.325072197 |  0.328886534| 0.325139289 | 0.312056651
| Kinetic $\varepsilon=10^{-1}$ | 0.755476966 |0.622117057  | 0.73996298 |  0.734300279|0.72678202|0.72959248
| Kinetic $\varepsilon=10^{-2}$ | 0.747591452 |0.616041174  |  0.729054516|  0.734959884|0.72684429|0.724830459
| Kinetic $\varepsilon=10^{-3}$ | 0.816131653 | 0.60631475 | 0.727427547 |  0.733612479|0.725641466|0.723017182

### 数据获得方式
该测试需运行“run\_macro\_batch.m”和"run\_kinetic\_batch.m"，会自动生成对应数据“travel\_speed\_with\_time\_macro\_T\_50.csv”与“travel\_speed\_with\_time\_eps\_1e-01\_T\_50.csv”等。

以下是计算与记录行进速度的相关代码设置：
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

# 误差测试
展示不同$\varepsilon$与在不同时刻$T$下，PDE与kinetic方程解之间的差别$\|\rho-\rho_\varepsilon\|$：

|   | $\varepsilon= 1$ | $\varepsilon=10^{-1}$ | $\varepsilon=0.05$ |$\varepsilon=10^{-2}$|$\varepsilon=10^{-3}$|
|-------|-------|-------|-------|-------|-------|
| T = 1 |  0.457387598| 0.195572754	|0.063367709|0.005665137	| 0.004720726 
| T = 5 |  1.170938306	|0.166912175	|0.048322629|0.004832707	|0.002355114
| T = 10 |  1.802961097	 | 0.143816224	|0.040773215|0.003372185	|0.00141042
| T = 20 | 2.858996388	|0.143795041	|0.040367427	|0.00313379|	0.000241319
| T = 50 |  6.209264324	 |0.139749525 |0.038962193|	0.003058151	|0.000246702

### 数据获得方式
在运行“run\_macro\_batch.m”和"run\_kinetic\_batch.m"完成后，运行“run\_compute\_error.m”生成“error\_table.csv”
