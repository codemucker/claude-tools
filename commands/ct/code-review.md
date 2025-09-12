# Multi-Agent Code Review System

Conducts thorough code review using specialized agents to ensure software engineering principles, test quality, production readiness, and rule compliance.

## Usage

```bash
/ct:code-review [path]          # Review specific path using all agents
/ct:code-review                 # Review entire project using all agents
/ct:code-review --agent=<name>  # Use specific agent only
/ct:code-review --quick         # Skip detailed analysis, faster review
```

## Options
- `--agent=<name>`: Use only specific agent (code-review|pragmatic-engineer|compliance-functionality|compliance-rules|compliance-spec|compliance-vision)
- `--quick`: Skip detailed cross-agent analysis for faster feedback
- `--strict`: Apply maximum scrutiny across all agents

## Multi-Agent Review Process

The code review orchestrates multiple specialized agents for comprehensive analysis:

### Agent Execution Sequence
1. **📋 /ct:agent:code-review** - Core Standards & Principles Review
   - Applies SOLID principles (SRP, OCP, LSP, ISP, DIP) with complexity balance
   - Enforces engineering standards (DRY, KISS, ROCO, POLA, YAGNI, CLEAN)
   - Evaluates test quality (GIVEN-WHEN-THEN, FIRST, meaningful behavior testing)
   - Assesses architecture, performance, security, and production readiness

2. **🔧 /ct:agent:pragmatic-engineer** - Simplicity & Over-engineering Check
   - Detects unnecessary complexity and over-engineering
   - Identifies enterprise patterns in simple projects
   - Recommends simplification opportunities
   - Ensures solutions match project scale (MVP vs enterprise)

3. **✅ /ct:agent:compliance-functionality** - Functionality Validation
   - Verifies claimed functionality actually works end-to-end
   - Detects stubbed out, mocked, or incomplete implementations
   - Validates error handling and integration points
   - Ensures no shortcuts that compromise features

4. **📋 /ct:agent:compliance-rules** - Rules Adherence Check
   - Validates against AGENTS.md guidelines
   - Checks XML rule files (./docs/llm/rules/*.xml, .claude/rules/*.xml)
   - Handles rule priority and conflict resolution
   - Ensures file creation and documentation policies are followed

5. **📋 /ct:agent:compliance-spec** - Specification Alignment
   - Verifies implementation matches written specifications
   - Identifies gaps between requirements and actual code
   - Flags features implemented but not specified
   - Ensures specification compliance

6. **🎯 /ct:agent:compliance-vision** - Vision & Scale Alignment
   - Validates implementations align with VISION.md project scope
   - Prevents scope creep (over-engineering) and under-engineering
   - Ensures complexity matches project type (CLI/desktop/web/enterprise)
   - Verifies features serve the stated project goals

7. **🔍 /ct:agent:reality-check** - Final Reality Assessment
   - Cuts through any remaining bullshit implementations
   - Validates that "complete" means "actually works"
   - Creates actionable plans for any identified gaps
   - Provides honest assessment of project state

## Quality Standards Applied

### SOLID Principles
- ✅ **Single Responsibility**: Each class/function has one reason to change (taking into account the complexity of the app)
- ✅ **Open/Closed**: Open for extension, closed for modification  
- ✅ **Liskov Substitution**: Derived classes are substitutable for base classes
- ✅ **Interface Segregation**: Clients shouldn't depend on unused interfaces
- ✅ **Dependency Inversion**: Depend on abstractions, not concretions
- while the above is important, breaking code up into multiple classes also introduces complexity, so the size of the problem, and the size of the app needs to be taken into account as to whether this warrants it.

### Additional Standards
- ✅ **DRY**: Don't repeat yourself - eliminate code duplication
- ✅ **KISS**: Keep it simple - favor simplicity over cleverness
- ✅ **ROCO**: Readable, Optimized, Consistent, Organized code
- ✅ **POLA**: Principle of least astonishment - code behaves as expected
- ✅ **YAGNI**: You aren't gonna need it - don't over-engineer,  the complexity of the code should reflrect the complexity of the problem. DO we need enterprisey features in this app?
- ✅ **CLEAN**: Clear, Logical, Efficient, Accessible, Named appropriately
- No cheating, mocking, or simulating intelligence in production code to pass tests. We need the real deal

### Test Quality
- ✅ **GIVEN-WHEN-THEN**: Clear test structure
- ✅ **FIRST**: Fast, Independent, Repeatable, Self-validating, Timely
- ✅ **MEANINGFUL**: Test behavior not implementation
- ✅ **NO CHEATING**: Tests must verify real behavior
- ✅ **fluent**: Ideally tests should be easy to read, and read like english as much as possible. We can trade a bit of complexity in test helpers and builders so that the test themselves read nice
- **Builders/utils** - The test cases should contain the *what* of the test, not the *how* (at least for higher level tests), so common setup code should go into builders/utils, so tests remain focused, and clear. Low level test setup code should be pushed out of the test method where possible (except for the very trivial cases)


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
- Security best practices (for the type of app we are building)
- Performance bottlenecks (for the type of app we are building)
- Thread safety

## Examples

```bash
# Review specific module
/ct:code-review src/api/

# Full codebase review  
/ct:code-review

# Part of complete quality workflow
/ct:fix
```

## Integration & Workflow

### Multi-Agent Execution Example
```bash
# Full multi-agent code review
/ct:code-review

# Execution flow:
echo "📋 Running core code review (SOLID, DRY, KISS, tests)..."
Task(description="Standards review", prompt="/ct:agent:code-review", subagent_type="general-purpose")

echo "🔧 Running pragmatic-engineer review..."
Task(description="Simplicity review", prompt="/ct:agent:pragmatic-engineer", subagent_type="general-purpose")

echo "✅ Running functionality validation..."  
Task(description="Functionality check", prompt="/ct:agent:compliance-functionality", subagent_type="general-purpose")

echo "📋 Running rules compliance check..."
Task(description="Rules validation", prompt="/ct:agent:compliance-rules", subagent_type="general-purpose")

echo "📋 Running spec compliance check..."
Task(description="Spec validation", prompt="/ct:agent:compliance-spec", subagent_type="general-purpose")

echo "🎯 Running vision compliance check..."
Task(description="Vision alignment", prompt="/ct:agent:compliance-vision", subagent_type="general-purpose")

echo "🔍 Running final reality check..."
Task(description="Reality assessment", prompt="/ct:agent:reality-check", subagent_type="general-purpose")
```

### Integration with Fix System
1. **Issue Detection**: Each agent identifies specific violations and issues
2. **Cross-Agent Validation**: Agents collaborate and cross-reference findings  
3. **Actionable Results**: Generates specific fix recommendations with priorities
4. **Fix Generation**: Integrates with `/ct:fix` for systematic issue resolution
5. **Quality Gate**: Zero tolerance approach - all agents must pass

### Output Consolidation
- **Severity Levels**: Critical/High/Medium/Low across all agents
- **Priority Conflicts**: Flags conflicts between agent recommendations  
- **Action Items**: Specific, ordered list of fixes required
- **Agent Collaboration**: Shows how agents reference each other's findings
- **Reality Assessment**: Final validation that fixes actually work

Maintains the highest code quality through systematic multi-agent review and enforcement!