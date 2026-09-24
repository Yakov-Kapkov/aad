# Repository Tool Discovery

**Copilot scans and discovers:**

1. **Build tool detection:**
   - Scan: `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`, `settings.gradle.kts`, `.mvn/`, `gradlew`, `gradlew.bat`
   - Report findings: "Found pom.xml → Project uses Maven"

2. **Test framework detection (REQUIRED: JUnit 5):**
   - Scan: `pom.xml` or `build.gradle` for `junit-jupiter`, `junit-jupiter-api`, `junit-jupiter-engine`, `junit-jupiter-params`
   - Check for test directories: `src/test/java/`
   - Check for test runner config: `surefire-plugin`, `maven-failsafe-plugin` in `pom.xml`; `test` task config in `build.gradle`
   - Report findings: "Found junit-jupiter 5.10.x → Project uses JUnit 5"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

3. **Static analysis detection (REQUIRED: one of SpotBugs / Checkstyle / Error Prone):**
   - Scan: `pom.xml` or `build.gradle` for `spotbugs`, `checkstyle`, `error-prone`, `pmd`
   - Check for config files: `checkstyle.xml`, `spotbugs-exclude.xml`, `pmd-ruleset.xml`
   - Report findings: "Configured: Checkstyle (google_checks), SpotBugs"
   - **If NOT found:** Flag as MISSING REQUIRED TOOL

4. **Formatter detection (OPTIONAL):**
   - Scan: `pom.xml` or `build.gradle` for `spotless`, `com.google.googlejavaformat:google-java-format`
   - Scan: `.editorconfig` for indentation settings
   - Report findings: "Formatters: Spotless (google-java-format)"
   - Classified in `### Format` section
   - Note: linting is handled by static analysis tools (section 3: Checkstyle, SpotBugs, PMD, Error Prone)

5. **Coverage tool detection (OPTIONAL):**
   - Scan: `pom.xml` or `build.gradle` for `jacoco-maven-plugin` or `jacoco` Gradle plugin
   - Scan: `pom.xml` or `build.gradle` for `sonar-maven-plugin`, `org.sonarqube` Gradle plugin
   - Report findings: "Coverage: JaCoCo (80% line coverage)", "Analysis: SonarQube detected"

6. **Coverage threshold detection (REQUIRED: always scan, may not exist):**
   - Scan: `pom.xml` for `jacoco-maven-plugin` with `<rule>` elements containing `<element>` and `<excludedRatios>` or `<limits>`
   - Also check: `build.gradle` for `jacocoTestCoverageVerification` task rules
   - Look for: threshold values for LINE, BRANCH, COMPLEXITY metrics
   - **If found**: Report findings (e.g., "JaCoCo: 80% (line coverage minimum per class)")
   - **If NOT found**: Report explicitly: "Coverage thresholds: Not configured — no threshold enforced"
   - **If found**: Include threshold value in coverage command examples as inline comments
   - **If NOT found**: Omit threshold comments entirely — never invent a default

7. **Project scripts:**
   - Scan: `pom.xml` profiles, `build.gradle` tasks, `Makefile`, `.github/workflows`, `scripts/`
   - Report findings: "Found Maven profiles: dev, test, prod; Gradle tasks: test, integrationTest, check"
   - Extract commands that wrap test/analysis if they exist

8. **Build command detection (derived from section 1):**
   - Maven (`pom.xml` present): `mvn package -DskipTests`
   - Gradle with wrapper (`gradlew` / `gradlew.bat` present): `./gradlew build -x test` (Unix) or `gradlew.bat build -x test` (Windows)
   - Gradle without wrapper: `gradle build -x test`
   - Prefer Gradle wrapper when present — ensures the correct Gradle version is used
   - Report findings: "Build: `./gradlew build -x test`" or "Build: `mvn package -DskipTests`"

---

## Test output filter patterns

Pieces joined with `|`. PS uses `$([char]0x...)` for symbols; bash uses literal.
sda-toolscan reads this to generate `filter-test-output` in `project-tools.md`.

**JUnit (mvn):** `Tests run:`, `BUILD`

---

**Example output (for reference):**
```
Repository Discovery Report
Generated: [timestamp]

Detected Tools:
  Build Tool: Maven (found pom.xml)
  Java: 21 (from pom.xml maven.compiler.release)
  Test Framework: JUnit 5 (junit-jupiter 5.10.x)
  Static Analysis: Checkstyle (google_checks.xml), SpotBugs
  Formatters: Spotless (google-java-format)
  Coverage: JaCoCo (80% line coverage)

Suggested Commands:
  Test execution:
    # test-all
    mvn test
    # test-path  (no coverage; accepts class name or package pattern e.g. "com.example.*")
    mvn test -Dtest=MyClassTest
    # test-path-coverage  (accepts class name or package pattern; threshold from config)
    mvn verify -Dtest=MyClassTest
    # test-all-coverage  (whole area; threshold from config — JaCoCo bound to verify)
    mvn verify
  
  Static analysis:
    mvn checkstyle:check
    mvn spotbugs:check
  
  Format check:
    mvn spotless:check
  Coverage:
    mvn jacoco:report

⚠️ VALIDATION CHECK:

Checking for REQUIRED tools:
  ✅ JUnit 5: Found (junit-jupiter in pom.xml)
  ✅ Static Analysis: Found (checkstyle-maven-plugin)

OR (if missing):

⚠️ MISSING REQUIRED TOOLS:
  ❌ JUnit 5: NOT FOUND in project configuration
  ❌ Static Analysis: NOT FOUND in project configuration

RECOMMENDATION:
  These tools are REQUIRED for the TDD workflow:
  
  1. JUnit 5 (test execution) - Add to pom.xml:
     <dependency>
       <groupId>org.junit.jupiter</groupId>
       <artifactId>junit-jupiter</artifactId>
       <version>5.10.2</version>
       <scope>test</scope>
     </dependency>

  2. Mockito (mocking) - Add to pom.xml:
     <dependency>
       <groupId>org.mockito</groupId>
       <artifactId>mockito-core</artifactId>
       <version>5.11.0</version>
       <scope>test</scope>
     </dependency>

  3. Checkstyle / SpotBugs (static analysis) - Add plugin to pom.xml

After installing, the agent can re-scan to generate proper commands.
```
