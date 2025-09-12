# Multi-Agent Anti-Cheat Detection System

Detects hardcoded responses, cheat patterns, simulation code, and other non-genuine implementations using specialized agents for thorough analysis.

## Usage

```bash
/ct:anti-cheat [path]           # Analyze specific path using all agents
/ct:anti-cheat                  # Analyze entire project using all agents  
/ct:anti-cheat --agent=<name>   # Use specific agent only
/ct:anti-cheat --strict         # Apply maximum scrutiny for cheat detection
/ct:anti-cheat --quick          # Fast scan focusing on obvious cheats
```

## Options
- `--agent=<name>`: Use only specific agent (reality-check|compliance-functionality|compliance-rules|pragmatic-engineer)
- `--strict`: Apply maximum scrutiny and zero tolerance for any suspicious patterns
- `--quick`: Focus on obvious cheat patterns for faster feedback

## Multi-Agent Cheat Detection Process

The anti-cheat system orchestrates specialized agents for comprehensive cheat pattern detection:

### Agent Execution Sequence
1. **🎯 /ct:agent:reality-check** - Primary Bullshit Detection
   - Detects functions that exist but don't actually work end-to-end
   - Identifies Band-Aid fixes that hide underlying problems  
   - Spots tasks marked complete that only work in ideal conditions
   - Calls out over-abstracted code that doesn't deliver value
   - **Core anti-cheat expertise**: Cutting through fake implementations

2. **✅ /ct:agent:compliance-functionality** - Implementation Validation
   - Verifies core functionality is genuinely implemented (not stubbed/mocked)
   - Detects placeholder comments like 'TODO', 'FIXME', 'Not implemented yet'
   - Identifies empty catch blocks and ignored error scenarios
   - Validates integration points connect to real systems, not hardcoded responses
   - **Cheat focus**: Tests that actually test real functionality vs mocks

3. **📋 /ct:agent:compliance-rules** - Anti-Cheat Rule Enforcement
   - Enforces "no cheating, mocking, or simulating intelligence in production code"
   - Validates against XML rules that may define specific cheat patterns
   - Checks AGENTS.md anti-cheat guidelines compliance
   - **Rule focus**: Project-specific anti-cheat policies and standards

4. **🔧 /ct:agent:pragmatic-engineer** - Over-Engineering vs Under-Engineering
   - Distinguishes between appropriate solutions and shortcuts
   - Identifies premature optimizations that prevent actual completion
   - Detects when complex patterns mask missing functionality
   - **Balance focus**: Real implementation at appropriate complexity level

## What It Detects

### Cheat Patterns
- ✅ **Hardcoded responses** that should be computed
- ✅ **Keyword-based fake intelligence** systems
- ✅ **Mock/stub implementations** in production code
- ✅ **Random/time-based responses** masking hardcoded logic
- ✅ **Early returns** with fake values
- ✅ **Debug modes** in production code
- ✅ **Bypass conditions** skipping real processing
- ✅ **TODO/FIXME** in production code
- ✅ **Caller-dependent behavior** variations
- ✅ **Lookup tables** masquerading as complex logic

### Anti-Patterns
- Fake API responses instead of real service calls
- Hardcoded test data in business logic
- Simulation code pretending to be real functionality
- Feature flags that permanently bypass implementation
- Magic numbers without explanation

## Examples

```bash
# Check specific component for cheats
/ct:anti-cheat src/auth/

# Full project cheat detection
/ct:anti-cheat

# Common as part of fix workflow
/ct:fix
```

## Integration & Workflow

### Multi-Agent Execution Example
```bash
# Full multi-agent anti-cheat detection
/ct:anti-cheat

# Execution flow:
echo "🎯 Running reality-check for bullshit detection..."
Task(description="Bullshit detection", prompt="/ct:agent:reality-check --focus=cheat-detection", subagent_type="general-purpose")

echo "✅ Running functionality validation for fake implementations..."  
Task(description="Implementation validation", prompt="/ct:agent:compliance-functionality --focus=anti-cheat", subagent_type="general-purpose")

echo "📋 Running rules compliance for anti-cheat policies..."
Task(description="Anti-cheat rules check", prompt="/ct:agent:compliance-rules --focus=anti-cheat", subagent_type="general-purpose")

echo "🔧 Running pragmatic review for complexity vs shortcuts..."
Task(description="Engineering balance check", prompt="/ct:agent:pragmatic-engineer --focus=shortcuts", subagent_type="general-purpose")
```

### Integration with Quality Workflow
1. **Multi-Agent Detection**: Each agent brings specialized anti-cheat expertise
2. **Cross-Agent Validation**: Agents collaborate to identify sophisticated cheat patterns
3. **Priority Assessment**: Critical cheats (fake functionality) vs Medium (hardcoded values)
4. **Fix Generation**: Integrates with `/ct:fix` for systematic cheat elimination
5. **Quality Gate**: Zero tolerance approach - all agents must pass anti-cheat validation

### Advanced Cheat Detection
- **Reality-Check**: Primary bullshit detector with zero tolerance for fake implementations
- **Functionality Validator**: Ensures claimed features actually work end-to-end
- **Rules Enforcer**: Applies project-specific anti-cheat policies and XML rules
- **Pragmatic Engineer**: Balances appropriate complexity vs shortcuts/over-engineering

### Output Consolidation
- **Cheat Severity**: Critical (fake functionality) to Low (magic numbers)
- **Pattern Classification**: Hardcoded responses, mock implementations, bypass logic
- **Agent Consensus**: Multiple agents confirming cheat patterns for accuracy
- **Remediation Plans**: Specific steps to replace cheats with real implementations

Part of the complete quality workflow:
1. `/ct:code-review` - SOLID principles + multi-agent analysis
2. `/ct:anti-cheat` - Multi-agent cheat pattern detection  
3. `/ct:validate` - Runtime validation
4. `/ct:fix` - Generate comprehensive fix plan

**ZERO TOLERANCE** for cheat patterns in production code through multi-agent enforcement!