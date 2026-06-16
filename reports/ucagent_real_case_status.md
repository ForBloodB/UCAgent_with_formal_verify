# UCAgent Real-Case Status

- Date: 2026-06-16
- Scope: real NutShell Cache PR #21 / PR #74 only.

The previous UCAgent artifacts were generated against compact or artificial DUT
shims. They are useful as workflow experiments, but they are not valid evidence
for the stricter requirement that the DUT core must be the real NutShell Cache
from the historical upstream commits.

Therefore those artifacts and workspaces were removed from the retained
deliverable. No UCAgent pass/fail matrix is claimed for the real PR #21 / PR #74
Cache wrappers in the current workspace.

Retained UCAgent material:

| Item | Status |
| --- | --- |
| `.ucagent_env.example` | Kept as the non-secret LLM environment template. |
| `scripts/00_setup_ucagent_sources.sh` | Kept to fetch official UCAgent, Example-NutShellCache, and picker sources. |
| `scripts/01_install_ucagent_venv.sh` | Kept as an optional reproducible UCAgent Python environment helper. |
| `docker/ucagent.Dockerfile` | Kept as an optional UCAgent container recipe. |
| `reports/toolchain_sources.md` | Kept as official source commit record. |

Current classification for real NutShell Cache UCAgent verification:

| Case | UCAgent status | Reason |
| --- | --- | --- |
| PR #21 real Cache | NOT_CLAIMED | Existing UCAgent runs did not use the real upstream NutShell `nutcore.Cache` wrapper. |
| PR #74 real CacheIO | NOT_CLAIMED | Existing UCAgent runs did not use the real upstream NutShell `nutcore.Cache` wrapper. |

This is intentionally conservative: the formal reports are the retained real-DUT
evidence, and UCAgent results should only be reintroduced after building a
Picker/Toffee workspace around these exact real Cache wrappers.
