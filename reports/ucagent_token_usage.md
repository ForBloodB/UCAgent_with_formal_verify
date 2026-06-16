# UCAgent Token 使用统计

- Date: 2026-06-16
- Scope: 根据 `reports/ucagent_logs/*fixed_generate_ucagent*.log` 中可见的 UCAgent 日志统计。

## 重要说明

当前日志没有记录官方 API 计费口径的 `prompt_tokens`、`completion_tokens`、`total_tokens` 字段。因此这里不能声称得到精确账单 token。

本报告统计的是 UCAgent 自己在上下文超限和摘要压缩时打印的可观测 token 值，例如：

- `Messages token size N exceed max tokens 51200`
- `Summarizing messages(N tokens, M messages)`
- `Summarization done, summary length: N tokens`

这些值可以反映上下文规模和压缩压力，但不是总 API 消耗。真实计费 token 需要从模型服务商账单、API usage endpoint，或在 UCAgent LLM wrapper 中显式记录 response usage。

## 最终三案例批量 Run 可观测值

| Case | Final run start | Max visible context tokens | Summarization input | Summary output | Reading |
| --- | --- | ---: | ---: | ---: | --- |
| `pr21_prefetch_mmio` | 2026-06-15 11:19:04 | 51,929 | 46,539 tokens / 51 messages | 325 | 超过 51,200 上下文阈值后压缩；随后仍未在 900 秒内完成 pytest 模板编辑，结果为 `INFRA_FAIL`。 |
| `pr74_cache_io_idbits` | 2026-06-15 13:01:49 | Not observed | Not observed | Not observed | 最终 run 未出现可见上下文压缩日志；UCAgent 生成测试后 replay 达到 `fixed PASS / buggy FAIL`。 |
| `flush_outstanding_miss` | 2026-06-15 13:04:27 | 51,271 | 46,353 tokens / 53 messages | Not observed | 出现上下文超限和摘要输入日志；supervisor 在 fixed replay 通过后提前停止，因此未看到 summary done 行。 |

## 当前日志文件累计可观测值

这些是当前 fixed-generation internal log 文件的累计值，包含最终 run 之前的历史调试尝试，所以它们不是单次最终 run 账单。

| Log | Summarization events | Sum of summarization input tokens | Sum of summary output tokens | Max context token size | Context exceed events |
| --- | ---: | ---: | ---: | ---: | ---: |
| `flush_outstanding_miss_fixed_generate_ucagent.internal.log` | 1 | 46,353 | 0 | 51,271 | 1 |
| `pr21_prefetch_mmio_fixed_generate_ucagent.internal.log` | 2 | 76,060 | 650 | 51,929 | 1 |
| `pr74_cache_io_idbits_fixed_generate_ucagent.internal.log` | 4 | 125,229 | 940 | 51,363 | 1 |
| **Total observed in current logs** | **7** | **247,642** | **1,590** | **51,929** | **3** |

## 结论

- 能确认：UCAgent 在 PR #21 和 flush case 的最终 run 中都触发了约 51k token 上下文压力。
- 能确认：当前日志累计至少有 7 次上下文摘要压缩，摘要输入 token 合计 247,642。
- 不能确认：总 API 计费 token，因为日志没有保存 provider usage 字段。
- PR #21 的 `INFRA_FAIL` 与 token 压力有关：日志显示它进入 stage 22 后发生路径探索偏移与上下文压缩，但没有完成目标 pytest 编辑。

