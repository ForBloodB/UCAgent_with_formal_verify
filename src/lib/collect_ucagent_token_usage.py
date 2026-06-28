#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


TOKEN_PATTERNS = {
  "prompt_tokens": re.compile(r"prompt_tokens['\"]?\s*[:=]\s*(\d+)", re.IGNORECASE),
  "completion_tokens": re.compile(r"completion_tokens['\"]?\s*[:=]\s*(\d+)", re.IGNORECASE),
  "total_tokens": re.compile(r"total_tokens['\"]?\s*[:=]\s*(\d+)", re.IGNORECASE),
  "input_tokens": re.compile(r"input_tokens['\"]?\s*[:=]\s*(\d+)", re.IGNORECASE),
  "output_tokens": re.compile(r"output_tokens['\"]?\s*[:=]\s*(\d+)", re.IGNORECASE),
}


def main() -> int:
  parser = argparse.ArgumentParser(description="Collect token usage hints from UCAgent logs.")
  parser.add_argument("--log-dir", required=True)
  parser.add_argument("--output", required=True)
  args = parser.parse_args()

  log_dir = Path(args.log_dir)
  output = Path(args.output)
  totals = {key: 0 for key in TOKEN_PATTERNS}
  matches = []

  for path in sorted(log_dir.glob("*")):
    if not path.is_file():
      continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for key, pattern in TOKEN_PATTERNS.items():
      values = [int(v) for v in pattern.findall(text)]
      if values:
        totals[key] += sum(values)
        matches.append((path.name, key, len(values), sum(values)))

  output.parent.mkdir(parents=True, exist_ok=True)
  lines = [
    "# UCAgent Token 使用统计",
    "",
    "该文件由本地 UCAgent 日志解析得到。部分 backend 不输出 token 统计字段，因此缺失值表示 `not reported`，不是实际使用量为零。",
    "",
    "| 指标 | 解析总和 |",
    "| --- | ---: |",
  ]
  for key, value in totals.items():
    lines.append(f"| `{key}` | {value} |")
  lines.extend(["", "## 匹配项", "", "| 日志 | 指标 | 数量 | 总和 |", "| --- | --- | ---: | ---: |"])
  if matches:
    for item in matches:
      lines.append(f"| `{item[0]}` | `{item[1]}` | {item[2]} | {item[3]} |")
  else:
    lines.append("| _none_ | _not reported_ | 0 | 0 |")
  output.write_text("\n".join(lines) + "\n", encoding="utf-8")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
