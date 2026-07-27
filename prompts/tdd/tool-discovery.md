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

4. **Code quality tools (OPTIONAL):**
   - Scan: `pyproject.toml[tool.*]` for black, ruff, flake8, isort, pre-commit
   - Report findings: "Configured: black (line-length: 120), flake8"
   - These are optional - workflow can proceed without them

5. **Project scripts:**
   - Scan: `pyproject.toml[tool.poe.tasks]`, `Makefile`, `.github/workflows`, `scripts/`
   - Report findings: "Found poe tasks: pre-commit-checks, pytest, mypy"
   - Extract commands that wrap pytest/mypy if they exist

**Copilot presents discovery report:**
```
Repository Discovery Report
Generated: [timestamp]

Detected Tools:
  Package Manager: poetry (found poetry.lock)
  Python: >=3.10.4, <3.13 (from pyproject.toml)
  Test Framework: pytest (pytest.ini, asyncio_mode=auto)
  Code Quality: mypy, black, flake8, isort, pre-commit

Suggested Commands:
  Test execution:
    poetry run pytest                           # All tests
    poetry run pytest tests/unit/test_file.py   # Specific file
    poetry run pytest -v --tb=short             # Verbose
  
  Type checking:
    poetry run mypy src/
  
  Code quality:
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

After installing, I can re-scan to generate proper commands.

Should I:
  A) Proceed with available tools only (NOT RECOMMENDED - missing required tools)
  B) Wait for you to install missing tools, then re-run Tool Discovery
  C) Show installation commands and wait

Questions:
  1. Use "poetry run pytest" for all tests? (Yes/modify)
  2. Any custom flags to add?
  3. Prefer poe tasks or direct commands?

Ready to save these commands to project-tools.md?
```

**Human responses:**
- ✅ "Approved" / "Yes" / "Save" → Save commands, continue with the current task
- 🔧 "Use [different command]" → Update and save
- 🔄 "Add [command]" → Add to list and save
- ⚠️ "Install missing" / "Option B" / "Option C" → Handle missing tools first

**After approval:**
- Create `project-tools.md` with approved commands
- Confirm: "Project tool discovery complete ✓"
- **✋ STOP and ask:** "Ready to continue with the current task?"
- **WAIT for explicit approval** before proceeding with the current task
