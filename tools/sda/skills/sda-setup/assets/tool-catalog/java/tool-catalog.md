# Tool Catalog — Java

Default and alternative tools per required category for Java projects.
Priority 1 = recommended default; 2 = alternative. Read by `sda-setup` (Step 7) and `sda-tool-installer`.

| Category | Tool | Priority | Install command | Hook command | Init command | Check command | Description |
|---|---|---|---|---|---|---|---|
| Test runner | JUnit 5 | 1 | Add `org.junit.jupiter:junit-jupiter` to pom.xml / build.gradle | `mvn test` | | | The standard Java test framework |
| Linter | Checkstyle | 1 | Add `maven-checkstyle-plugin` to pom.xml | `mvn checkstyle:check` | | | Static analysis for code style enforcement |
| Code formatter | google-java-format | 1 | Add `fmt-maven-plugin` to pom.xml | `mvn fmt:check` | | | Opinionated formatter following Google's Java style |
| Coverage | JaCoCo | 1 | Add `jacoco-maven-plugin` to pom.xml | | | | Standard Java code coverage library |
| Git hooks | pre-commit | 1 | `pip install pre-commit` | | `pre-commit install` | `pre-commit --version` | Cross-language Git hooks framework |
| Data format validators | jq + yamllint + xmllint | 1 | See OS-specific commands below | | | | Validators for JSON, YAML, and XML files |

## OS-specific commands for data format validators

| OS | jq | xmllint | yamllint |
|---|---|---|---|
| Windows | `choco install jq` | `choco install xsltproc` | `pip install yamllint` |
| macOS | `brew install jq` | `brew install libxml2` | `pip install yamllint` |
| Linux | `apt install jq` | `apt install libxml2-utils` | `pip install yamllint` |
