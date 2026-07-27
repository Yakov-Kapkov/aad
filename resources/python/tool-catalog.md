# Tool Catalog — Python

Default and alternative tools per required category for Python projects.
Priority 1 = recommended default; 2 = alternative. Read by `sda-setup` (Step 7) and `sda-tool-installer`.

| Category | Tool | Priority | Install command | Hook command | Init command | Check command | Description |
|---|---|---|---|---|---|---|---|
| Package manager | uv | 1 | `pip install uv` | | | `uv --version` | Fast Rust-based package manager; replaces pip, virtualenv, and pipx |
| Package manager | poetry | 2 | `pipx install poetry` | | | `poetry --version` | Mature project manager with lock files and workspace support |
| Test runner | pytest | 1 | `pip install pytest` | `pytest` | | `pytest --version` | The standard Python test framework |
| Type checker | mypy | 1 | `pip install mypy` | `mypy .` | | `mypy --version` | Static type checker with gradual typing support |
| Type checker | pyright | 2 | `pip install pyright` | `pyright` | | `pyright --version` | Fast type checker from Microsoft, used by Pylance |
| Linter | ruff | 1 | `pip install ruff` | `ruff check .` | | `ruff --version` | Extremely fast linter written in Rust; replaces pylint and flake8 |
| Code formatter | ruff | 1 | `pip install ruff` | `ruff format --check .` | | `ruff --version` | Fast formatter written in Rust; drop-in replacement for black with zero config; same package as the linter |
| Code formatter | black | 2 | `pip install black` | `black --check .` | | `black --version` | Opinionated formatter; the original Python standard |
| Coverage | coverage | 1 | `pip install coverage` | | | `coverage --version` | Standard coverage tool with HTML/XML reports |
| Coverage | pytest-cov | 2 | `pip install pytest-cov` | | | | Coverage plugin that integrates directly with pytest runs |
| Git hooks | pre-commit | 1 | `pip install pre-commit` | | `pre-commit install` | `pre-commit --version` | Git hooks framework; runs checks before every commit |
| Data format validators | jq + yamllint + xmllint | 1 | See OS-specific commands below | | | | Validators for JSON, YAML, and XML files |

## OS-specific commands for data format validators

| OS | jq | xmllint | yamllint |
|---|---|---|---|
| Windows | `choco install jq` | `choco install xsltproc` | `pip install yamllint` |
| macOS | `brew install jq` | `brew install libxml2` | `pip install yamllint` |
| Linux | `apt install jq` | `apt install libxml2-utils` | `pip install yamllint` |
