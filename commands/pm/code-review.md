---
allowed-tools: Read, Grep, Glob, Bash
---

# PM Code Review

Conduct a comprehensive code review focusing on software engineering principles, test quality, and production readiness.

## Usage
```
/pm:code-review [path] [--language=<lang>] [--strict] [--tests-only]
```

## Options
- `path`: Directory or file to review (defaults to current directory)
- `--language=<lang>`: Focus on specific language (typescript, kotlin, python, java, rust, go)
- `--strict`: Apply strictest interpretation of principles
- `--tests-only`: Review only test files

## Code Review Principles

### Production Code Standards

**SOLID Principles:**
- **S**ingle Responsibility: Each class/function has one reason to change
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Derived classes must be substitutable for base classes
- **I**nterface Segregation: Clients shouldn't depend on unused interfaces
- **D**ependency Inversion: Depend on abstractions, not concretions

**Quality Principles:**
- **DRY** (Don't Repeat Yourself): No code duplication
- **KISS** (Keep It Simple, Stupid): Simplest solution that works
- **ROCO** (Readable, Optimized, Consistent, Organized): Code quality standards
- **POLA** (Principle of Least Astonishment): Code behaves as expected
- **YAGNI** (You Aren't Gonna Need It): Don't build unused features
- **CLEAN**: Clear, Logical, Efficient, Accessible, Named appropriately

### Test Quality Standards

**GIVEN-WHEN-THEN Structure:**
- **GIVEN**: Set up test conditions and context
- **WHEN**: Execute the action being tested
- **THEN**: Assert expected outcomes

**FIRST Principles:**
- **F**ast: Tests run quickly
- **I**ndependent: Tests don't depend on each other
- **R**epeatable: Same results in any environment
- **S**elf-Validating: Clear pass/fail with good error messages
- **T**imely: Written just before production code

**Meaningful Tests:**
- Test behavior, not implementation
- Clear, descriptive test names
- Real, relevant assertions
- Edge cases and error conditions covered
- **FLUENT** tests, which are easy to follow. The test method code should focus on the WHAT of the test, not the HOW. The HOW should be in test builders etc, so boilerplate setup is kept out of the test method (a non tech person can read the test case) (Within reason)

## Review Process

Analyze all files in the specified path and evaluate against these criteria:

### Step 1: File Discovery and Classification
```bash
# Discover source files
echo "🔍 Discovering source files..."

# Get the target path
target_path="${1:-.}"
language_filter="$2"

if [[ ! -d "$target_path" ]]; then
    echo "❌ Path not found: $target_path"
    exit 1
fi

echo "📁 Reviewing: $target_path"
echo "🎯 Language filter: ${language_filter:-"auto-detect"}"

# Find production code files
production_files=()
test_files=()

case "$language_filter" in
    "typescript"|"ts")
        mapfile -t production_files < <(find "$target_path" -name "*.ts" -not -path "*/test/*" -not -path "*/*.test.*" -not -path "*/*.spec.*" -not -path "*/tests/*")
        mapfile -t test_files < <(find "$target_path" -name "*.test.ts" -o -name "*.spec.ts" -o -path "*/test/*.ts" -o -path "*/tests/*.ts")
        ;;
    "kotlin"|"kt")
        mapfile -t production_files < <(find "$target_path" -name "*.kt" -not -path "*/test/*" -not -path "*/*Test.kt" -not -path "*/tests/*")
        mapfile -t test_files < <(find "$target_path" -name "*Test.kt" -o -path "*/test/*.kt" -o -path "*/tests/*.kt")
        ;;
    "python"|"py")
        mapfile -t production_files < <(find "$target_path" -name "*.py" -not -path "*/test*" -not -name "*test*.py" -not -name "test_*.py")
        mapfile -t test_files < <(find "$target_path" -name "*test*.py" -o -name "test_*.py" -o -path "*/test*/*.py")
        ;;
    "java")
        mapfile -t production_files < <(find "$target_path" -name "*.java" -not -path "*/test/*" -not -name "*Test.java" -not -path "*/tests/*")
        mapfile -t test_files < <(find "$target_path" -name "*Test.java" -o -path "*/test/*.java" -o -path "*/tests/*.java")
        ;;
    *)
        # Auto-detect all common languages
        mapfile -t production_files < <(find "$target_path" \( -name "*.ts" -o -name "*.js" -o -name "*.kt" -o -name "*.py" -o -name "*.java" -o -name "*.rs" -o -name "*.go" \) -not -path "*/test*" -not -name "*test*" -not -name "*Test*" -not -name "test_*")
        mapfile -t test_files < <(find "$target_path" \( -name "*test*" -o -name "*Test*" -o -name "test_*" -o -path "*/test*/*" \))
        ;;
esac

echo "📊 Found ${#production_files[@]} production files and ${#test_files[@]} test files"
```

### Step 2: Production Code Review
Review each production file against SOLID, DRY, KISS, ROCO, POLA, YAGNI, and CLEAN principles:

```bash
if [[ "$3" != "--tests-only" ]]; then
    echo ""
    echo "🏗️ PRODUCTION CODE REVIEW"
    echo "========================="
    
    production_issues=()
    production_score=0
    total_production_files=${#production_files[@]}
    
    for file in "${production_files[@]}"; do
        echo ""
        echo "📄 Reviewing: $file"
        
        # Read file content for analysis
        if [[ ! -f "$file" ]]; then
            echo "  ⚠️ File not found: $file"
            continue
        fi
        
        file_issues=()
        
        echo "  🔍 SOLID Principles Analysis..."
        
        # Single Responsibility Principle
        class_count=$(grep -c "^class\|^export class\|^public class" "$file" 2>/dev/null || echo "0")
        function_count=$(grep -c "function\|def \|func \|fn " "$file" 2>/dev/null || echo "0")
        lines_of_code=$(wc -l < "$file")
        
        if [[ $lines_of_code -gt 300 ]] && [[ $class_count -lt 2 ]]; then
            file_issues+=("SRP: Single class with $lines_of_code lines may have multiple responsibilities")
        fi
        
        # Open/Closed Principle - look for modification patterns
        if grep -q "if.*type.*==\|switch.*type\|instanceof" "$file"; then
            file_issues+=("OCP: Type checking suggests violation of Open/Closed Principle")
        fi
        
        # DRY Principle - detect code duplication
        duplicated_lines=$(sort "$file" | uniq -d | wc -l)
        if [[ $duplicated_lines -gt 5 ]]; then
            file_issues+=("DRY: Potential code duplication detected ($duplicated_lines similar lines)")
        fi
        
        echo "  🔍 Quality Principles Analysis..."
        
        # KISS - complexity indicators
        complexity_indicators=$(grep -c "&&\||\|||\|nested.*if\|for.*for\|while.*while" "$file" 2>/dev/null || echo "0")
        if [[ $complexity_indicators -gt $((lines_of_code / 20)) ]]; then
            file_issues+=("KISS: High complexity detected - consider simplification")
        fi
        
        # ROCO - readability checks
        if ! grep -q "^//\|^#\|^/\*\|^\*" "$file"; then
            file_issues+=("ROCO: No comments found - consider adding documentation")
        fi
        
        # POLA - surprising behavior patterns
        if grep -q "global\|eval\|exec\|System\.exit\|process\.exit" "$file"; then
            file_issues+=("POLA: Global state or process control may surprise users")
        fi
        
        # YAGNI - unused code detection
        unused_imports=$(grep "^import\|^from.*import" "$file" | wc -l)
        if [[ $unused_imports -gt 10 ]]; then
            file_issues+=("YAGNI: Many imports ($unused_imports) - verify all are needed")
        fi
        
        # CLEAN - naming and structure
        bad_names=$(grep -c " [a-z]\{1,2\} \|temp\|data\|obj\|item[^s]" "$file" 2>/dev/null || echo "0")
        if [[ $bad_names -gt 3 ]]; then
            file_issues+=("CLEAN: Poor variable naming detected - use descriptive names")
        fi
        
        # Security and production readiness
        security_issues=$(grep -c "password\|secret\|key.*=\|token.*=\|console\.log\|print.*debug\|TODO\|FIXME" "$file" 2>/dev/null || echo "0")
        if [[ $security_issues -gt 0 ]]; then
            file_issues+=("SECURITY: Potential security issues or debug code found")
        fi
        
        # Report file results
        if [[ ${#file_issues[@]} -eq 0 ]]; then
            echo "  ✅ No issues found"
            ((production_score++))
        else
            echo "  ❌ Issues found:"
            printf '    - %s\n' "${file_issues[@]}"
            production_issues+=("${file}: ${file_issues[*]}")
        fi
    done
    
    echo ""
    echo "📊 Production Code Summary:"
    echo "  Files reviewed: $total_production_files"
    echo "  Files passing: $production_score"
    echo "  Success rate: $(( production_score * 100 / (total_production_files + 1) ))%"
    
    if [[ ${#production_issues[@]} -gt 0 ]]; then
        echo ""
        echo "❌ Production Issues Found:"
        printf '%s\n' "${production_issues[@]}"
    fi
fi
```

### Step 3: Test Code Review
Review test files against GIVEN-WHEN-THEN, FIRST principles, and meaningfulness:

```bash
if [[ ${#test_files[@]} -gt 0 ]]; then
    echo ""
    echo "🧪 TEST CODE REVIEW"
    echo "=================="
    
    test_issues=()
    test_score=0
    total_test_files=${#test_files[@]}
    
    for test_file in "${test_files[@]}"; do
        echo ""
        echo "🧪 Reviewing: $test_file"
        
        if [[ ! -f "$test_file" ]]; then
            echo "  ⚠️ File not found: $test_file"
            continue
        fi
        
        file_test_issues=()
        
        echo "  🔍 GIVEN-WHEN-THEN Structure Analysis..."
        
        # Check for proper test structure
        given_count=$(grep -ic "given\|arrange\|setup\|beforeEach\|setUp" "$test_file" || echo "0")
        when_count=$(grep -ic "when\|act\|execute\|call" "$test_file" || echo "0")
        then_count=$(grep -ic "then\|assert\|expect\|should\|verify" "$test_file" || echo "0")
        
        test_functions=$(grep -c "test\|it(\|def test_\|fun.*test\|Test.*(" "$test_file" || echo "0")
        
        if [[ $test_functions -gt 0 ]]; then
            if [[ $given_count -eq 0 ]] && [[ $test_functions -gt 2 ]]; then
                file_test_issues+=("GIVEN-WHEN-THEN: No setup/arrange phase detected")
            fi
            if [[ $then_count -eq 0 ]]; then
                file_test_issues+=("GIVEN-WHEN-THEN: No assertions found - tests are meaningless")
            fi
        fi
        
        echo "  🔍 FIRST Principles Analysis..."
        
        # Fast - look for slow operations
        slow_operations=$(grep -ic "sleep\|wait\|timeout\|delay\|Thread\.sleep\|setTimeout" "$test_file" || echo "0")
        if [[ $slow_operations -gt 0 ]]; then
            file_test_issues+=("FIRST-Fast: Slow operations detected in tests")
        fi
        
        # Independent - look for test dependencies
        if grep -q "order\|depends\|sequence\|previous" "$test_file"; then
            file_test_issues+=("FIRST-Independent: Tests may depend on execution order")
        fi
        
        # Repeatable - look for environment dependencies
        env_deps=$(grep -ic "process\.env\|System\.getenv\|os\.environ\|hardcoded.*path\|localhost\|127\.0\.0\.1" "$test_file" || echo "0")
        if [[ $env_deps -gt 2 ]]; then
            file_test_issues+=("FIRST-Repeatable: Environment dependencies may affect repeatability")
        fi
        
        # Self-Validating - check assertion quality
        weak_assertions=$(grep -ic "assertTrue.*true\|assertFalse.*false\|expect.*toBe.*true\|assertEqual.*1.*1" "$test_file" || echo "0")
        if [[ $weak_assertions -gt 0 ]]; then
            file_test_issues+=("FIRST-SelfValidating: Weak or tautological assertions found")
        fi
        
        echo "  🔍 Meaningful Test Analysis..."
        
        # Check for descriptive test names
        bad_test_names=$(grep -c "test1\|test2\|testA\|testB\|simple.*test\|basic.*test" "$test_file" || echo "0")
        if [[ $bad_test_names -gt 0 ]]; then
            file_test_issues+=("MEANINGFUL: Non-descriptive test names found")
        fi
        
        # Check for real assertions vs mocks
        total_assertions=$(grep -c "assert\|expect\|should\|verify" "$test_file" || echo "0")
        mock_assertions=$(grep -c "mock\|stub\|spy\|fake" "$test_file" || echo "0")
        
        if [[ $total_assertions -gt 0 ]] && [[ $mock_assertions -gt $((total_assertions / 2)) ]]; then
            file_test_issues+=("MEANINGFUL: More mocks than real assertions - tests may not verify actual behavior")
        fi
        
        # Check for edge cases
        edge_case_indicators=$(grep -ic "null\|empty\|zero\|negative\|boundary\|edge\|limit\|error\|exception" "$test_file" || echo "0")
        if [[ $test_functions -gt 3 ]] && [[ $edge_case_indicators -eq 0 ]]; then
            file_test_issues+=("MEANINGFUL: No edge cases or error conditions tested")
        fi
        
        # Report test file results
        if [[ ${#file_test_issues[@]} -eq 0 ]]; then
            echo "  ✅ No issues found"
            ((test_score++))
        else
            echo "  ❌ Issues found:"
            printf '    - %s\n' "${file_test_issues[@]}"
            test_issues+=("${test_file}: ${file_test_issues[*]}")
        fi
    done
    
    echo ""
    echo "📊 Test Code Summary:"
    echo "  Files reviewed: $total_test_files"
    echo "  Files passing: $test_score"
    echo "  Success rate: $(( test_score * 100 / (total_test_files + 1) ))%"
    
    if [[ ${#test_issues[@]} -gt 0 ]]; then
        echo ""
        echo "❌ Test Issues Found:"
        printf '%s\n' "${test_issues[@]}"
    fi
else
    echo ""
    echo "⚠️ No test files found - consider adding comprehensive tests"
fi
```

### Step 4: Overall Assessment and Recommendations
```bash
echo ""
echo "🎯 OVERALL CODE REVIEW ASSESSMENT"
echo "================================="

total_files=$((${#production_files[@]} + ${#test_files[@]}))
total_passing_files=$((production_score + test_score))

if [[ $total_files -gt 0 ]]; then
    overall_score=$(( total_passing_files * 100 / total_files ))
    
    echo "📊 Review Results:"
    echo "  Total files reviewed: $total_files"
    echo "  Files meeting standards: $total_passing_files"
    echo "  Overall quality score: $overall_score%"
    
    echo ""
    if [[ $overall_score -ge 90 ]]; then
        echo "🏆 EXCELLENT: Code meets high quality standards"
        echo "   Continue maintaining these excellent practices"
    elif [[ $overall_score -ge 70 ]]; then
        echo "✅ GOOD: Code quality is acceptable with room for improvement"
        echo "   Address identified issues for better maintainability"
    elif [[ $overall_score -ge 50 ]]; then
        echo "⚠️ NEEDS IMPROVEMENT: Code quality issues require attention"
        echo "   Focus on SOLID principles and test coverage"
    else
        echo "❌ POOR: Significant code quality issues found"
        echo "   Major refactoring recommended before production"
    fi
    
    echo ""
    echo "🔧 Recommended Actions:"
    if [[ ${#production_issues[@]} -gt 0 ]]; then
        echo "   • Address production code principle violations"
        echo "   • Refactor complex functions and classes"
        echo "   • Add meaningful documentation"
    fi
    if [[ ${#test_issues[@]} -gt 0 ]]; then
        echo "   • Improve test structure and meaningfulness"
        echo "   • Add edge case and error condition tests"
        echo "   • Remove test dependencies and environmental coupling"
    fi
    
    echo ""
    echo "📚 Quality Principles Summary:"
    echo "   SOLID: Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion"
    echo "   DRY: Don't repeat yourself - eliminate duplication"
    echo "   KISS: Keep it simple - favor simplicity over cleverness"
    echo "   ROCO: Readable, Optimized, Consistent, Organized code"
    echo "   POLA: Principle of least astonishment - code behaves as expected"
    echo "   YAGNI: You aren't gonna need it - don't over-engineer"
    echo "   CLEAN: Clear, Logical, Efficient, Accessible, Named appropriately"
    
    echo ""
    echo "🧪 Test Quality Standards:"
    echo "   GIVEN-WHEN-THEN: Structure tests with clear setup, action, and verification"
    echo "   FIRST: Fast, Independent, Repeatable, Self-validating, Timely tests"
    echo "   MEANINGFUL: Test behavior not implementation, with relevant assertions"
    
    # Exit with appropriate code
    if [[ $overall_score -ge 70 ]]; then
        exit 0
    else
        exit 1
    fi
else
    echo "❌ No files found to review"
    exit 1
fi
```

This command provides a comprehensive code review focused on industry-standard software engineering principles and test quality standards.