# Repository Tool Discovery

**Copilot scans and discovers:**

1. **Package manager detection:**
   - Scan: `pyproject.toml`, `poetry.lock`, `uv.lock`, `requirements.txt`, `Pipfile`
   - Report findings: "Found poetry.lock → Project uses poetry"

2. **Test framework detection (REQUIRED: pytest):**
   - Scan: `pytest.ini`, `pyproject.toml[tool.pytest]`, `tox.ini`, `pyproject.toml[tool.poetry.dependencies]`
   - Check poe tasks: `pyproject.toml[tool.poe.tasks]` (pytest might be in tasks like "test", "pytest")
   - Report findings: "Found pytest.ini → Project uses pytest with asyncio_mode=auto"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

3. **Type checking detection (REQUIRED: mypy):**
   - Scan: `pyproject.toml[tool.mypy]`, `pyproject.toml[tool.poetry.dependencies]`, `mypy.ini`
   - Check poe tasks: `pyproject.toml[tool.poe.tasks]` (mypy might be in tasks like "type-check", "mypy")
   - Report findings: "Configured: mypy with strict settings"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

4. **Linter detection (OPTIONAL):**
   - Scan: `pyproject.toml[tool.ruff.lint]`, `pyproject.toml[tool.ruff]` for ruff (check)
   - Scan: `setup.cfg[flake8]`, `.flake8`, `pyproject.toml[tool.flake8]` for flake8
   - Scan: `.pylintrc`, `pyproject.toml[tool.pylint]` for pylint
   - Scan: `pyproject.toml[tool.bandit]` for bandit
   - Report findings: "Linters: ruff (check), flake8"
   - Classified in `### Lint` section — commands use `ruff check`, `flake8`, `pylint`
   - **ruff** — always a Linter (`ruff check` reports violations); do NOT also classify as Formatter based on `[tool.ruff]` alone — only if `[tool.ruff.format]` is present (see section 5)

5. **Formatter detection (OPTIONAL):**
   - Scan: `pyproject.toml[tool.ruff]`, `pyproject.toml[tool.ruff.format]`, or `ruff format` in project scripts or hooks, for ruff (format) — **preferred formatter**
   - Scan: `pyproject.toml[tool.black]` for black
   - Scan: `pyproject.toml[tool.isort]` for isort
   - Scan: `pyproject.toml[tool.autoflake]`, `pyproject.toml[tool.pyupgrade]`, `pyproject.toml[tool.docformatter]` for others
   - Report findings: "Formatters: ruff (format)"
   - Classified in `### Format` section — commands use `ruff format`, `black`, `isort`
   - **ruff format** — classify ruff as a Formatter whenever ruff is installed (`[tool.ruff]` in pyproject.toml is sufficient); `ruff format` works with zero additional configuration and is a drop-in replacement for black

6. **Git hook manager detection (REQUIRED: always scan, may not exist):**
   - Scan: `.pre-commit-config.yaml` for pre-commit
   - Scan: `pyproject.toml[tool.poetry.dev-dependencies]` or `[project.optional-dependencies]` for `pre-commit`
   - Report findings: "Git hooks: pre-commit"
   - Hook managers route to `### Pre-Commit Checks` only — never to `### Lint` or `### Format`

7. **Coverage threshold detection (REQUIRED: always scan, may not exist):**
   - Scan: `pyproject.toml[tool.pytest.ini_options]` for `--cov-fail-under` flag or numeric threshold
   - Also check: `pytest.ini[pytest]` for `cov_fail_under` or similar settings
   - Also check: `pyproject.toml[tool.coverage]` for `fail_under` key
   - **If found**: Report findings (e.g., "pytest: 80% (fail-under threshold configured)")
   - **If NOT found**: Report explicitly: "Coverage thresholds: Not configured — no threshold enforced"
   - **If found**: Include threshold value in coverage command examples as inline comments
   - **If NOT found**: Omit threshold comments entirely — never invent a default
   - **Addopts coverage scan:** Check `pyproject.toml[tool.pytest.ini_options] addopts` for embedded `--cov` or `--cov-fail-under` entries. When found, report **addopts-coverage: true** in scan findings and apply these command adjustments:
     - Non-coverage scoped runs (single file or folder): append `--no-cov`
     - Scoped coverage runs (single file or folder): prefix with `--override-ini="addopts="`, then re-add the explicit `--cov=<module>` and `--cov-report` flags
     - Full-suite runs: no change — inherit addopts as-is

8. **Project scripts:**
   - Scan: `pyproject.toml[tool.poe.tasks]`, `Makefile`, `.github/workflows`, `scripts/`
   - Report findings: "Found poe tasks: pre-commit-checks, pytest, mypy"
   - Extract commands that wrap pytest/mypy if they exist

9. **Build tool detection (OPTIONAL: always scan, may not exist):**
   - Scan: `pyproject.toml[build-system]` for a build backend (`flit_core`, `hatchling`, `setuptools`, `pdm-backend`)
   - Scan project scripts (`[tool.poe.tasks]`, `Makefile`) for a `build` or `compile` target
   - **Most Python server apps run directly** — `_Not detected._` is the expected result for the majority of projects
   - When found, use the runner-prefixed form per the package manager runner rule above: `poetry build`, `uv build`, `python -m build`
   - Report findings: "Build: `poetry build`" or "Build: none (runtime app — not detected)"

---

## Test output filter patterns

Pieces joined with `|`. PS uses `$([char]0x...)` for symbols; bash uses literal.
sda-toolscan reads this to generate `filter-test-output` in `project-tools.md`.

**pytest:** `FAILED`, `PASSED`, `FAILURES`, `\d+\s+failed`, `\d+\s+passed`

---

**Command generation rules:**

**Package manager runner (applies to ALL generated commands):** Use the runner prefix that matches the package manager detected in step 1. Every CLI command — test runners, type checkers, linters, formatters, and app-run start commands — must be prefixed:

| Detected package manager | Runner prefix |
|---|---|
| `poetry` | `poetry run {tool} ...` |
| `uv` | `uv run {tool} ...` |
| `pipenv` | `pipenv run {tool} ...` |

- Never use bare binary calls (`pytest`, `mypy`, `black`, `python3 script.py`, `python -m ...`) — they require the virtual environment to already be activated.
- When a source (README, docs) presents multiple equivalent forms for the same command (e.g., `python3 api.py` as primary with `poetry run uvicorn ...` as an alternative), always select the runner-prefixed form and discard the bare invocation.

---

**Example output (for reference):**
```
Repository Discovery Report
Generated: [timestamp]

Detected Tools:
  Package Manager: poetry (found poetry.lock)
  Python: >=3.10.4, <3.13 (from pyproject.toml)
  Test Framework: pytest (pytest.ini, asyncio_mode=auto)
  Linters: ruff (check), flake8
  Formatters: ruff (format)
  Git Hooks: pre-commit

Suggested Commands:
  Test execution:
    # test-all
    poetry run pytest
    # test-path  (no coverage; accepts file or folder path)
    poetry run pytest tests/unit/test_file.py --no-cov
    # test-path-coverage  (accepts file or folder path; threshold from config; --override-ini clears addopts when it contains --cov)
    poetry run pytest tests/unit/test_file.py --override-ini="addopts=" --cov=module.name --cov-report=term-missing
    # test-all-coverage  (whole project; threshold from config — inherits addopts, no override flags)
    poetry run pytest --cov=<package> --cov-report=term-missing

  ⚠️  Whole-area coverage: when `addopts` already carries `--cov=...` and
      `--cov-fail-under=N`, omit the `--cov` argument — emit `poetry run pytest`
      with the silence flag only.

  ⚠️  --override-ini="addopts=" in scoped coverage commands:
      When `addopts` in `pyproject.toml` embeds `--cov=<dir>` and/or `--cov-fail-under=N`,
      every pytest invocation (including single-file runs) measures the entire source tree
      against the project-wide threshold. `--override-ini="addopts="` clears that for the
      invocation; the explicit `--cov=<module>` that follows scopes coverage to the target
      only. Omit this flag when addopts does NOT contain coverage entries.

  ⚠️  --cov target format:
      `--cov` takes an importable module name (dot-separated), NOT a path.
      Wrong format silently falls back to project-wide coverage.

      ✅ --cov=mypackage.utils.helpers
      ❌ --cov=src/mypackage/utils/helpers.py
      ❌ --cov=src/mypackage/utils/helpers

      To convert a source file path to a --cov target:
      1. Strip the pythonpath prefix (e.g., `src/`)
      2. Strip the `.py` extension
      3. Replace `/` with `.`
      Example: `src/mypackage/utils/helpers.py` → `--cov=mypackage.utils.helpers`

      Resolve the import root from [tool.pytest.ini_options] pythonpath
      or [tool.setuptools.packages.find] where. The value must work as
      `import <value>`.
  
  Type checking:
    poetry run mypy src/
  
  Pre-commit:
    poetry run poe pre-commit-checks

⚠️ VALIDATION CHECK:

Checking for REQUIRED tools:
  ✅ pytest: Found (in pytest.ini)
  ✅ mypy: Found (in pyproject.toml)

OR (if missing):

⚠️ MISSING REQUIRED TOOLS:
  ❌ pytest: NOT FOUND in project configuration
  ❌ mypy: NOT FOUND in project configuration

RECOMMENDATION:
  These tools are REQUIRED for the TDD workflow:
  
  1. pytest (test execution) - Install:
     poetry add --group dev pytest pytest-asyncio
  
  2. mypy (type checking) - Install:
     poetry add --group dev mypy

After installing, the agent can re-scan to generate proper commands.
```
