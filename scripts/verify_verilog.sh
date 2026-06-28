#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

top=""
smoke=false
args=("$@")

while [[ $# -gt 0 ]]; do
  case "$1" in
    --top)
      if [[ $# -lt 2 ]]; then
        echo "error: --top requires a value" >&2
        exit 2
      fi
      top="$2"
      shift 2
      ;;
    --smoke)
      smoke=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$top" ]]; then
  echo "error: --top is required" >&2
  exit 2
fi

python3 src/formal/verify_verilog.py "${args[@]}"

if [[ "$smoke" == true ]]; then
  exit 0
fi

if [[ -f "$ROOT/.ucagent_env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.ucagent_env"
  set +a
fi

if [[ -z "${OPENAI_API_KEY:-}" || -z "${OPENAI_MODEL:-}" ]]; then
  echo "error: strict mode requires OPENAI_API_KEY and OPENAI_MODEL; use --smoke for local-only verification" >&2
  exit 1
fi

if ! conda run -n ucagent python -c "import ucagent" >/dev/null 2>&1; then
  echo "error: conda environment 'ucagent' cannot import ucagent" >&2
  exit 1
fi

case_dir="$ROOT/reports/generic_verilog/$top"
workspace="$case_dir/ucagent_workspace"
template="$ROOT/src/ucagent_workspaces/generic_verilog"
log_dir="$case_dir/logs"
uca_log="$log_dir/ucagent_generic_verilog.log"
msg_file="$log_dir/ucagent_generic_verilog_messages.jsonl"
note_file="$workspace/reports/generic_verilog_ucagent_note.md"
timeout_seconds="${UCAGENT_GENERIC_VERILOG_TIMEOUT:-1800}"

rm -rf "$workspace"
mkdir -p "$case_dir" "$log_dir" "$workspace/reports"
cp -a "$template"/. "$workspace"/

cat > "$workspace/reports/input_case.md" <<EOF
# Generic Verilog Input Case

- Repo root: \`$ROOT\`
- Top: \`$top\`
- Formal YAML: \`reports/generic_verilog/$top/auto_formal.yaml\`
- Local smoke report: \`reports/generic_verilog/$top/README.md\`

The agent must not edit RTL. Use the generic-formal skill to re-run the YAML case
and then summarize the boundary between smoke verification and functional
property verification.
EOF

loop_msg="Run the generated generic Verilog formal case for top '$top'. First call ListSkill, read .ucagent/skills/generic-formal/SKILL.md, then read reports/input_case.md. Call RunSkillScript with this four-element command: [\"python3\", \"generic-formal\", \"run_formal.py\", \"--workspace $ROOT --case reports/generic_verilog/$top/auto_formal.yaml --timeout 300\"]. Then read reports/input_case.md again if needed and summarize the result. Write reports/ucagent_note.md inside this workspace with the result, the boundary of smoke vs functional property verification, and 2-3 recommended next properties for this RTL. Call SetSkillUsage, Complete, and Exit. Do not modify RTL."

set +e
timeout "$timeout_seconds" conda run -n ucagent ucagent "$workspace" "GenericVerilogDut" \
  --config "$workspace/config.yaml" \
  --backend=langchain \
  --use-skill \
  --extra-skill-path "$ROOT/src/ucagent_skills" \
  --override "skill.general_skill_list=['generic-formal']" \
  --exit-on-completion \
  --no-history \
  --stream-output \
  --log \
  --log-file "$uca_log" \
  --msg-file "$msg_file" \
  --loop-msg "$loop_msg"
ucagent_rc=$?
set -e

if [[ "$ucagent_rc" -eq 124 ]]; then
  echo "error: UCAgent generic Verilog run timed out after ${timeout_seconds}s" >&2
  exit 1
fi

if [[ "$ucagent_rc" -ne 0 ]]; then
  if [[ -f "$uca_log" ]] && grep -q "ToolComplete:" "$uca_log"; then
    echo "[verify_verilog] UCAgent returned $ucagent_rc after ToolComplete; preserving reports"
  else
    exit "$ucagent_rc"
  fi
fi

if [[ -f "$workspace/reports/ucagent_note.md" ]]; then
  cp "$workspace/reports/ucagent_note.md" "$ROOT/reports/generic_verilog/$top/ucagent_note.md" || true
fi
