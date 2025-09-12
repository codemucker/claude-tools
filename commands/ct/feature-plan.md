# Feature Planning and Analysis System

Interactive feature planning command that prompts for new features, analyzes them for completeness and clarity issues, and creates structured feature documentation with multi-agent validation.

## Usage

```bash
/ct:feature-plan                    # Interactive feature planning session
/ct:feature-plan --quick           # Skip detailed validation for rapid prototyping
/ct:feature-plan --vision-only     # Focus only on vision alignment
```

## Options
- `--quick`: Skip detailed cross-agent analysis for faster feedback
- `--vision-only`: Only validate against VISION.md, skip other compliance checks
- `--skip-interaction`: Process feature without interactive clarification (for automated workflows)

## Feature Analysis Process

The feature planning system uses a multi-agent approach to ensure features are well-defined, clear, and aligned with project goals:

### Phase 1: Feature Collection
1. **Interactive Prompting**: Gather initial feature description from user
2. **Context Discovery**: Analyze existing project structure, VISION.md, requirements.md
3. **Initial Assessment**: Quick review for obvious gaps or issues

### Phase 2: Multi-Agent Analysis
1. **🎯 /ct:agent:compliance-vision** - Vision Alignment Analysis
   - Validates feature fits project scope and scale (CLI/desktop/web/enterprise)
   - Prevents scope creep and ensures appropriate complexity
   - Checks against VISION.md requirements

2. **📋 /ct:agent:compliance-spec** - Specification Clarity Analysis
   - Identifies vague, ambiguous, or unclear requirements
   - Flags missing technical details and acceptance criteria
   - Ensures feature is testable and measurable

3. **🔍 /ct:agent:reality-check** - Feasibility and Reality Assessment
   - Cuts through unrealistic expectations
   - Validates technical feasibility within project constraints
   - Identifies potential implementation challenges

4. **📋 /ct:agent:compliance-rules** - Project Rules Compliance
   - Validates against AGENTS.md guidelines
   - Checks XML rule files (./docs/llm/rules/*.xml, .claude/rules/*.xml)
   - Ensures feature aligns with project standards

### Phase 3: Interactive Clarification
- **Issue Identification**: Present analysis findings to user
- **Clarification Loop**: Interactive Q&A to resolve ambiguities
- **Refinement**: Iterative improvement until feature is well-defined
- **Final Validation**: Confirm feature meets all clarity requirements

### Phase 4: Documentation Creation
- **Feature File Creation**: Generate dated feature file in `./docs/planning/features/`
- **Design Integration**: Link to existing design.md if present
- **Business Case**: Include use cases and business value
- **Implementation Breakdown**: Break large features into sub-features

### Phase 5: Task Workflow Generation
- **🔧 /ct:agent:feature-workflow** - Implementation Task Breakdown
  - Creates hierarchical task structure with XML tracking
  - Generates actionable, specific implementation tasks
  - Establishes task dependencies and parallel execution opportunities
  - Produces machine-readable task files for progress monitoring

## Feature Analysis Framework

### Clarity Issues Detected
- **Vague Requirements**: "Make it better" → "Improve response time by 50%"
- **Ambiguous Scope**: "Add user management" → "Add user registration, authentication, and profile management"
- **Missing Context**: Feature without business justification or use cases
- **Open-Ended Goals**: "Optimize performance" → "Reduce API response time from 2s to 500ms"
- **Undefined Success**: No measurable acceptance criteria
- **Technical Gaps**: Missing implementation details or constraints

### Business Validation
- **Use Case Analysis**: Who will use this feature and why?
- **Value Proposition**: What business problem does this solve?
- **User Stories**: Concrete scenarios for feature usage
- **Success Metrics**: How will we measure feature success?
- **Priority Assessment**: Where does this fit in project roadmap?

## Output Format

### Feature Analysis Report
```
## Feature Analysis: [Feature Name]

### Original Request:
[User's initial feature description]

### Vision Alignment: [ALIGNED/SCOPE_CREEP/UNDER_SPECIFIED/CONFLICTS]
- Project Scale: [CLI/Desktop/Web/Enterprise]
- Complexity Match: [Appropriate/Over-engineered/Under-specified]
- Vision Compliance: [Details from compliance-vision agent]

### Clarity Assessment: [CLEAR/NEEDS_CLARIFICATION/MAJOR_GAPS]
- Specification Issues: [List from compliance-spec agent]
- Reality Check: [Feasibility assessment from reality-check agent]
- Rule Compliance: [Validation from compliance-rules agent]

### Issues Requiring Clarification:
1. **[Issue Type]** - Priority: [High/Medium/Low]
   - Problem: [What's unclear/missing]
   - Clarification Needed: [Specific questions for user]

### Business Case:
- Primary Use Case: [Who uses this and why]
- Success Criteria: [Measurable outcomes]
- Business Value: [Why this matters]

### Implementation Breakdown:
- Sub-features: [If feature is large, break into parts]
- Dependencies: [Other features or systems needed]
- Technical Considerations: [Key implementation notes]
```

## Interactive Clarification Flow

```bash
# Example interaction flow
echo "🎯 Feature Planning Session Started"
echo "Please describe the feature you'd like to add:"
read feature_description

echo "📊 Analyzing feature with multiple agents..."
Task(description="Vision alignment", prompt="/ct:agent:compliance-vision --feature='$feature_description'", subagent_type="general-purpose")
Task(description="Spec clarity check", prompt="/ct:agent:compliance-spec --feature='$feature_description'", subagent_type="general-purpose")
Task(description="Reality assessment", prompt="/ct:agent:reality-check --feature='$feature_description'", subagent_type="general-purpose")
Task(description="Rules compliance", prompt="/ct:agent:compliance-rules --feature='$feature_description'", subagent_type="general-purpose")

echo "🔍 Analysis complete. Issues found:"
# Present issues and iterate with user
while [[ $issues_remaining -gt 0 ]]; do
    echo "Please clarify: [specific question]"
    read clarification
    # Re-analyze with updates
done

echo "✅ Feature is well-defined. Creating documentation..."
# Create feature file

echo "🔧 Generating implementation workflow..."
Task(description="Task breakdown", prompt="/ct:agent:feature-workflow --feature-file='$feature_file_path'", subagent_type="general-purpose")

echo "✅ Feature planning complete with actionable task structure!"
```

## File Creation Strategy

### Feature File Naming
- Format: `YYYY-MM-DD-feature-name.md`
- Location: `./docs/planning/features/`
- Example: `2024-01-15-user-authentication.md`

### Feature File Structure
```markdown
# Feature: [Name]
**Date**: [YYYY-MM-DD]
**Status**: [Planned/In-Progress/Complete]
**Priority**: [High/Medium/Low]

## Business Case
- **Problem**: [What problem this solves]
- **Users**: [Who benefits from this]
- **Value**: [Business value delivered]

## Requirements
- **Functional**: [What the feature does]
- **Non-Functional**: [Performance, security, etc.]
- **Acceptance Criteria**: [Measurable success conditions]

## Technical Approach
- **Implementation Strategy**: [High-level approach]
- **Dependencies**: [What's needed first]
- **Risks**: [Potential challenges]

## Sub-Features (if applicable)
1. [Sub-feature 1] - [Priority/Status]
2. [Sub-feature 2] - [Priority/Status]

## Integration
- **Design.md Impact**: [Changes needed to design.md]
- **Vision Alignment**: [How this serves project vision]
- **Related Features**: [Dependencies or connections]

## Validation Results
- Vision Compliance: ✅/❌
- Specification Clarity: ✅/❌  
- Technical Feasibility: ✅/❌
- Rule Compliance: ✅/❌
```

## Integration Points

### Design.md Integration
- **Automatic Linking**: Reference existing design patterns
- **Design Updates**: Flag when design.md needs updates
- **Architecture Impact**: Note system-wide changes needed

### Vision Validation
- **VISION.md Alignment**: Ensure feature serves project goals
- **Scope Appropriateness**: Match feature complexity to project scale
- **Priority Alignment**: Validate feature fits project roadmap

### Requirements Integration
- **Requirements.md Cross-Reference**: Link to existing requirements
- **Gap Analysis**: Identify missing requirement documentation
- **Consistency Check**: Ensure no conflicting requirements

### Task Workflow Integration
- **Hierarchical Task Structure**: Feature broken into sequential and parallel tasks
- **XML Task Tracking**: Machine-readable progress monitoring
- **Directory Structure**: `./docs/planning/features/<timestamp>-<name>/task-XXX.xml`
- **Dependency Management**: Clear task ordering and prerequisites
- **Implementation Ready**: Specific, actionable tasks with success criteria

## Examples

```bash
# Interactive feature planning
/ct:feature-plan

# Quick feature validation without deep analysis
/ct:feature-plan --quick

# Focus only on vision alignment
/ct:feature-plan --vision-only

# Process feature description from file
echo "Add real-time notifications" | /ct:feature-plan --skip-interaction
```

## Complete Workflow Example

```bash
# Full feature planning workflow
/ct:feature-plan

# Input: "Add user authentication with login and registration"
# 
# Phase 1: Feature Collection ✅
# Phase 2: Multi-Agent Analysis ✅
#   - Vision alignment: ALIGNED (matches web app scale)
#   - Spec clarity: NEEDS_CLARIFICATION (missing JWT details)
#   - Reality check: FEASIBLE (with existing database)
#   - Rules compliance: ALIGNED
# 
# Phase 3: Interactive Clarification ✅
#   Q: "Should authentication use JWT tokens or sessions?"
#   A: "JWT tokens with 24-hour expiry"
#   Q: "What user fields are required for registration?"
#   A: "Email, password, firstName, lastName"
#
# Phase 4: Documentation Creation ✅
#   Created: ./docs/planning/features/2024-01-15-user-authentication.md
#
# Phase 5: Task Workflow Generation ✅
#   Created: ./docs/planning/features/2024-01-15-user-authentication/
#   ├── task-001.xml (Create UserService with addUser/removeUser)
#   ├── task-002.xml (Create AuthService with login/register)
#   ├── task-003/ (Parallel API endpoints)
#   │   ├── task-003.xml (Parent tracker)
#   │   ├── sub-task-001.xml (POST /api/auth/register)
#   │   ├── sub-task-002.xml (POST /api/auth/login)
#   │   └── sub-task-003.xml (GET /api/auth/profile)
#   └── task-004.xml (Add JWT middleware)
#
# Result: Feature ready for implementation with 7 actionable tasks
```

## Success Criteria

A feature is considered implementation-ready when:
- **Clear Requirements**: Specific, measurable, and testable
- **Business Justification**: Clear use cases and value proposition
- **Technical Feasibility**: Realistic within project constraints
- **Vision Alignment**: Serves stated project goals appropriately
- **Task Breakdown**: Actionable tasks with dependencies and success criteria
- **Machine Trackable**: XML task structure enables automated progress monitoring

The feature planning system ensures no feature enters development without proper analysis, clarification, and actionable implementation roadmap, preventing scope creep, over-engineering, and unclear requirements that lead to project delays and confusion.