# Repository Tool Discovery

**Copilot scans and discovers:**

1. **SDK and project file detection:**
   - Scan: `*.sln`, `*.csproj`, `Directory.Build.props`, `global.json`, `NuGet.Config`
   - Report findings: "Found solution.sln → .NET project, global.json → SDK 8.0.x"

2. **Test framework detection (REQUIRED: xUnit, NUnit, or MSTest):**
   - Scan: `*.csproj` for `xunit`, `xunit.runner.visualstudio`, `NUnit`, `NUnit3TestAdapter`, `MSTest.TestAdapter`, `MSTest.TestFramework`
   - Check: test project naming convention (`*.Tests.csproj`, `*.UnitTests.csproj`)
   - Check: `dotnet test` runner configuration in `.runsettings` or `*.csproj` `<VSTestLogger>`
   - Report findings: "Found xunit 2.9.x → Project uses xUnit"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

3. **Static analysis detection (REQUIRED: Roslyn analyzers):**
   - Scan: `*.csproj` for `Microsoft.CodeAnalysis.NetAnalyzers`, `StyleCop.Analyzers`, `SonarAnalyzer.CSharp`, `Roslynator.Analyzers`
   - Check: `.editorconfig` for `dotnet_diagnostic.*` severity rules
   - Check: `Directory.Build.props` for `<AnalysisMode>`, `<TreatWarningsAsErrors>`, `<EnforceCodeStyleInBuild>`
   - Report findings: "Configured: .NET analyzers (All mode), StyleCop.Analyzers"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

4. **Formatter detection (OPTIONAL):**
   - Scan: `dotnet-tools.json` (`.config/dotnet-tools.json`) for `dotnet-format`, `csharpier`
   - Scan: `*.csproj` or `Directory.Build.props` for `<PackageReference Include="CSharpier">`
   - Scan: `.editorconfig` for formatting rules (consumed by `dotnet-format`)
   - Report findings: "Formatters: dotnet-format, CSharpier"
   - Classified in `### Format` section
   - Note: linting is handled by Roslyn analyzers (section 3) — no standalone linter binary detection needed

5. **Coverage tool detection (OPTIONAL):**
   - Scan: `*.csproj` or `Directory.Build.props` for `coverlet.collector`, `coverlet.msbuild`, `dotnet-coverage`
   - Report findings: "Coverage: coverlet.collector"

6. **Coverage threshold detection (REQUIRED: always scan, may not exist):**
   - Scan: `*.runsettings` for `<Threshold>` under `<CoverletSettings>` or `<Threshold>` element
   - Also check: `*.csproj` for `<CoverletThreshold>` MSBuild property
   - Also check: CI workflow files (`.github/workflows/*.yml`) for `--threshold` flag in `dotnet test` commands
   - Look for: line, branch, method coverage thresholds
   - **If found**: Report findings (e.g., "coverlet: 80% (line threshold in .runsettings)")
   - **If NOT found**: Report explicitly: "Coverage thresholds: Not configured — no threshold enforced"
   - **If found**: Include threshold value in coverage command examples as inline comments
   - **If NOT found**: Omit threshold comments entirely — never invent a default

7. **Project scripts:**
   - Scan: `Makefile`, `.github/workflows`, `scripts/`, `build.ps1`, `build.sh`
   - Report findings: "Found Makefile targets: build, test, coverage; GitHub Actions: ci.yml"
   - Extract commands that wrap `dotnet test`/`dotnet build` if they exist

8. **Build tool detection (REQUIRED: dotnet build):**
   - `dotnet build` is always available for `*.csproj`-based projects — no probe required
   - Scan `Makefile`, `.github/workflows/`, `scripts/` for a custom `build` target wrapping `dotnet build`; prefer the project script if found
   - Report findings: "Build: `dotnet build`"

9. **Git hook manager detection (REQUIRED: always scan, may not exist):**
   - Scan: `.husky/` for husky.net
   - Scan: `.pre-commit-config.yaml` for pre-commit
   - Scan: `.git/hooks/` for raw git hooks
   - Report findings: "Git hooks: husky.net, pre-commit"
   - Hook managers route to `### Pre-Commit Checks` only — never to the lint or format sections

---

## Test output filter patterns

Pieces joined with `|`. PS uses `$([char]0x...)` for symbols; bash uses literal.
sda-toolscan reads this to generate `filter-test-output` in `project-tools.md`.

**dotnet test:** `^\s*[Ff]ail`, `^\s*[Pp]ass`, `Total:?\s+\d`

---

**Command generation rules:**

**`dotnet` CLI (applies to ALL generated commands):** run every command through the `dotnet` CLI (`dotnet test ...`, `dotnet build ...`) — never a bare binary path from a local tool directory.

- A tool installed as a local dotnet tool is invoked as `dotnet tool run {tool} ...`.
- When a source (README, docs) presents multiple equivalent forms for the same command, always select the `dotnet` form and discard the bare invocation.

---

## Application run detection

Build `# app-run-start` from what the project already declares — never from source code. Long-running processes are expected here; the no-watch-mode rule does not apply.

- **Runtime invocation:** `dotnet run --project <layer project>` — add a configuration flag only when the project's own docs do so
- **Port:** `Properties/launchSettings.json` (`applicationUrl`), `appsettings.json` (`Kestrel:Endpoints`), or the framework default — omit the URL argument when none is found
- **Multiple startable projects:** one layer per project; never chain them in one command

---

**Example output (for reference):**
```
Repository Discovery Report
Generated: [timestamp]

Detected Tools:
  SDK: .NET 8.0.x (from global.json)
  Build: dotnet CLI (*.csproj / *.sln)
  Test Framework: xUnit (xunit 2.9.x, xunit.runner.visualstudio)
  Static Analysis: .NET analyzers (All mode), StyleCop.Analyzers
  Formatters: dotnet-format, CSharpier
  Coverage: coverlet.collector

Suggested Commands:
  Test execution:
    # test-all
    dotnet test --verbosity quiet
    # test-path  (no coverage; --filter accepts class name or namespace)
    dotnet test --verbosity quiet --filter "FullyQualifiedName~MyClassTests" --no-build
    # test-path-coverage  (accepts class name or namespace; threshold from config)
    dotnet test --verbosity quiet --filter "FullyQualifiedName~MyClassTests" --collect:"XPlat Code Coverage" --no-build
    # test-all-coverage  (whole area; threshold from config)
    dotnet test --verbosity quiet --collect:"XPlat Code Coverage"

  ⚠️  --filter format:
      `--filter` matches against test metadata, NOT file paths.

      ✅ --filter "FullyQualifiedName~MyCompany.Feature.MyClassTests"
      ✅ --filter "Category=Unit"
      ❌ --filter "src/MyProject/Tests/MyClassTests.cs"

      To filter by namespace, use the `~` (contains) operator with the
      fully-qualified namespace: `FullyQualifiedName~MyCompany.Feature`.

  Static analysis:
    dotnet build /p:TreatWarningsAsErrors=true
    dotnet format --verify-no-changes

  Format:
    dotnet format
  Coverage:
    dotnet test --collect:"XPlat Code Coverage"

⚠️ VALIDATION CHECK:

Checking for REQUIRED tools:
  ✅ xUnit: Found (xunit in *.csproj)
  ✅ Static Analysis: Found (.editorconfig with analyzer rules)

OR (if missing):

⚠️ MISSING REQUIRED TOOLS:
  ❌ xUnit / NUnit / MSTest: NOT FOUND in project configuration
  ❌ Static Analysis: NOT FOUND (no Roslyn analyzer packages, no .editorconfig rules)

RECOMMENDATION:
  These tools are REQUIRED for the TDD workflow:

  1. xUnit (test execution) - Add to test *.csproj:
     <PackageReference Include="xunit" Version="2.9.*" />
     <PackageReference Include="xunit.runner.visualstudio" Version="2.8.*">
       <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
       <PrivateAssets>all</PrivateAssets>
     </PackageReference>
     <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.*" />

  2. Roslyn analyzers (static analysis) - Add to Directory.Build.props:
     <PropertyGroup>
       <AnalysisMode>All</AnalysisMode>
       <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
       <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
     </PropertyGroup>

After installing, the agent can re-scan to generate proper commands.
```
