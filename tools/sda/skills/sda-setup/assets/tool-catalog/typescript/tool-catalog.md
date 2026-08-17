# Tool Catalog — TypeScript

Default and alternative tools per required category for TypeScript projects.
Priority 1 = recommended default; 2 = alternative. Read by `sda-setup` (Step 7) and `sda-tool-installer`.

| Category | Tool | Priority | Install command | Hook command | Init command | Check command | Description |
|---|---|---|---|---|---|---|---|
| Test runner | vitest | 1 | `npm install -D vitest` | `npx vitest run --silent` | | `npx vitest --version` | Modern Vite-native test runner; fast and ESM-first |
| Test runner | jest | 2 | `npm install -D jest @types/jest ts-jest` | `npx jest --passWithNoTests --silent` | `(interactive) npx jest --init` | `npx jest --version` | Widely adopted test runner with rich ecosystem |
| Type checker | typescript | 1 | `npm install -D typescript` | `npx tsc --noEmit` | `npx tsc --init` | `npx tsc --version` | Microsoft's type checker and transpiler for TypeScript |
| Linter | eslint | 1 | `npm install -D eslint` | `npx eslint .` | `(interactive) npm init @eslint/config@latest` | `npx eslint --version` | Pluggable linter for JavaScript and TypeScript |
| Linter | biome | 2 | `npm install -D @biomejs/biome` | `npx @biomejs/biome check .` | `npx @biomejs/biome init` | `npx @biomejs/biome --version` | Fast Rust-based linter and formatter; replaces eslint + prettier |
| Code formatter | prettier | 1 | `npm install -D prettier` | `npx prettier --check .` | | `npx prettier --version` | Opinionated code formatter with broad language support |
| Code formatter | biome | 2 | `npm install -D @biomejs/biome` | `npx @biomejs/biome format --check .` | | `npx @biomejs/biome --version` | Fast Rust-based formatter; replaces prettier |
| Coverage | c8 | 1 | `npm install -D c8` | | | `npx c8 --version` | Native V8 coverage; zero-config with Node.js |
| Git hooks | husky | 1 | `npm install -D husky` | | `npx husky init` | `npm list husky` | Git hooks manager for Node.js projects |
| Git hooks | lefthook | 2 | `npm install -D lefthook` | | `npx lefthook install` | `npx lefthook --version` | Fast polyglot Git hooks manager |
| Data format validators | jq + yamllint + xmllint | 1 | See OS-specific commands below | | | | Validators for JSON, YAML, and XML files |

## OS-specific commands for data format validators

| OS | jq | xmllint | yamllint |
|---|---|---|---|
| Windows | `choco install jq` | `choco install xsltproc` | `pip install yamllint` |
| macOS | `brew install jq` | `brew install libxml2` | `pip install yamllint` |
| Linux | `apt install jq` | `apt install libxml2-utils` | `pip install yamllint` |
