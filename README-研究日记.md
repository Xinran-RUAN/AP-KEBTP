# AP-KEBTP
This is the joint work with Gissell Estrada-Rodriguez and Canan Akkoyunlu. 

The formation of suspensions of swimming bacteria self-aggregate in regions where the conditions are more favorable, for instance there is more oxygen. These high concentration regions propagate along the channel. This phenomena was first reported by Adler [1]. **Chemotaxis** is widely known to be responsible for the formation of these **travelling pulses** in capillary assays (or micro-channels). 

# 2025-10-27: 

1. 画不同$\chi_S$, $\chi_N$的图；heat plot形式
2. 数值算例：$\psi_0 = 1, v\in(-1,1)$
3. 根据comment修改
4. 检查analytical solution的来源
5. 完善bound preserving的证明

# 2026-01-16:
## Travelling pulse（kinetic 为主）数值实验部分——待办简短记录

## 目标（数值实验要回答的问题）
- 验证 AP：固定网格下，$\epsilon\to 0$ 时 kinetic 的 $\rho^\epsilon$ 收敛到宏观 $\rho$。
- 验证 travelling pulse：是否形成稳定脉冲、速度是否稳定/唯一、形状是否保持（前缓后陡）。
- 评估数值性质：limiter 对质量守恒/速度/形状的影响，网格与速度离散的敏感性。

## 统一诊断量（建议所有实验都输出）
- 速度：质心速度 $c_cm(t)$ + 峰值位置速度 $c_p(t)$ 交叉验证；稳态区间取平均得到 $c_num$。
- 形状：峰值 $max\rho$、半高宽 $W_{1/2}$、左右指数衰减率（拟合得到 $\lambda_n^\epsilon,\lambda_p^\epsilon$）。
- 质量与非负性：总质量 M(t)、min f、limiter 触发率（时间/空间占比）。

## 建议新增实验（从必须到可选）
### 必须
- \epsilon 收敛：\epsilon=0.2,0.1,0.05,0.02,0.01；在 pulse 成形后时刻 T 比较 L1/L2/L∞ 误差（表或 log-log 图）。
- 网格敏感性：\Delta x=0.2,0.1,0.05；kinetic 再做 \Delta v=0.05,0.02,0.01；比较最终 c、max\rho、W_{1/2}。
- 速度唯一性测试：同一参数下换不同初值（宽度/位置/双峰），检查最终 c 是否一致；并选一组“违反文献条件”的参数区做对照。

### 强烈建议
- (\chi_S,\chi_N) 相图：标注是否形成 pulse；形成时用颜色表示 c；用符号标出“对初值敏感/多速度”区域。
- 微观参数机制：扫 \mu（如 0.05/0.1/0.2），观察速度与形状不对称性变化。

### 可选
- limiter 影响评估：有/无 limiter（或不同强度）对 c、误差、min f、质量守恒的影响对比。

## 需要顺手统一/修正的点
- 边界条件表述统一（Neumann/Dirichlet/zero-flux/reflective 不要混用），说明物理含义与数值实现。
- travelling speed 取“稳定平台”区间平均，并说明区间选择依据（速度曲线平台）。
- 宏观解析速度公式写法统一，明确作为对照的 analytic speed 采用哪一版（\epsilon 是否取 0）。

## 建议的论文数值小节结构
- Numerical setup & diagnostics
- Macroscopic pulse validation
- AP test: \epsilon\to0 convergence
- Kinetic pulse shape & asymmetry（含 \mu 影响）
- Speed selection / (non)uniqueness
- Robustness: mesh + limiter


## 参考文献

1. Adler. Chemotaxis in bacteria. *Surface Membrane Receptors: Interface Between Cells and Their Environment*, 419–435, 1976.
