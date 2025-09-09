---
allowed-tools: Bash, Read, Write, Grep, Glob
---

# PM Plan MD

Generate a comprehensive linear action plan to resolve all project issues and write to PLAN.md. No milestones, no phases - just a complete list for the LLM to work through ALL issues without stopping. Do not add intyermediate hedings between tasks. Just a straight up list of tasks, ordered in priority order. We do not want an LLM to find reasons to pause, and units of work cause it to do so

## Usage
```
/pm:plan-md [--force] [--include-tests] [--include-e2e]
```

## Options
- `--force`: Overwrite existing PLAN.md without prompting
- `--include-tests`: Include test creation/improvement tasks
- `--include-e2e`: Include end-to-end testing tasks

## Planning Philosophy

**CRITICAL: LINEAR EXECUTION FOR LLM**
- No phases, milestones, or stopping points. So headings or brakdown between tasks
- Every task must be actionable and specific
- LLM must work through entire list without human intervention
- All linting, testing, and building must pass
- No shortcuts or "good enough" solutions

## Plan Generation Process

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

# Check for existing PLAN.md
if [[ -f "PLAN.md" ]] && [[ "$force_overwrite" != "true" ]]; then
    echo "⚠️ PLAN.md already exists"
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

# Start building the plan
plan_content="# COMPREHENSIVE PROJECT ACTION PLAN

**CRITICAL INSTRUCTIONS FOR LLM EXECUTION:**
- Work through ALL tasks in this list sequentially
- Do NOT stop at any point until ALL tasks are completed
- Do NOT create phases, milestones, or stopping points
- Fix ALL issues found - no shortcuts or \"good enough\" solutions
- ALL linting, testing, and building must pass with zero errors
- Verify each task is fully completed before moving to the next
- Update this file with ✅ as tasks are completed

**COMPLETION CRITERIA:**
- Zero lint errors across all projects
- Zero test failures across all projects  
- Zero build errors across all projects
- All applications start and run correctly
- All code follows quality standards (SOLID, DRY, KISS, etc.)
- All claims of functionality are verified with real execution

---

## LINEAR TASK EXECUTION LIST

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
   - Run linting command to verify fix
   - Ensure zero lint errors remain
   - Commit fix with clear message

"
        ((task_number++))
    done
fi

# Add test issues
if [[ ${#test_issues[@]} -gt 0 ]]; then
    plan_content+="
### TEST ISSUES (ZERO TOLERANCE)
"
    for issue in "${test_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **TEST:** $issue
   - Run full test suite to verify fix
   - Ensure all tests pass with meaningful assertions
   - Follow GIVEN-WHEN-THEN structure
   - Follow FIRST principles (Fast, Independent, Repeatable, Self-validating, Timely)
   - Commit fix with clear message

"
        ((task_number++))
    done
fi

# Add build issues
if [[ ${#build_issues[@]} -gt 0 ]]; then
    plan_content+="
### BUILD ISSUES (ZERO TOLERANCE)
"
    for issue in "${build_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **BUILD:** $issue
   - Run full build process to verify fix
   - Ensure build completes successfully with zero errors
   - Test that built artifacts work correctly
   - Commit fix with clear message

"
        ((task_number++))
    done
fi

# Add code quality issues
if [[ ${#code_quality_issues[@]} -gt 0 ]]; then
    plan_content+="
### CODE QUALITY ISSUES (SOLID, DRY, KISS, ROCO, POLA, YAGNI, CLEAN)
"
    for issue in "${code_quality_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **QUALITY:** $issue
   - Apply appropriate software engineering principles
   - Ensure code is maintainable and follows best practices
   - Run code review analysis to verify improvement
   - Commit refactoring with clear message

"
        ((task_number++))
    done
fi

# Add anti-cheat issues
if [[ ${#anti_cheat_issues[@]} -gt 0 ]]; then
    plan_content+="
### ANTI-CHEAT ISSUES (NO HARDCODED/FAKE IMPLEMENTATIONS)
"
    for issue in "${anti_cheat_issues[@]}"; do
        plan_content+="
${task_number}. [ ] **ANTI-CHEAT:** $issue
   - Replace with real, working implementation
   - Remove all hardcoded responses and fake logic
   - Ensure genuine functionality with proper algorithms
   - Run anti-cheat analysis to verify fix
   - Commit real implementation with clear message

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
   - Configure application to start and run correctly
   - Test actual application startup and functionality
   - Verify application responds to requests (if applicable)
   - Commit configuration with clear message

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
   - Follow GIVEN-WHEN-THEN structure
   - Use real assertions, not weak/tautological ones
   - Test edge cases and error conditions
   - Achieve minimum 80% code coverage

"
    ((task_number++))
    
    plan_content+="
${task_number}. [ ] **CREATE INTEGRATION TESTS:** Test component interactions
   - Test real data flows between components
   - Verify external dependencies work correctly
   - Test error handling and recovery scenarios

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
   - Setup appropriate E2E testing tools (Playwright, Cypress, etc.)
   - Configure test environment
   - Create basic E2E test structure

"
    ((task_number++))
    
    plan_content+="
${task_number}. [ ] **CREATE E2E TESTS:** Test complete user workflows
   - Test critical user journeys from start to finish
   - Verify real API calls and responses
   - Test against running application, not mocks
   - Ensure tests pass consistently

"
    ((task_number++))
fi

# Add final validation tasks
plan_content+="
### FINAL VALIDATION AND VERIFICATION
"

plan_content+="
${task_number}. [ ] **RUN FULL VALIDATION:** Execute comprehensive validation
   - Run /pm:validate --strict --e2e to verify all standards
   - Fix any remaining issues immediately
   - Ensure zero failures in all categories

"
((task_number++))

plan_content+="
${task_number}. [ ] **VERIFY REAL FUNCTIONALITY:** Test all claimed features work
   - Start applications and verify they run without errors
   - Make actual calls/requests to verify responses
   - Test error handling and edge cases
   - Confirm all functionality claims are accurate

"
((task_number++))

plan_content+="
${task_number}. [ ] **FINAL CODE REVIEW:** Run complete code quality analysis
   - Run /pm:code-review --strict on entire codebase
   - Run /pm:anti-cheat --strict on entire codebase
   - Address any remaining quality or anti-cheat issues
   - Ensure all code meets production standards

"
((task_number++))

plan_content+="
${task_number}. [ ] **DOCUMENTATION UPDATE:** Ensure all documentation is accurate
   - Update README with current functionality
   - Document any new features or changes
   - Ensure setup instructions are correct and complete
   - Verify all documented features actually work

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

*Generated by /pm:plan-md on $(date)*
"
```

### Step 5: Write Plan and Provide Instructions
```bash
echo ""
echo "📄 Writing comprehensive plan to PLAN.md..."

# Write the plan to file
echo "$plan_content" > PLAN.md

echo "✅ Plan written to PLAN.md"
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
echo "✅ The plan in PLAN.md is designed for LINEAR EXECUTION"
echo "✅ Work through EVERY task without stopping"
echo "✅ Do NOT create phases or milestones"
echo "✅ Fix ALL issues - no shortcuts allowed"
echo "✅ Mark tasks with ✅ as you complete them"
echo "✅ Run validation after completion to verify success"
echo ""
echo "🚀 START EXECUTION:"
echo "   1. Open PLAN.md"
echo "   2. Work through each task sequentially"
echo "   3. Mark completed tasks with ✅"
echo "   4. Do not stop until all tasks are ✅"
echo "   5. Run /pm:validate --strict --e2e as final verification"
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
    echo "Start working through PLAN.md immediately"
    echo "Do not stop until completion!"
fi
```

This plan generation command creates a comprehensive, linear task list that:

- **No phases or stopping points** - Pure linear execution for LLM
- **Captures all issues** - Linting, testing, building, quality, anti-cheat, runtime
- **Specific actionable tasks** - Each task is clear and measurable  
- **Zero tolerance approach** - ALL issues must be fixed, no shortcuts
- **Verification built-in** - Each task includes verification steps
- **Comprehensive coverage** - From code quality to real functionality testing
- **Linear progression** - Designed for LLM to execute without human intervention

The LLM can now work through the entire PLAN.md file systematically, ensuring every issue is resolved and every standard is met.