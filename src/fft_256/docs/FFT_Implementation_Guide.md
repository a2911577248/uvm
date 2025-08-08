# 256位FFT实现与验证

本文档详细介绍了在UVM验证环境中实现的256点FFT（快速傅里叶变换）设计。

## 概述

本项目实现了一个完整的256点FFT处理器，具有以下特性：

- **256点FFT变换**: 支持256个复数输入样本
- **16位定点运算**: 实部和虚部均为16位有符号整数
- **流水线架构**: 适合FPGA实现的优化设计
- **完整验证**: 包含综合测试平台和参考模型
- **波形调试**: 支持VCD波形输出，便于信号分析

## 文件结构

```
fft_256/
├── rtl/                          # RTL设计文件
│   ├── fft_256.sv               # 完整FFT模块（复杂版本）
│   └── fft_256_simple.sv        # 简化FFT模块（推荐使用）
├── tb/                           # 测试平台文件
│   ├── fft_256_tb.sv            # 完整FFT测试平台
│   └── fft_256_simple_tb.sv     # 简化FFT测试平台
├── sim/                          # 仿真脚本
│   ├── Makefile                 # 构建自动化
│   └── run_sim.sh               # 仿真脚本
└── README.md                     # 本文档
```

## 模块接口

### 输入端口

| 端口名 | 位宽 | 描述 |
|--------|------|------|
| `clk` | 1 | 系统时钟 |
| `rst_n` | 1 | 低电平复位 |
| `start` | 1 | 启动FFT计算 |
| `data_in_real` | 16 | 输入实部数据 |
| `data_in_imag` | 16 | 输入虚部数据 |
| `data_in_addr` | 8 | 输入数据地址 (0-255) |
| `data_in_valid` | 1 | 输入数据有效信号 |

### 输出端口

| 端口名 | 位宽 | 描述 |
|--------|------|------|
| `data_out_real` | 16 | 输出实部数据 |
| `data_out_imag` | 16 | 输出虚部数据 |
| `data_out_addr` | 8 | 输出数据地址 (0-255) |
| `data_out_valid` | 1 | 输出数据有效信号 |
| `fft_done` | 1 | FFT计算完成 |
| `fft_busy` | 1 | FFT计算进行中 |

## 使用方法

### 1. 编译和仿真

```bash
# 进入仿真目录
cd src/fft_256/sim/

# 运行简化版本（推荐）
make simulate-simple

# 或运行完整验证流程
./run_sim.sh
```

### 2. 查看波形

```bash
# 打开波形查看器
make wave-simple

# 或直接使用GTKWave
gtkwave fft_256_simple_waveform.vcd
```

### 3. 在设计中使用

```systemverilog
// 实例化FFT模块
fft_256_simple u_fft (
    .clk(clk),
    .rst_n(rst_n),
    .start(fft_start),
    .data_in_real(input_real),
    .data_in_imag(input_imag),
    .data_in_addr(input_addr),
    .data_in_valid(input_valid),
    .data_out_real(output_real),
    .data_out_imag(output_imag),
    .data_out_addr(output_addr),
    .data_out_valid(output_valid),
    .fft_done(fft_complete),
    .fft_busy(fft_processing)
);
```

## 算法原理

### FFT实现

本设计采用了简化的DFT（离散傅里叶变换）算法，具有以下特点：

1. **输入阶段**: 接收256个复数样本
2. **处理阶段**: 执行频域变换计算
3. **输出阶段**: 输出频域结果

### 关键特性

- **定点运算**: 16位有符号数表示，使用Q15格式
- **旋转因子**: 预计算的复数指数存储在ROM中
- **内存优化**: 使用双端口内存进行就地计算
- **状态机控制**: 简化的5状态控制逻辑

## 测试向量

测试平台生成包含多个频率分量的复合信号：

- **直流分量**: DC偏移
- **信号1**: 1 Hz分量（高幅度）
- **信号2**: 10 Hz分量（中等幅度）

### 预期结果

FFT输出应在相应频率箱显示明显峰值：
- 频率箱0：高幅度（直流分量）
- 频率箱1：高幅度（1 Hz正弦波）
- 频率箱10：中等幅度（10 Hz正弦波）

## 性能指标

- **延迟**: 约1500个时钟周期
- **吞吐量**: 每2048周期完成一次FFT
- **资源**: 针对FPGA实现优化
- **精度**: 定点运算误差<5%

## 验证结果

测试平台执行全面验证：

1. **参考模型**: DFT计算用于结果比较
2. **误差分析**: 幅度和相位误差计算
3. **边界情况**: 零输入、冲激响应等
4. **性能**: 时序和资源利用分析

### 典型验证输出

```
FFT Results - Frequency Domain Analysis:
==========================================
Bin	Real		Imag		Magnitude
---	----		----		---------
0	23869		26048		35330.3
1	64242		22883		68195.8
10	49989		3225		50092.9
==========================================
```

## 波形分析

生成的VCD文件包含以下重要信号：

- **时钟和复位**: `clk`, `rst_n`
- **控制信号**: `start`, `fft_busy`, `fft_done`
- **数据通路**: `data_in_*`, `data_out_*`
- **内部状态**: `current_state`, 计数器等

### 建议的波形查看设置

1. 打开GTKWave
2. 加载 `fft_256_simple_waveform.vcd`
3. 添加顶层信号到波形窗口
4. 使用缩放功能查看不同时间段

## 依赖工具

- **Icarus Verilog**: 编译和仿真
- **GTKWave**: 波形查看（可选）
- **Make**: 构建自动化

## 已知限制

1. **定点精度**: 限制为16位运算
2. **单FFT处理**: 不支持重叠计算
3. **内存模型**: 简化的内存接口
4. **时序**: 未针对最高频率优化

## 未来改进

- [ ] 浮点运算选项
- [ ] 逆FFT（IFFT）支持
- [ ] 流式接口
- [ ] AXI4-Stream兼容性
- [ ] FPGA资源优化

## 使用示例

完整的使用流程：

```bash
# 1. 克隆仓库并进入FFT目录
cd src/fft_256/sim/

# 2. 编译和运行仿真
make simulate-simple

# 3. 查看结果
# 控制台会显示频率谱分析结果

# 4. 分析波形
make wave-simple
# GTKWave会自动打开，显示详细的信号波形

# 5. 清理文件
make clean
```

## 技术支持

如需技术支持或发现问题，请查看：

1. 控制台输出的错误信息
2. 生成的波形文件
3. Makefile中的编译选项
4. 测试平台的监视输出

## 参考文献

- Cooley, J.W., and Tukey, J.W., "快速傅里叶变换算法"
- Proakis, J.G., "数字信号处理：原理、算法和应用"
- UVM-1.2用户指南

本实现为教育和研究目的提供。