# Tool Catalog — C#

Default and alternative tools per required category for C# projects.
Priority 1 = recommended default; 2 = alternative. Read by `sda-setup` (Step 7) and `sda-tool-installer`.

| Category | Tool | Priority | Install command | Hook command | Init command | Check command | Description |
|---|---|---|---|---|---|---|---|
| Test runner | xunit | 1 | `dotnet add package xunit` | `dotnet test` | | | Modern extensible test framework; recommended for .NET |
| Test runner | nunit | 2 | `dotnet add package NUnit` | `dotnet test` | | | Mature test framework with rich assertions |
| Test runner | mstest | 2 | `dotnet add package MSTest.TestFramework` | `dotnet test` | | | Microsoft's built-in test framework |
| Code formatter | dotnet-format | 1 | `dotnet tool install -g dotnet-format` | `dotnet format` | | `dotnet format --version` | Official .NET formatter and code-style enforcer |
| Code formatter | csharpier | 2 | `dotnet tool install -g csharpier` | `dotnet csharpier .` | | `dotnet csharpier --version` | Opinionated formatter for C#; faster and stricter than dotnet-format |
| Coverage | coverlet | 1 | `dotnet add package coverlet.collector` | | | | Cross-platform code coverage for .NET |
| Git hooks | husky.net | 1 | `dotnet tool install husky` | | `dotnet husky install` | | Git hooks manager for .NET projects |
| Git hooks | pre-commit | 2 | `pip install pre-commit` | | `pre-commit install` | `pre-commit --version` | Cross-language Git hooks framework |
| Data format validators | jq + yamllint + xmllint | 1 | See OS-specific commands below | | | | Validators for JSON, YAML, and XML files |

## OS-specific commands for data format validators

| OS | jq | xmllint | yamllint |
|---|---|---|---|
| Windows | `choco install jq` | `choco install xsltproc` | `pip install yamllint` |
| macOS | `brew install jq` | `brew install libxml2` | `pip install yamllint` |
| Linux | `apt install jq` | `apt install libxml2-utils` | `pip install yamllint` |
