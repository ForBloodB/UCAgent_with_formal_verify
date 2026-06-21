# NutShell Cache Real PR Formal Verification

This repository is now scoped to real historical NutShell Cache cases only.
The earlier compact/artificial three-case demos were removed.

In addition, `ucagent_skills/generic-formal` contains a tiny counter smoke test
for validating a reusable UCAgent formal skill. That smoke test is not claimed
as a NutShell Cache case.

| Case | Upstream history | What is checked |
| --- | --- | --- |
| PR #21 `Bug prefetch mmio` | pre `bd425dee`, fixed `f0d7c494` | A real NutShell `nutcore.Cache` must not let an MMIO prefetch disturb an existing normal cache/L2 pipeline entry. |
| PR #74 `cache: fix cache io` | pre `4b656f32`, fixed `287c5e02` | A real NutShell `nutcore.Cache` with `idBits=4` must expose and preserve the SimpleBus request/response ID field. |

## Layout

```text
formal/nutshell_pr21_real/   Real NutShell PR #21 wrapper, generated RTL, and SBY configs
formal/nutshell_pr74_real/   Real NutShell PR #74 wrapper, generated RTL, and SBY config
scripts/40_*.sh              Fetch/generate PR #21 real Cache RTL
scripts/41_*.sh              Run PR #21 real formal
scripts/42_*.sh              Fetch/generate PR #74 real Cache RTL
scripts/43_*.sh              Run PR #74 real formal
reports/                     Real-case reports and logs
docker/                      Optional formal and UCAgent environments
ucagent_skills/              Reusable UCAgent skill experiments
examples/counter_formal/     Minimal skill smoke test, not a NutShell Cache case
```

## Reproduce

Formal runs use the existing `nutshell-cache-formal:latest` Docker image:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
  nutshell-cache-formal:latest bash scripts/41_run_pr21_real_nutshell_cache_formal.sh

docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work \
  nutshell-cache-formal:latest bash scripts/43_run_pr74_real_nutshell_cache_formal.sh
```

If generated RTL is missing, prepare it first on the host:

```bash
bash scripts/40_prepare_pr21_real_nutshell_cache.sh all
bash scripts/42_prepare_pr74_real_nutshell_cache.sh fixed
```

PR #74 pre-PR generation is expected to fail:

```bash
bash scripts/42_prepare_pr74_real_nutshell_cache.sh pre
```

That failure is the real bug trigger: the parent commit builds `CacheIO.in`
without `idBits`, so a `CacheConfig(idBits = 4)` wrapper fails at the real
Cache connection with `Right Record missing field (id)`.

## Current Results

| Report | Expected result |
| --- | --- |
| `reports/pr21_real_nutshell_cache_formal.md` | pre-PR FAIL, fixed PASS |
| `reports/pr74_real_nutshell_cache_formal.md` | pre-PR elaboration FAIL, fixed generation PASS, fixed formal PASS |
| `reports/generic_formal/counter_minimal.md` | generic formal skill smoke: buggy FAIL, fixed PASS |
| `reports/ucagent_real_case_status.md` | UCAgent compact/artificial artifacts removed; no non-real result is claimed |

## Official Sources

- UCAgent: https://github.com/XS-MLVP/UCAgent
- Example-NutShellCache: https://github.com/XS-MLVP/Example-NutShellCache
- picker: https://github.com/XS-MLVP/picker
- NutShell PR #21: https://github.com/OSCPU/NutShell/pull/21
- NutShell PR #74: https://github.com/OSCPU/NutShell/pull/74
