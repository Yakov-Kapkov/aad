# Repository Tool Discovery

**Copilot scans and discovers:**

1. **Package manager detection:**
   - Scan: `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`
   - Report findings: "Found yarn.lock → Project uses yarn"

2. **Test framework detection (REQUIRED: Jest or Vitest):**
   - Scan: `jest.config.ts`, `jest.config.js`, `jest.config.mjs`, `vitest.config.ts`, `vitest.config.js`
   - Check `package.json`: `scripts`, `jest`, `vitest` keys; `devDependencies` for `jest`, `vitest`, `@jest/core`, `@vitest/ui`
   - Report findings: "Found jest.config.ts → Project uses Jest with ts-jest"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

3. **Type checking detection (REQUIRED: TypeScript / tsc):**
   - Scan: `tsconfig.json`, `tsconfig.*.json` (e.g. `tsconfig.build.json`, `tsconfig.test.json`)
   - Check `package.json` `devDependencies` for `typescript`; check `scripts` for `tsc`, `type-check`, `typecheck`
   - Report findings: "Found tsconfig.json → strict mode enabled, target ES2022"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL
   - **Command generation:** `tsc --noEmit` does not support folder-scoped checking — it always type-checks the entire project per `tsconfig.json`. Generate `type-path` identical to `type-all` (no path argument in either variant).

4. **Linter detection (OPTIONAL):**
   - Scan: `.eslintrc`, `.eslintrc.js`, `.eslintrc.json`, `eslint.config.js`, `eslint.config.ts` for ESLint
   - Scan: `biome.json`, `biome.jsonc`, or `devDependencies["@biomejs/biome"]` for Biome (lint mode)
   - Check `package.json` `devDependencies` for `eslint`, `@biomejs/biome`; `scripts` for `lint`
   - Report findings: "Linters: ESLint (typescript-eslint)"
   - Classified in `### Lint` section
   - **Biome** — when detected, also check Formatter detection (section 5); it replaces both ESLint and Prettier

5. **Formatter detection (OPTIONAL):**
   - Scan: `.prettierrc`, `.prettierrc.js`, `.prettierrc.json`, `prettier.config.js`, `prettier.config.ts` for Prettier
   - Scan: `biome.json`, `biome.jsonc`, or `devDependencies["@biomejs/biome"]` for Biome (format mode)
   - Check `package.json` `devDependencies` for `prettier`, `@biomejs/biome`; `scripts` for `format`
   - Report findings: "Formatters: Prettier (semi: false, singleQuote: true)"
   - Classified in `### Format` section

6. **Git hook manager detection (REQUIRED: always scan, may not exist):**
   - Scan: `.husky/` directory for Husky
   - Scan: `.lintstagedrc`, `lint-staged` key in `package.json` for lint-staged
   - Scan: `lefthook.yml`, `.lefthook.yml` for Lefthook
   - Report findings: "Git hooks: Husky + lint-staged"
   - Hook managers route to `### Pre-Commit Checks` only — never to `### Lint` or `### Format`

7. **Coverage threshold detection (REQUIRED: always scan, may not exist):**
   - Scan: `jest.config.ts`, `jest.config.js`, `jest.config.mjs`, `vitest.config.ts`, `vitest.config.js`
   - Look for: `coverageThreshold` object with keys like `global`, `branches`, `functions`, `lines`, `statements`
   - Also check: `package.json[jest]`, `package.json[vitest]` for inline `coverageThreshold`
   - **If found**: Report findings (e.g., "Jest/Vitest: 80% (branches: 80, functions: 80, lines: 80, statements: 80)")
   - **If NOT found**: Report explicitly: "Coverage thresholds: Not configured — no threshold enforced"
   - **If found**: Include threshold value in coverage command examples as inline comments
   - **If NOT found**: Omit threshold comments entirely — never invent a default

8. **Project scripts:**
   - Scan: `package.json[scripts]`, `Makefile`, `.github/workflows`, `scripts/`
   - Report findings: "Found npm scripts: test, test:unit, test:coverage, type-check, lint"
   - Extract commands that wrap jest/vitest/tsc if they exist

9. **Build tool detection (OPTIONAL: always scan, may not exist):**
   - Scan: `package.json[scripts]` for a `build`, `compile`, or `bundle` key
   - Check `devDependencies` for bundlers: `vite`, `webpack`, `esbuild`, `rollup`, `@swc/core`
   - **Command priority:** prefer the project's `build` script unless it chains multiple tools — then construct a direct invocation per [Detection priority](#detection-priority--scripts-reveal-intent-not-syntax) rules in `sda-toolscan`
   - **tsc-only projects:** if no bundler is found and `tsconfig.json` lacks `"noEmit": true`, the compiler produces output — construct `npx tsc` (or runner-prefixed equivalent)
   - Report findings: "Build: `npm run build` (vite)" or "Build: `npx tsc`"
   - **Never write** a watch-mode command (`tsc --watch`, `vite --watch`) as `# build-all`

---

## Test output filter patterns

Pieces joined with `|`. PS uses `$([char]0x...)` for symbols; bash uses literal.
sda-toolscan reads this to generate `filter-test-output` in `project-tools.md`.

**vitest:** ✓, ×, ` FAIL `, `Tests:?\s+\d`, `Test\s+Files:?\s+\d`
**jest:**   ✓, ✕, ` FAIL `, ` PASS `, `Tests:?\s+\d`, `Test\s+Suites:?\s+\d`

---

**Example output (for reference):**
```
Repository Discovery Report
Generated: [timestamp]

Detected Tools:
  Package Manager: npm (found package-lock.json)
  TypeScript: 5.4.x (from package.json devDependencies)
  Test Framework: Jest (jest.config.ts, ts-jest preset)
  Type Checking: tsc (tsconfig.json, strict: true)
  Linters: ESLint (typescript-eslint)
  Formatters: Prettier (semi: false, singleQuote: true)
  Git Hooks: Husky + lint-staged

Suggested Commands:
  Test execution:
    # test-all (script alias — verified non-interactive with --run)
    npm test -- --run
    # test-path  (no coverage; accepts file or folder path — direct invocation)
    npx vitest run --silent src/module/module.test.ts
    # test-path-coverage  (accepts file or folder path; threshold from config — direct invocation)
    npx vitest run --silent --coverage src/module/module.test.ts
    # test-all-coverage  (whole area; threshold from config — direct invocation)
    npx vitest run --silent --coverage
  
  Type checking:
    npx tsc --noEmit
  
  Lint:
    npm run lint
  Format:
    npm run format

⚠️ VALIDATION CHECK:

Checking for REQUIRED tools:
  ✅ Jest/Vitest: Found (jest.config.ts)
  ✅ TypeScript: Found (tsconfig.json)

OR (if missing):

⚠️ MISSING REQUIRED TOOLS:
  ❌ Jest/Vitest: NOT FOUND in project configuration
  ❌ TypeScript: NOT FOUND in project configuration

RECOMMENDATION:
  These tools are REQUIRED for the TDD workflow:
  
  1. Jest + ts-jest (test execution) - Install:
     npm install --save-dev jest ts-jest @types/jest
     # OR for Vitest:
     npm install --save-dev vitest @vitest/coverage-v8
  
  2. TypeScript + tsc (type checking) - Install:
     npm install --save-dev typescript

After installing, the agent can re-scan to generate proper commands.
```
