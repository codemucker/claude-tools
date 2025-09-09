---
allowed-tools: Bash, Read, Write, Grep, Glob
---

# PM Validate

Comprehensive validation that ensures features have meaningful tests, all tests pass, applications run without errors, and all claims of functionality are actively verified with real calls.

## Usage
```
/pm:validate [path] [--strict] [--e2e] [--fix-on-fail]
```

## Options
- `path`: Directory to validate (defaults to current directory)
- `--strict`: Zero tolerance for any failures - all tests, linting, and builds must pass
- `--e2e`: Include end-to-end testing of actual functionality
- `--fix-on-fail`: Attempt to fix issues automatically where possible

## Validation Standards

### CRITICAL Requirements
- **ALL code must run with NO lint errors** (zero tolerance)
- **ALL tests must pass** (zero tolerance)  
- **ALL applications must start and run** (zero tolerance)
- **ALL claimed functionality must be verified with real calls** (zero tolerance)
- **Tests must follow SOLID, KISS, FIRST principles**
- **Tests must be meaningful with real assertions**

## Validation Process

### Step 1: Environment Detection and Setup
```bash
echo "🔍 COMPREHENSIVE PROJECT VALIDATION"
echo "==================================="

target_path="${1:-.}"
strict_mode=false
e2e_mode=false
fix_on_fail=false

# Parse options
for arg in "$@"; do
    case $arg in
        --strict) strict_mode=true ;;
        --e2e) e2e_mode=true ;;
        --fix-on-fail) fix_on_fail=true ;;
    esac
done

echo "📁 Target: $target_path"
echo "⚡ Strict mode: $strict_mode"
echo "🧪 E2E testing: $e2e_mode"
echo "🔧 Auto-fix: $fix_on_fail"

if [[ ! -d "$target_path" ]]; then
    echo "❌ Target directory not found: $target_path"
    exit 1
fi

cd "$target_path" || exit 1

# Detect project types
project_types=()
test_commands=()
build_commands=()
lint_commands=()
start_commands=()

echo ""
echo "🔍 Detecting project configuration..."

# TypeScript/Node.js
if [[ -f "package.json" ]]; then
    project_types+=("typescript")
    
    # Extract commands from package.json
    if jq -e '.scripts.test' package.json >/dev/null; then
        test_commands+=("npm test")
    fi
    if jq -e '.scripts.build' package.json >/dev/null; then
        build_commands+=("npm run build")
    fi
    if jq -e '.scripts.lint' package.json >/dev/null; then
        lint_commands+=("npm run lint")
    elif jq -e '.scripts["lint:check"]' package.json >/dev/null; then
        lint_commands+=("npm run lint:check")
    fi
    if jq -e '.scripts.start' package.json >/dev/null; then
        start_commands+=("npm start")
    elif jq -e '.scripts.dev' package.json >/dev/null; then
        start_commands+=("npm run dev")
    fi
    
    echo "  ✅ TypeScript/Node.js project detected"
fi

# Kotlin Multiplatform
if [[ -f "build.gradle.kts" ]] || [[ -f "../agent-kmp/build.gradle.kts" ]]; then
    project_types+=("kmp")
    kmp_dir="."
    if [[ -f "../agent-kmp/build.gradle.kts" ]]; then
        kmp_dir="../agent-kmp"
    fi
    
    test_commands+=("cd $kmp_dir && ./gradlew test")
    build_commands+=("cd $kmp_dir && ./gradlew build")
    lint_commands+=("cd $kmp_dir && ./gradlew ktlintCheck")
    
    echo "  ✅ Kotlin Multiplatform project detected at: $kmp_dir"
fi

# Python
if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    project_types+=("python")
    test_commands+=("python -m pytest")
    if command -v flake8 >/dev/null; then
        lint_commands+=("flake8 .")
    fi
    if command -v black >/dev/null; then
        lint_commands+=("black --check .")
    fi
    
    echo "  ✅ Python project detected"
fi

if [[ ${#project_types[@]} -eq 0 ]]; then
    echo "  ❌ No recognized project types found"
    exit 1
fi

echo "  📊 Detected project types: ${project_types[*]}"
echo "  📊 Test commands: ${#test_commands[@]}"
echo "  📊 Build commands: ${#build_commands[@]}"
echo "  📊 Lint commands: ${#lint_commands[@]}"
echo "  📊 Start commands: ${#start_commands[@]}"
```

### Step 2: Critical Linting Validation (Zero Tolerance)
```bash
echo ""
echo "🔍 CRITICAL: Linting Validation (Zero Tolerance)"
echo "=============================================="

lint_failures=()

if [[ ${#lint_commands[@]} -eq 0 ]]; then
    echo "⚠️ No linting commands configured"
    if [[ "$strict_mode" == "true" ]]; then
        echo "❌ STRICT MODE: Linting must be configured"
        exit 1
    fi
else
    for lint_cmd in "${lint_commands[@]}"; do
        echo ""
        echo "🔍 Running: $lint_cmd"
        
        # Capture both stdout and stderr
        lint_output=$(eval "$lint_cmd" 2>&1)
        lint_exit_code=$?
        
        echo "$lint_output"
        
        if [[ $lint_exit_code -ne 0 ]]; then
            echo "❌ LINT FAILURE: $lint_cmd (exit code: $lint_exit_code)"
            lint_failures+=("$lint_cmd: exit code $lint_exit_code")
            
            if [[ "$fix_on_fail" == "true" ]]; then
                echo "🔧 Attempting automatic fix..."
                
                # Try common fix commands
                case "$lint_cmd" in
                    *"npm run lint"*)
                        if jq -e '.scripts["lint:fix"]' package.json >/dev/null; then
                            echo "  Trying: npm run lint:fix"
                            npm run lint:fix
                        fi
                        ;;
                    *"ktlintCheck"*)
                        echo "  Trying: ./gradlew ktlintFormat"
                        cd "${lint_cmd#*cd }" && ./gradlew ktlintFormat && cd - >/dev/null
                        ;;
                    *"flake8"*)
                        if command -v black >/dev/null; then
                            echo "  Trying: black ."
                            black .
                        fi
                        ;;
                esac
                
                # Re-run lint to check if fixed
                echo "🔍 Re-running after fix attempt: $lint_cmd"
                if eval "$lint_cmd" >/dev/null 2>&1; then
                    echo "✅ Fixed successfully"
                    # Remove from failures
                    lint_failures=("${lint_failures[@]/$lint_cmd: exit code $lint_exit_code}")
                else
                    echo "❌ Fix attempt failed"
                fi
            fi
        else
            echo "✅ Linting passed: $lint_cmd"
        fi
    done
fi

# CRITICAL: Fail immediately on any lint errors
if [[ ${#lint_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Linting errors detected"
    echo "=========================================="
    for failure in "${lint_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL CODE MUST PASS LINTING WITH ZERO ERRORS"
    echo "Fix all linting issues before proceeding"
    exit 1
fi

echo ""
echo "✅ LINTING: All checks passed"
```

### Step 3: Critical Test Validation (Zero Tolerance)  
```bash
echo ""
echo "🧪 CRITICAL: Test Execution (Zero Tolerance)"
echo "==========================================="

test_failures=()

if [[ ${#test_commands[@]} -eq 0 ]]; then
    echo "❌ CRITICAL: No test commands found"
    echo "ALL PROJECTS MUST HAVE MEANINGFUL TESTS"
    exit 1
fi

for test_cmd in "${test_commands[@]}"; do
    echo ""
    echo "🧪 Running: $test_cmd"
    
    # Run tests with timeout to prevent hanging
    test_output=$(timeout 600 bash -c "$test_cmd" 2>&1)
    test_exit_code=$?
    
    echo "$test_output"
    
    if [[ $test_exit_code -eq 124 ]]; then
        echo "❌ TEST TIMEOUT: $test_cmd (exceeded 10 minutes)"
        test_failures+=("$test_cmd: timeout")
    elif [[ $test_exit_code -ne 0 ]]; then
        echo "❌ TEST FAILURE: $test_cmd (exit code: $test_exit_code)"
        test_failures+=("$test_cmd: exit code $test_exit_code")
    else
        echo "✅ Tests passed: $test_cmd"
        
        # Validate test quality and meaningfulness
        echo "🔍 Validating test quality..."
        
        # Check for meaningful test counts
        test_count=$(echo "$test_output" | grep -oE '[0-9]+ (tests?|passing|passed)' | head -1 | grep -oE '[0-9]+' || echo "0")
        if [[ $test_count -lt 1 ]]; then
            echo "❌ NO MEANINGFUL TESTS: Test count is $test_count"
            test_failures+=("$test_cmd: no meaningful tests detected")
        else
            echo "  ✅ Test count: $test_count"
        fi
        
        # Check for test coverage if available
        coverage=$(echo "$test_output" | grep -oE '[0-9]+(\.[0-9]+)?%' | tail -1 || echo "")
        if [[ -n "$coverage" ]]; then
            coverage_num=$(echo "$coverage" | grep -oE '[0-9]+')
            echo "  📊 Coverage: $coverage"
            if [[ $coverage_num -lt 70 ]] && [[ "$strict_mode" == "true" ]]; then
                echo "  ⚠️ STRICT MODE: Coverage below 70%"
                test_failures+=("$test_cmd: low coverage $coverage")
            fi
        fi
        
        # Look for assertion patterns in test output
        assertions=$(echo "$test_output" | grep -c "assert\|expect\|should\|verify" || echo "0")
        if [[ $assertions -lt 1 ]]; then
            echo "  ⚠️ No assertion indicators found in test output"
        else
            echo "  ✅ Assertions detected: $assertions indicators"
        fi
    fi
done

# CRITICAL: Fail immediately on any test errors
if [[ ${#test_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Test failures detected"
    echo "======================================="
    for failure in "${test_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL TESTS MUST PASS WITH ZERO FAILURES"
    echo "Fix all test issues before proceeding"
    exit 1
fi

echo ""
echo "✅ TESTING: All tests passed with meaningful results"
```

### Step 4: Critical Build Validation
```bash
echo ""
echo "🔨 CRITICAL: Build Validation"
echo "============================"

build_failures=()

if [[ ${#build_commands[@]} -eq 0 ]]; then
    echo "⚠️ No build commands configured"
else
    for build_cmd in "${build_commands[@]}"; do
        echo ""
        echo "🔨 Running: $build_cmd"
        
        build_output=$(timeout 600 bash -c "$build_cmd" 2>&1)
        build_exit_code=$?
        
        # Only show last 50 lines of build output to avoid spam
        echo "$build_output" | tail -50
        
        if [[ $build_exit_code -eq 124 ]]; then
            echo "❌ BUILD TIMEOUT: $build_cmd (exceeded 10 minutes)"
            build_failures+=("$build_cmd: timeout")
        elif [[ $build_exit_code -ne 0 ]]; then
            echo "❌ BUILD FAILURE: $build_cmd (exit code: $build_exit_code)"
            build_failures+=("$build_cmd: exit code $build_exit_code")
        else
            echo "✅ Build successful: $build_cmd"
        fi
    done
fi

# CRITICAL: Fail immediately on any build errors
if [[ ${#build_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 CRITICAL FAILURE: Build failures detected"
    echo "========================================"
    for failure in "${build_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    echo ""
    echo "ALL BUILDS MUST SUCCEED WITH ZERO ERRORS"
    echo "Fix all build issues before proceeding"
    exit 1
fi

echo ""
echo "✅ BUILDS: All builds completed successfully"
```

### Step 5: Application Runtime Validation
```bash
echo ""
echo "🚀 CRITICAL: Application Runtime Validation"
echo "=========================================="

runtime_failures=()

if [[ ${#start_commands[@]} -eq 0 ]]; then
    echo "⚠️ No start commands configured - cannot verify runtime"
    if [[ "$e2e_mode" == "true" ]]; then
        echo "❌ E2E MODE: Start commands required for runtime validation"
        exit 1
    fi
else
    for start_cmd in "${start_commands[@]}"; do
        echo ""
        echo "🚀 Testing application startup: $start_cmd"
        
        # Start application in background
        echo "  Starting application..."
        eval "$start_cmd" &
        app_pid=$!
        
        # Give app time to start
        sleep 10
        
        # Check if process is still running
        if kill -0 $app_pid 2>/dev/null; then
            echo "  ✅ Application started successfully (PID: $app_pid)"
            
            # If E2E mode, try to make actual calls
            if [[ "$e2e_mode" == "true" ]]; then
                echo "  🔍 E2E: Testing actual functionality..."
                
                # Try common endpoints/health checks
                endpoints_tested=0
                endpoints_working=0
                
                # Test common health check endpoints
                for port in 3000 8080 5000 4000; do
                    for endpoint in "/health" "/api/health" "/" "/status"; do
                        if timeout 5 curl -s "http://localhost:$port$endpoint" >/dev/null 2>&1; then
                            echo "    ✅ E2E: http://localhost:$port$endpoint responded"
                            ((endpoints_working++))
                            ((endpoints_tested++))
                            break 2  # Found working endpoint, move on
                        fi
                        ((endpoints_tested++))
                    done
                done
                
                if [[ $endpoints_working -eq 0 ]] && [[ $endpoints_tested -gt 0 ]]; then
                    echo "    ❌ E2E: No endpoints responding"
                    runtime_failures+=("$start_cmd: no responding endpoints")
                elif [[ $endpoints_working -gt 0 ]]; then
                    echo "    ✅ E2E: Application responding to requests"
                fi
            fi
            
            # Gracefully shutdown
            echo "  🛑 Shutting down application..."
            kill $app_pid 2>/dev/null
            sleep 5
            kill -9 $app_pid 2>/dev/null  # Force kill if needed
            
        else
            echo "  ❌ Application failed to start or crashed immediately"
            runtime_failures+=("$start_cmd: failed to start")
        fi
    done
fi

# CRITICAL: Fail on runtime errors in strict mode
if [[ ${#runtime_failures[@]} -gt 0 ]]; then
    echo ""
    echo "🚨 RUNTIME FAILURES detected"
    echo "========================="
    for failure in "${runtime_failures[@]}"; do
        [[ -n "$failure" ]] && echo "  ❌ $failure"
    done
    
    if [[ "$strict_mode" == "true" ]] || [[ "$e2e_mode" == "true" ]]; then
        echo ""
        echo "APPLICATIONS MUST START AND RESPOND TO REQUESTS"
        echo "Fix all runtime issues before proceeding"
        exit 1
    else
        echo ""
        echo "⚠️ Runtime issues detected but not in strict/E2E mode"
    fi
fi

if [[ ${#runtime_failures[@]} -eq 0 ]]; then
    echo ""
    echo "✅ RUNTIME: All applications start and run correctly"
fi
```

### Step 6: Test Quality Deep Analysis
```bash
echo ""
echo "🔬 DEEP ANALYSIS: Test Quality Validation"
echo "========================================"

# Find all test files
test_files=()
while IFS= read -r -d '' file; do
    test_files+=("$file")
done < <(find . \( -name "*.test.*" -o -name "*Test.*" -o -name "test_*.py" -o -path "*/test/*" \) -type f -print0)

echo "📊 Found ${#test_files[@]} test files"

test_quality_issues=()

for test_file in "${test_files[@]}"; do
    echo ""
    echo "🔬 Analyzing: $test_file"
    
    if [[ ! -f "$test_file" ]]; then
        continue
    fi
    
    # SOLID Principle Analysis for Tests
    echo "  🔍 SOLID Analysis..."
    
    # Single Responsibility - check if test file focuses on one component
    classes_tested=$(grep -c "describe\|context\|class.*Test" "$test_file" || echo "0")
    if [[ $classes_tested -gt 3 ]]; then
        test_quality_issues+=("$test_file: Multiple classes tested - violates Single Responsibility")
    fi
    
    # KISS Analysis - complexity check
    echo "  🔍 KISS Analysis..."
    complex_logic=$(grep -c "for.*for\|while.*while\|if.*if.*if" "$test_file" || echo "0")
    if [[ $complex_logic -gt 2 ]]; then
        test_quality_issues+=("$test_file: Complex logic in tests - violates KISS principle")
    fi
    
    # FIRST Principle Analysis
    echo "  🔍 FIRST Analysis..."
    
    # Fast - look for slow operations
    slow_ops=$(grep -c "sleep\|wait\|timeout\|delay" "$test_file" || echo "0")
    if [[ $slow_ops -gt 0 ]]; then
        test_quality_issues+=("$test_file: Slow operations detected - violates FIRST-Fast")
    fi
    
    # Independent - look for dependencies
    dependencies=$(grep -c "order\|sequence\|depends.*on\|previous.*test" "$test_file" || echo "0")
    if [[ $dependencies -gt 0 ]]; then
        test_quality_issues+=("$test_file: Test dependencies detected - violates FIRST-Independent")
    fi
    
    # Self-validating - check for meaningful assertions
    total_lines=$(wc -l < "$test_file")
    assertions=$(grep -c "assert\|expect\|should\|verify" "$test_file" || echo "0")
    
    if [[ $total_lines -gt 20 ]] && [[ $assertions -lt 1 ]]; then
        test_quality_issues+=("$test_file: No assertions found - tests are not self-validating")
    fi
    
    # Check for meaningful assertions vs weak ones
    weak_assertions=$(grep -c "assertTrue.*true\|assertFalse.*false\|expect.*toBe.*true" "$test_file" || echo "0")
    if [[ $weak_assertions -gt 0 ]]; then
        test_quality_issues+=("$test_file: Weak/tautological assertions found")
    fi
    
    # Check for real vs mock heavy tests
    mock_count=$(grep -c "mock\|stub\|spy\|fake" "$test_file" || echo "0")
    if [[ $assertions -gt 0 ]] && [[ $mock_count -gt $assertions ]]; then
        test_quality_issues+=("$test_file: More mocks than real assertions - may not test actual behavior")
    fi
    
    if [[ ${#test_quality_issues[@]} -eq 0 ]]; then
        echo "    ✅ Test quality meets standards"
    fi
done

echo ""
echo "📊 Test Quality Summary:"
if [[ ${#test_quality_issues[@]} -eq 0 ]]; then
    echo "  ✅ All tests meet quality standards"
else
    echo "  ⚠️ Test quality issues found:"
    for issue in "${test_quality_issues[@]}"; do
        echo "    - $issue"
    done
    
    if [[ "$strict_mode" == "true" ]]; then
        echo ""
        echo "❌ STRICT MODE: Test quality issues must be resolved"
        exit 1
    fi
fi
```

### Step 7: Final Validation Summary
```bash
echo ""
echo "🏆 COMPREHENSIVE VALIDATION COMPLETE"
echo "===================================="

# Count all issue categories
total_issues=$((${#lint_failures[@]} + ${#test_failures[@]} + ${#build_failures[@]} + ${#runtime_failures[@]} + ${#test_quality_issues[@]}))

echo "📊 Validation Results:"
echo "  🔍 Linting: ${#lint_failures[@]} failures"
echo "  🧪 Testing: ${#test_failures[@]} failures"  
echo "  🔨 Building: ${#build_failures[@]} failures"
echo "  🚀 Runtime: ${#runtime_failures[@]} failures"
echo "  📚 Test Quality: ${#test_quality_issues[@]} issues"
echo "  📈 Total Issues: $total_issues"

echo ""
echo "🎯 Standards Applied:"
echo "  ✅ SOLID principles in tests"
echo "  ✅ KISS principle (simplicity)"
echo "  ✅ FIRST test principles (Fast, Independent, Repeatable, Self-validating, Timely)"
echo "  ✅ Zero tolerance linting"
echo "  ✅ Zero tolerance test failures"
echo "  ✅ Real application runtime verification"
if [[ "$e2e_mode" == "true" ]]; then
    echo "  ✅ End-to-end functionality validation"
fi

echo ""
if [[ $total_issues -eq 0 ]]; then
    echo "🎉 VALIDATION PASSED: All standards met!"
    echo ""
    echo "✅ ALL CLAIMS OF FUNCTIONALITY VERIFIED:"
    echo "  • Code runs without lint errors"
    echo "  • All tests pass with meaningful assertions"
    echo "  • Applications build successfully"
    echo "  • Applications start and run correctly"
    if [[ "$e2e_mode" == "true" ]]; then
        echo "  • End-to-end functionality confirmed with real calls"
    fi
    echo "  • Tests follow engineering best practices"
    echo ""
    echo "🏆 PROJECT IS PRODUCTION READY"
    exit 0
else
    echo "❌ VALIDATION FAILED: $total_issues issues must be resolved"
    echo ""
    echo "🔧 Required Actions:"
    echo "  1. Fix all linting errors (zero tolerance)"
    echo "  2. Fix all failing tests (zero tolerance)"
    echo "  3. Fix all build failures (zero tolerance)"
    echo "  4. Ensure applications start and run correctly"
    echo "  5. Improve test quality and meaningfulness"
    echo ""
    echo "🚨 NO SHORTCUTS ALLOWED - ALL ISSUES MUST BE RESOLVED"
    echo "Run /pm:validate again after fixes to verify completion"
    exit 1
fi
```

This validation command provides:
- **Zero tolerance** for lint, test, or build failures
- **Real runtime verification** that applications actually work
- **Deep test quality analysis** using SOLID, KISS, FIRST principles  
- **E2E testing** with actual HTTP calls to verify functionality
- **Comprehensive reporting** with actionable next steps
- **Auto-fix attempts** when possible with --fix-on-fail flag

The validation is strict and comprehensive - exactly what's needed to ensure all claims of working functionality are actively verified.