# PM Code Review System

Conducts comprehensive code review focusing on software engineering principles, test quality, and production readiness.

## Usage

```bash
/ct:code-review [path]          # Review specific path
/ct:code-review                 # Review entire project
```

## Quality Standards Applied

### SOLID Principles
- ✅ **Single Responsibility**: Each class/function has one reason to change
- ✅ **Open/Closed**: Open for extension, closed for modification  
- ✅ **Liskov Substitution**: Derived classes are substitutable for base classes
- ✅ **Interface Segregation**: Clients shouldn't depend on unused interfaces
- ✅ **Dependency Inversion**: Depend on abstractions, not concretions

### Additional Standards
- ✅ **DRY**: Don't repeat yourself - eliminate code duplication
- ✅ **KISS**: Keep it simple - favor simplicity over cleverness
- ✅ **ROCO**: Readable, Optimized, Consistent, Organized code
- ✅ **POLA**: Principle of least astonishment - code behaves as expected
- ✅ **YAGNI**: You aren't gonna need it - don't over-engineer
- ✅ **CLEAN**: Clear, Logical, Efficient, Accessible, Named appropriately

### Test Quality
- ✅ **GIVEN-WHEN-THEN**: Clear test structure
- ✅ **FIRST**: Fast, Independent, Repeatable, Self-validating, Timely
- ✅ **MEANINGFUL**: Test behavior not implementation
- ✅ **NO CHEATING**: Tests must verify real behavior

## Review Areas

### Code Structure
- Function/class size and complexity
- Naming conventions and clarity
- Error handling and edge cases
- Resource management (connections, files, memory)

### Architecture
- Separation of concerns
- Dependency management
- Abstraction levels
- Module boundaries

### Performance & Security  
- Resource leaks prevention
- Security best practices
- Performance bottlenecks
- Thread safety

## Examples

```bash
# Review specific module
/ct:code-review src/api/

# Full codebase review  
/ct:code-review

# Part of complete quality workflow
/ct:fix-all
```

## Integration

Works with quality-guardian agent for enforcement:
1. Identifies violations of coding standards
2. Generates actionable improvement suggestions
3. Integrates with `/ct:plan-fixes` for systematic resolution
4. Zero tolerance for quality violations

Maintains high code quality through systematic review and enforcement!