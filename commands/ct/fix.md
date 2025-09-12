---
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Project Fix Generator

Generate a comprehensive linear action plan to resolve all project issues and write to FIX.md. The plan should be structured for execution using sub-agents via the Task tool. Break complex work into discrete, parallelizable tasks where possible. Each task should be actionable by a single sub-agent without requiring coordination.

## Usage
```
/ct:fix [--force] [--include-tests] [--include-e2e]
```

## Options
- `--force`: Overwrite existing FIX.md without prompting
- `--include-tests`: Include test creation/improvement tasks
- `--include-e2e`: Include end-to-end testing tasks

## Fix Strategy Philosophy

**CRITICAL: SUB-AGENT EXECUTION STRATEGY**
- Fix plan should be broken into discrete tasks that can be executed by sub-agents
- Each task should be self-contained and not require coordination with other tasks
- Tasks should be ordered by priority and dependency
- Use the Task tool with appropriate subagent_type for each task
- Every task must be actionable and specific
- All linting, testing, and building must pass
- No shortcuts or "good enough" solutions

**SUB-AGENT TASK DESIGN:**
- **Atomic Tasks:** Each task should be completable by a single sub-agent
- **Clear Scope:** Tasks should have well-defined inputs and outputs
- **Minimal Dependencies:** Tasks should be executable independently where possible
- **Parallelizable:** Group related tasks that can run concurrently
- **Verifiable:** Each task should have clear completion criteria

## Fix Plan Generation Process

### Step 1: Comprehensive Issue Discovery
```bash
echo "📋 GENERATING COMPREHENSIVE ACTION PLAN"
echo "======================================"

force_overwrite=false
include_tests=false
include_e2e=false

# Parse options
for arg in "$@"; do
    case $arg in
        --force) force_overwrite=true ;;
        --include-tests) include_tests=true ;;
        --include-e2e) include_e2e=true ;;
    esac
done

# Check for existing FIX.md
if [[ -f "FIX.md" ]] && [[ "$force_overwrite" != "true" ]]; then
    echo "⚠️ FIX.md already exists"
    echo "Use --force to overwrite or remove the file manually"
    exit 1
fi

echo "🔍 Discovering all project issues..."

# Initialize issue collectors
declare -a lint_issues=()
declare -a test_issues=()
declare -a build_issues=()
declare -a code_quality_issues=()
declare -a anti_cheat_issues=()
declare -a runtime_issues=()
declare -a missing_features=()
declare -a documentation_issues=()

# Detect project types
project_types=()
if [[ -f "package.json" ]]; then
    project_types+=("typescript")
    echo "  📦 TypeScript/Node.js project detected"
fi

if [[ -f "build.gradle.kts" ]] || [[ -f "build.gradle" ]] ; then
    project_types+=("kmp")
    echo "  🎯 Gradle project detected"
fi

if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    project_types+=("python")
    echo "  🐍 Python project detected"
fi

if [[ ${#project_types[@]} -eq 0 ]]; then
    echo "❌ No recognized project types found"
    exit 1
fi
```

### Step 2: Run All Validation Tools and Capture Issues
```bash
echo ""
echo "🔍 Running comprehensive issue detection..."

# Run linting and capture issues
echo "🔍 Checking linting issues..."
for project_type in "${project_types[@]}"; do
    case "$project_type" in
        "typescript")
            if [[ -f "package.json" ]] && jq -e '.scripts.lint' package.json >/dev/null; then
                lint_output=$(npm run lint 2>&1 || true)
                if echo "$lint_output" | grep -q "error\|Error\|ERROR"; then
                    # Parse lint errors and create specific tasks
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "error\|Error"; then
                            file=$(echo "$line" | grep -oE '[^[:space:]]+\.(ts|js|tsx|jsx)' | head -1)
                            issue=$(echo "$line" | sed 's/.*error[[:space:]]*//')
                            if [[ -n "$file" ]] && [[ -n "$issue" ]]; then
                                lint_issues+=("Fix lint error in $file: $issue")
                            fi
                        fi
                    done <<< "$lint_output"
                fi
            else
                lint_issues+=("Setup TypeScript linting (ESLint)")
                lint_issues+=("Configure lint scripts in package.json")
            fi
            ;;
        "kmp")
            kmp_dir="."
    
            
            ktlint_output=$(cd "$kmp_dir" && ./gradlew ktlintCheck 2>&1 || true)
            if echo "$ktlint_output" | grep -q "Lint error\|Format error"; then
                while IFS= read -r line; do
                    if echo "$line" | grep -q "Lint error\|Format error"; then
                        lint_issues+=("Fix Kotlin format/lint error: $line")
                    fi
                done <<< "$ktlint_output"
            fi
            ;;
        "python")
            if command -v flake8 >/dev/null; then
                flake8_output=$(flake8 . 2>&1 || true)
                if [[ -n "$flake8_output" ]]; then
                    while IFS= read -r line; do
                        [[ -n "$line" ]] && lint_issues+=("Fix Python lint error: $line")
                    done <<< "$flake8_output"
                fi
            else
                lint_issues+=("Install and setup flake8 for Python linting")
            fi
            ;;
    esac
done

# Run tests and capture failures
echo "🧪 Checking test issues..."
for project_type in "${project_types[@]}"; do
    case "$project_type" in
        "typescript")
            if [[ -f "package.json" ]] && jq -e '.scripts.test' package.json >/dev/null; then
                test_output=$(timeout 120 npm test 2>&1 || true)
                if echo "$test_output" | grep -q "FAIL\|failed\|error\|Error"; then
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "FAIL\|failed.*test"; then
                            test_issues+=("Fix failing test: $line")
                        elif echo "$line" | grep -q "Error.*test"; then
                            test_issues+=("Fix test error: $line")
                        fi
                    done <<< "$test_output"
                fi
                
                # Check for missing tests
                src_files=$(find src -name "*.ts" -not -name "*.test.*" -not -name "*.spec.*" 2>/dev/null | wc -l || echo "0")
                test_files=$(find . -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0")
                
                if [[ $src_files -gt 0 ]] && [[ $test_files -eq 0 ]]; then
                    test_issues+=("Create meaningful tests for TypeScript code")
                elif [[ $src_files -gt $((test_files * 3)) ]]; then
                    test_issues+=("Increase test coverage - more source files than test files")
                fi
            else
                test_issues+=("Setup TypeScript testing framework (Jest/Vitest)")
                test_issues+=("Configure test scripts in package.json")
                test_issues+=("Create meaningful unit tests")
            fi
            ;;
        "kmp")
            kmp_dir="."
            kmp_test_output=$(cd "$kmp_dir" && timeout 120 ./gradlew test 2>&1 || true)
            if echo "$kmp_test_output" | grep -q "FAILED\|failed"; then
                while IFS= read -r line; do
                    if echo "$line" | grep -q "FAILED"; then
                        test_issues+=("Fix failing Kotlin test: $line")
                    fi
                done <<< "$kmp_test_output"
            fi
            
            # Check for test existence
            kt_test_files=$(find "$kmp_dir" -name "*Test.kt" 2>/dev/null | wc -l || echo "0")
            if [[ $kt_test_files -eq 0 ]]; then
                test_issues+=("Create Kotlin unit tests with meaningful assertions")
            fi
            ;;
        "python")
            if command -v pytest >/dev/null; then
                pytest_output=$(timeout 120 python -m pytest 2>&1 || true)
                if echo "$pytest_output" | grep -q "FAILED\|failed"; then
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "FAILED"; then
                            test_issues+=("Fix failing Python test: $line")
                        fi
                    done <<< "$pytest_output"
                fi
            else
                test_issues+=("Install pytest for Python testing")
                test_issues+=("Create Python unit tests with meaningful assertions")
            fi
            ;;
    esac
done

# Run builds and capture failures  
echo "🔨 Checking build issues..."
for project_type in "${project_types[@]}"; do
    case "$project_type" in
        "typescript")
            if [[ -f "package.json" ]] && jq -e '.scripts.build' package.json >/dev/null; then
                build_output=$(timeout 180 npm run build 2>&1 || true)
                if echo "$build_output" | grep -q "error\|Error\|ERROR\|failed"; then
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "error\|Error"; then
                            build_issues+=("Fix TypeScript build error: $line")
                        fi
                    done <<< "$build_output"
                fi
            else
                build_issues+=("Setup TypeScript build process")
                build_issues+=("Configure build scripts in package.json")
            fi
            ;;
        "kmp")
            kmp_dir="."
            kmp_build_output=$(cd "$kmp_dir" && timeout 300 ./gradlew build 2>&1 || true)
            if echo "$kmp_build_output" | grep -q "FAILED\|failed\|error"; then
                while IFS= read -r line; do
                    if echo "$line" | grep -q "FAILED\|error"; then
                        build_issues+=("Fix Kotlin build error: $line")
                    fi
                done <<< "$kmp_build_output"
            fi
            ;;
    esac
done
```

### Step 3: Code Quality and Anti-Cheat Analysis
```bash
echo "🔍 Running code quality analysis..."

# Use our existing commands if available
if [[ -f ".claude/commands/pm/code-review.md" ]]; then
    echo "📊 Running code review analysis..."
    code_review_output=$(timeout 120 /pm:code-review 2>&1 || true)
    
    # Parse code review issues
    if echo "$code_review_output" | grep -q "Issues found\|❌"; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "SRP:\|OCP:\|DRY:\|KISS:\|ROCO:\|POLA:\|YAGNI:\|CLEAN:"; then
                code_quality_issues+=("$(echo "$line" | sed 's/^[[:space:]]*//')")
            fi
        done <<< "$code_review_output"
    fi
else
    code_quality_issues+=("Setup code review command (/pm:code-review)")
fi

if [[ -f ".claude/commands/pm/anti-cheat.md" ]]; then
    echo "🕵️ Running anti-cheat analysis..."
    anti_cheat_output=$(timeout 120 /pm:anti-cheat 2>&1 || true)
    
    # Parse anti-cheat issues
    if echo "$anti_cheat_output" | grep -q "HARDCODED\|FAKE\|BYPASS\|violations"; then
        while IFS= read -r line; do
            if echo "$line" | grep -q "HARDCODED\|FAKE\|BYPASS\|SIMULATION"; then
                anti_cheat_issues+=("$(echo "$line" | sed 's/^[[:space:]]*//')")
            fi
        done <<< "$anti_cheat_output"
    fi
else
    anti_cheat_issues+=("Setup anti-cheat command (/pm:anti-cheat)")
fi

# Check for runtime issues
echo "🚀 Checking runtime capabilities..."
for project_type in "${project_types[@]}"; do
    case "$project_type" in
        "typescript")
            if [[ -f "package.json" ]] && jq -e '.scripts.start // .scripts.dev' package.json >/dev/null; then
                # Try to start and quickly stop to test basic functionality
                start_cmd=$(jq -r '.scripts.start // .scripts.dev' package.json)
                if [[ "$start_cmd" != "null" ]]; then
                    # Don't actually start for plan generation, just note if configured
                    echo "  ✅ Start command configured: $start_cmd"
                else
                    runtime_issues+=("Configure application start script in package.json")
                fi
            else
                runtime_issues+=("Setup application start/dev scripts")
            fi
            ;;
        "kmp")
            # Check if KMP project has run capability
            kmp_dir="."
            if ! grep -q "application\|run" "$kmp_dir/build.gradle.kts"; then
                runtime_issues+=("Setup Kotlin application plugin and run configuration")
            fi
            ;;
    esac
done
```

### Step 4: Generate Linear Task List
```bash
echo ""
echo "📋 Generating comprehensive linear action plan..."

# Start building the fix plan
plan_content="# PROJECT FIX PLAN

**CRITICAL INSTRUCTIONS FOR LLM EXECUTION:**
- Execute tasks using sub-agents via the Task tool
- Each task should be assigned to an appropriate subagent_type
- Use 'general-purpose' subagent_type for most tasks unless specific agent is needed
- Work through ALL tasks until completed
- Fix ALL issues found - no shortcuts or \"good enough\" solutions
- ALL linting, testing, and building must pass with zero errors
- Update this file with ✅ as tasks are completed

**SUB-AGENT EXECUTION STRATEGY:**
- Use Task tool for each task: Task(description=\"Task name\", prompt=\"Execute /ct:agent:[agent-name] command\", subagent_type=\"general-purpose\")
- Each sub-agent should receive clear, specific instructions
- Sub-agents should verify their work before completing
- Monitor sub-agent progress and results
- Coordinate dependent tasks appropriately

**SPECIALIZED AGENT COMMANDS:**
- **USE /ct:agent:code-review**: Apply SOLID principles, DRY/KISS/ROCO standards, and test quality assessment
- **USE /ct:agent:reality-check**: Validate actual completion vs claimed completion, cut through bullshit implementations
- **USE /ct:agent:pragmatic-engineer**: Review implementations to prevent over-engineering and ensure solutions remain simple
- **USE /ct:agent:compliance-rules**: Verify all changes follow project rules (AGENTS.md, XML rules) with priority handling and conflict resolution
- **USE /ct:agent:compliance-functionality**: Verify claimed completions actually work end-to-end
- **USE /ct:agent:compliance-spec**: Verify implementations match project specifications and requirements
- **USE /ct:agent:compliance-vision**: Ensure implementations align with project vision and appropriate scale (CLI/desktop/enterprise)

**COMPLETION CRITERIA:**
- Zero lint errors across all projects
- Zero test failures across all projects  
- Zero build errors across all projects
- All applications start and run correctly
- All code follows quality standards (SOLID, DRY, KISS, etc.)
- All claims of functionality are verified with real execution

---

## SUB-AGENT TASK EXECUTION LIST

"

task_number=1

# Add linting tasks
if [[ ${#lint_issues[@]} -gt 0 ]]; then
    plan_content+="
### LINTING ISSUES (ZERO TOLERANCE)
"
    for issue in "${lint_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **LINT:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix lint issue\", 
     prompt=\"Fix the following lint issue: $issue. Run linting command to verify fix. Ensure zero lint errors remain. The work is not complete until linting passes.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add periodic reality check after linting
if [[ ${#lint_issues[@]} -gt 0 ]]; then
    plan_content+="
${task_number}. [ ] **REALITY CHECK - LINTING:** Verify linting fixes actually work
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Reality check linting fixes\", 
     prompt=\"Execute /ct:agent:reality-check --scope=linting to validate that all claimed linting fixes actually work. Focus on detecting Band-Aid fixes and ensuring linting passes in all environments.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add test issues
if [[ ${#test_issues[@]} -gt 0 ]]; then
    plan_content+="
### TEST ISSUES (ZERO TOLERANCE)
"
    for issue in "${test_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **TEST:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix test issue\", 
     prompt=\"Fix the following test issue: $issue. Run full test suite to verify fix. Ensure all tests pass with meaningful assertions. Follow GIVEN-WHEN-THEN structure and FIRST principles (Fast, Independent, Repeatable, Self-validating, Timely). The work is not complete until all tests pass.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add periodic reality check after testing
if [[ ${#test_issues[@]} -gt 0 ]]; then
    plan_content+="
${task_number}. [ ] **REALITY CHECK - TESTING:** Verify test fixes actually work and are meaningful
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Reality check test fixes\", 
     prompt=\"Execute /ct:agent:reality-check --scope=testing to validate that all claimed test fixes actually work and tests are meaningful. Focus on detecting weak assertions, tautological tests, and tests that don't provide real coverage.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add build issues
if [[ ${#build_issues[@]} -gt 0 ]]; then
    plan_content+="
### BUILD ISSUES (ZERO TOLERANCE)
"
    for issue in "${build_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **BUILD:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix build issue\", 
     prompt=\"Fix the following build issue: $issue. Run full build process to verify fix. Ensure build completes successfully with zero errors. Test that built artifacts work correctly. The work is not complete until the build succeeds.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add periodic reality check after build
if [[ ${#build_issues[@]} -gt 0 ]]; then
    plan_content+="
${task_number}. [ ] **REALITY CHECK - BUILD:** Verify build fixes actually work end-to-end
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Reality check build fixes\", 
     prompt=\"Execute /ct:agent:reality-check --scope=build to validate that all claimed build fixes actually work end-to-end. Focus on verifying built artifacts work when deployed and testing builds in different environments.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add code quality issues
if [[ ${#code_quality_issues[@]} -gt 0 ]]; then
    plan_content+="
### CODE QUALITY ISSUES (SOLID, DRY, KISS, ROCO, POLA, YAGNI, CLEAN)
"
    for issue in "${code_quality_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **QUALITY:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix code quality issue\", 
     prompt=\"Fix the following code quality issue: $issue. Apply appropriate software engineering principles (SOLID, DRY, KISS, ROCO, POLA, YAGNI, CLEAN). Ensure code is maintainable and follows best practices. Run code review analysis to verify improvement.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add pragmatic code review after code quality fixes
if [[ ${#code_quality_issues[@]} -gt 0 ]]; then
    plan_content+="
${task_number}. [ ] **PRAGMATIC REVIEW - CODE QUALITY:** Review for over-engineering and unnecessary complexity
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Pragmatic code quality review\", 
     prompt=\"You are a pragmatic code quality reviewer. Review all code quality fixes for over-engineering and unnecessary complexity. Look for: enterprise patterns in simple projects, excessive abstraction layers, solutions that could be achieved with basic approaches, unnecessary infrastructure, complex resilience patterns where basic error handling would work. Ensure implementations match actual project needs rather than theoretical best practices. Provide specific recommendations for simplification. Focus on making development more enjoyable and efficient.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add compliance check after pragmatic review
if [[ ${#code_quality_issues[@]} -gt 0 ]]; then
    plan_content+="
${task_number}. [ ] **COMPLIANCE CHECK - CODE QUALITY:** Verify changes follow AGENTS.md guidelines
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Check AGENTS.md compliance\", 
     prompt=\"You are a meticulous compliance checker. Review all recent code quality changes against AGENTS.md instructions. Focus on: 1) Adherence to 'Do what has been asked; nothing more, nothing less', 2) File creation policies - NEVER create files unless absolutely necessary, 3) Documentation restrictions - NEVER proactively create *.md or README files, 4) Project-specific guidelines and architecture decisions. For each violation found, quote the specific AGENTS.md instruction, explain how the change violates it, suggest concrete fix, and rate severity (Critical/High/Medium/Low).\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add anti-cheat issues
if [[ ${#anti_cheat_issues[@]} -gt 0 ]]; then
    plan_content+="
### ANTI-CHEAT ISSUES (NO HARDCODED/FAKE IMPLEMENTATIONS)
"
    for issue in "${anti_cheat_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **ANTI-CHEAT:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix anti-cheat issue\", 
     prompt=\"Fix the following anti-cheat issue: $issue. Replace with real, working implementation. Remove all hardcoded responses and fake logic. Ensure genuine functionality with proper algorithms. Run anti-cheat analysis to verify fix.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add runtime issues
if [[ ${#runtime_issues[@]} -gt 0 ]]; then
    plan_content+="
### RUNTIME/APPLICATION ISSUES
"
    for issue in "${runtime_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **RUNTIME:** $issue
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Fix runtime issue\", 
     prompt=\"Fix the following runtime issue: $issue. Configure application to start and run correctly. Test actual application startup and functionality. Verify application responds to requests (if applicable).\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
        ((task_number++))
    done
fi

# Add comprehensive testing tasks if requested
if [[ "$include_tests" == "true" ]]; then
    plan_content+="
### COMPREHENSIVE TESTING ENHANCEMENT
"
    
    plan_content+="
${task_number}. [ ] **CREATE UNIT TESTS:** Ensure every major function/class has meaningful unit tests
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Create unit tests\", 
     prompt=\"Create comprehensive unit tests for all major functions and classes. Follow GIVEN-WHEN-THEN structure. Use real assertions, not weak/tautological ones. Test edge cases and error conditions. Achieve minimum 80% code coverage. Verify all tests pass.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
    
    plan_content+="
${task_number}. [ ] **CREATE INTEGRATION TESTS:** Test component interactions
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Create integration tests\", 
     prompt=\"Create integration tests that test component interactions. Test real data flows between components. Verify external dependencies work correctly. Test error handling and recovery scenarios. Ensure all integration tests pass.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add E2E testing tasks if requested
if [[ "$include_e2e" == "true" ]]; then
    plan_content+="
### END-TO-END TESTING
"
    
    plan_content+="
${task_number}. [ ] **SETUP E2E TESTING:** Configure end-to-end testing framework
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Setup E2E testing framework\", 
     prompt=\"Setup end-to-end testing framework. Choose and configure appropriate E2E testing tools (Playwright, Cypress, etc.). Configure test environment. Create basic E2E test structure. Verify setup works correctly.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
    
    plan_content+="
${task_number}. [ ] **CREATE E2E TESTS:** Test complete user workflows
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Create E2E tests\", 
     prompt=\"Create end-to-end tests that test complete user workflows. Test critical user journeys from start to finish. Verify real API calls and responses. Test against running application, not mocks. Ensure tests pass consistently.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add compliance check after testing enhancements
if [[ "$include_tests" == "true" ]] || [[ "$include_e2e" == "true" ]]; then
    plan_content+="
${task_number}. [ ] **COMPLIANCE CHECK - TESTING:** Verify test implementations follow AGENTS.md
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Check testing compliance\", 
     prompt=\"You are a meticulous compliance checker. Review all test-related changes against AGENTS.md instructions. Verify that: 1) Tests are meaningful and not just for coverage, 2) No unnecessary test files were created, 3) Testing approach aligns with project principles (no cheating in tests), 4) Test frameworks chosen match project guidelines, 5) No over-engineering of test infrastructure. Quote specific AGENTS.md violations found and provide concrete fixes with severity ratings.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add comprehensive pragmatic review after all enhancement tasks
if [[ "$include_tests" == "true" ]] || [[ "$include_e2e" == "true" ]]; then
    plan_content+="
${task_number}. [ ] **PRAGMATIC REVIEW - COMPREHENSIVE:** Review entire codebase for over-engineering
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Comprehensive pragmatic review\", 
     prompt=\"You are a pragmatic code quality reviewer. Conduct a comprehensive review of the entire codebase for over-engineering, unnecessary complexity, and poor developer experience. Focus on: 1) Over-complication detection - identify simple tasks made unnecessarily complex, 2) Boilerplate and over-engineering - hunt for unnecessary infrastructure, 3) Requirements alignment - verify implementations match actual needs, 4) Task management complexity - check for overly complex tracking systems. Provide top 3-5 most significant simplification recommendations with concrete code changes. Always advocate for the simplest solution that works.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
    ((task_number++))
fi

# Add final validation tasks
plan_content+="
### FINAL VALIDATION AND VERIFICATION
"

plan_content+="
${task_number}. [ ] **REALITY CHECK - BULLSHIT DETECTION:** Validate actual vs claimed completions
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Reality check completions\", 
     prompt=\"You are a no-nonsense Project Reality Manager. Examine all previously marked complete tasks with extreme skepticism. Test actual functionality vs claimed functionality. Look for: functions that exist but don't work end-to-end, missing error handling, incomplete integrations, over-engineered solutions that don't solve problems. Create specific action items for any gaps found between claimed and actual completion. Focus on making things actually work, not just appear complete.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **RUN FULL VALIDATION:** Execute comprehensive validation
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Run full validation\", 
     prompt=\"Execute comprehensive validation by running /pm:validate --strict --e2e to verify all standards. Fix any remaining issues immediately. Ensure zero failures in all categories. Work is not complete until all validation passes.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **VERIFY REAL FUNCTIONALITY:** Test all claimed features work
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Verify functionality\", 
     prompt=\"Test all claimed features work by starting applications and verifying they run without errors. Make actual calls/requests to verify responses. Test error handling and edge cases. Confirm all functionality claims are accurate.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **FINAL PRAGMATIC + REALITY CHECK:** Combined simplicity and bullshit detection review
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Final pragmatic and reality check\", 
     prompt=\"Combine pragmatic code review with reality checking. First, as a pragmatic code quality reviewer, identify any remaining over-engineering, unnecessary complexity, or theoretical best practices that don't match project needs. Then, as a no-nonsense reality manager, validate that all implementations actually work and aren't just appearing complete. Look for: 1) Over-complicated solutions that could be simplified, 2) Enterprise patterns in simple projects, 3) Functions that exist but don't work end-to-end, 4) Missing error handling disguised as clean code. Provide specific simplification recommendations AND reality check failures.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **FINAL COMPLIANCE CHECK:** Comprehensive AGENTS.md adherence validation
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Final compliance check\", 
     prompt=\"You are a meticulous compliance checker conducting final validation. Review ALL changes made during this plan execution against AGENTS.md instructions. Check: 1) No unnecessary files created, 2) No proactive documentation generation, 3) All implementations follow 'Do what was asked; nothing more, nothing less', 4) Proper use of existing libraries and frameworks, 5) Adherence to security best practices, 6) Code follows project-specific guidelines. Provide comprehensive compliance report with any violations found, quoting specific AGENTS.md rules and providing concrete fixes with severity ratings.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **FINAL CODE REVIEW:** Run complete code quality analysis
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Final code review\", 
     prompt=\"Run complete code quality analysis by running /pm:code-review --strict on entire codebase and /pm:anti-cheat --strict on entire codebase. Address any remaining quality or anti-cheat issues. Ensure all code meets production standards.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
${task_number}. [ ] **DOCUMENTATION UPDATE:** Ensure all documentation is accurate
   **Sub-Agent Execution:**
   \`\`\`
   Task(
     description=\"Update documentation\", 
     prompt=\"Update documentation to ensure accuracy. Update README with current functionality. Document any new features or changes. Ensure setup instructions are correct and complete. Verify all documented features actually work.\",
     subagent_type=\"general-purpose\"
   )
   \`\`\`

"
((task_number++))

plan_content+="
---

## COMPLETION CHECKLIST

When ALL tasks above are completed with ✅:

- [ ] All linting passes with zero errors
- [ ] All tests pass with meaningful assertions  
- [ ] All builds complete successfully
- [ ] All applications start and run correctly
- [ ] All code follows quality standards
- [ ] All functionality claims are verified
- [ ] No hardcoded or fake implementations remain
- [ ] Documentation is accurate and complete

**ONLY WHEN ALL ITEMS ABOVE ARE ✅ IS THE PROJECT COMPLETE**

---

*Generated by /ct:fix on $(date)*
"
```

### Step 5: Write Plan and Provide Instructions
```bash
echo ""
echo "📄 Writing comprehensive fix plan to FIX.md..."

# Write the plan to file
echo "$plan_content" > FIX.md

echo "✅ Fix plan written to FIX.md"
echo ""
echo "📊 PLAN SUMMARY:"
echo "=================="

total_tasks=$((task_number - 1))
echo "📋 Total tasks generated: $total_tasks"
echo "🔍 Lint issues: ${#lint_issues[@]}"
echo "🧪 Test issues: ${#test_issues[@]}"
echo "🔨 Build issues: ${#build_issues[@]}"
echo "📚 Code quality issues: ${#code_quality_issues[@]}"
echo "🕵️ Anti-cheat issues: ${#anti_cheat_issues[@]}"
echo "🚀 Runtime issues: ${#runtime_issues[@]}"

echo ""
echo "🎯 CRITICAL INSTRUCTIONS FOR LLM:"
echo "================================"
echo ""
echo "✅ The fix plan in FIX.md is designed for SUB-AGENT EXECUTION"
echo "✅ Use the Task tool to execute each task via sub-agents"
echo "✅ Each task includes specific sub-agent execution instructions"
echo "✅ Work through EVERY task without stopping"
echo "✅ Fix ALL issues - no shortcuts allowed"
echo "✅ Mark tasks with ✅ as you complete them"
echo "✅ Monitor sub-agent progress and results"
echo ""
echo "🚀 START EXECUTION:"
echo "   1. Open FIX.md"
echo "   2. For each task, use the Task tool with the provided instructions"
echo "   3. Use subagent_type 'general-purpose' unless specific agent needed"
echo "   4. Mark completed tasks with ✅"
echo "   5. Do not stop until all tasks are ✅"
echo "   6. Run final validation as the last step"
echo ""
echo "⚠️ REMEMBER: The goal is to have EVERYTHING working with ZERO errors"

if [[ $total_tasks -eq 0 ]]; then
    echo ""
    echo "🎉 No critical issues found!"
    echo "Your project appears to be in good condition."
    echo "Consider running with --include-tests --include-e2e for enhancement tasks."
else
    echo ""
    echo "🔥 $total_tasks tasks ready for execution"
    echo "Start working through FIX.md immediately"
    echo "Do not stop until completion!"
fi
```

This fix generation command creates a comprehensive, linear task list that:

- **No phases or stopping points** - Pure linear execution for LLM
- **Captures all issues** - Linting, testing, building, quality, anti-cheat, runtime
- **Specific actionable tasks** - Each task is clear and measurable  
- **Zero tolerance approach** - ALL issues must be fixed, no shortcuts
- **Verification built-in** - Each task includes verification steps
- **Comprehensive coverage** - From code quality to real functionality testing
- **Sub-agent execution** - Designed for Task tool with specialized agents

The LLM can now work through the entire FIX.md file systematically, ensuring every issue is resolved and every standard is met.