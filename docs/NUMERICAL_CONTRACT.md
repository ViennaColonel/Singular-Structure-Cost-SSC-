# 接口与数组

| 接口 | 输入 | 输出内容 |
|---|---|---|
| `ssc.paperConfig` | 视差候选 | 参数结构体 |
| `ssc.costVolume` | 左右灰度图、视差与图块参数 | SSC 代价与特征信息 |
| `ssc.baselineCost` | 左右灰度图、方法与配置 | 基础代价体 |
| `ssc.additionalCost` | 左右灰度图、方法与配置 | 比较方法代价体 |
| `ssc.fuse` | 基础代价、SSC 代价与特征 | 融合代价与权重 |
| `ssc.sgm` | 代价体、惩罚参数与视差候选 | 视差图 |
| `ssc.match` | 左右灰度图、配置结构体 | 匹配结果结构体 |
| `ssc.metrics` | 预测、真值与掩膜 | MAE、RMSE、BPR 指标 |

图像与视差数组为 H×W，代价体为 H×W×D；第三维顺序对应视差候选。函数参数、默认值和返回字段见各 `.m` 文件的函数定义。CSV 配置说明见 `EXPERIMENTS.md`。
