---
allowed-tools: Bash, Read, Glob
---

# PM Update

Synchronize project commands with global bert-global commands by updating symlinks.

## Usage
```
/pm:update [--dry-run] [--force] [--clean]
```

## Options
- `--dry-run`: Show what would be done without making changes
- `--force`: Overwrite existing non-symlink files
- `--clean`: Remove symlinks to commands that no longer exist in global directory

## Synchronization Process

Update project `.claude/commands/` symlinks to match `~/.claude/bert-global/commands/`:

### Step 1: Validate Directories
```bash
echo "🔄 PM Commands Synchronization"
echo "============================="

# Check if global command directory exists
global_dir="$HOME/.claude/bert-global/commands"
if [[ ! -d "$global_dir" ]]; then
    echo "❌ Global command directory not found: $global_dir"
    echo ""
    echo "Create it first:"
    echo "  mkdir -p $global_dir"
    exit 1
fi

# Create local command directory if it doesn't exist
local_dir=".claude/commands"
if [[ ! -d "$local_dir" ]]; then
    echo "📁 Creating local command directory: $local_dir"
    mkdir -p "$local_dir"
fi

echo "📁 Global commands: $global_dir"
echo "📁 Project commands: $local_dir"

# Parse options
dry_run=false
force=false
clean=false

for arg in "$@"; do
    case $arg in
        --dry-run) dry_run=true ;;
        --force) force=true ;;
        --clean) clean=true ;;
    esac
done

echo "⚙️ Options: dry-run=$dry_run, force=$force, clean=$clean"
echo ""
```

### Step 2: Discover Global Commands
```bash
echo "🔍 Discovering global commands..."

# Find all command files in global directory (preserve directory structure)
global_commands=()
while IFS= read -r -d '' file; do
    # Get relative path from global commands directory
    rel_path="${file#$global_dir/}"
    global_commands+=("$rel_path")
done < <(find "$global_dir" -name "*.md" -type f -print0)

echo "📊 Found ${#global_commands[@]} global command files:"
for cmd in "${global_commands[@]}"; do
    echo "  📄 $cmd"
done

if [[ ${#global_commands[@]} -eq 0 ]]; then
    echo "⚠️ No global commands found to sync"
    if [[ "$clean" == "true" ]]; then
        echo "Proceeding with cleanup only..."
    else
        exit 0
    fi
fi
```

### Step 3: Discover Existing Project Commands
```bash
echo ""
echo "🔍 Analyzing existing project commands..."

existing_links=()
existing_files=()
broken_links=()

# Find all existing command files and symlinks
while IFS= read -r -d '' file; do
    rel_path="${file#$local_dir/}"
    
    if [[ -L "$file" ]]; then
        # It's a symlink
        if [[ -e "$file" ]]; then
            # Symlink is valid
            existing_links+=("$rel_path")
        else
            # Symlink is broken
            broken_links+=("$rel_path")
        fi
    elif [[ -f "$file" ]]; then
        # It's a regular file
        existing_files+=("$rel_path")
    fi
done < <(find "$local_dir" -name "*.md" -print0 2>/dev/null || true)

echo "📊 Existing project commands:"
echo "  🔗 Valid symlinks: ${#existing_links[@]}"
echo "  📄 Regular files: ${#existing_files[@]}"  
echo "  💔 Broken symlinks: ${#broken_links[@]}"

if [[ ${#existing_links[@]} -gt 0 ]]; then
    echo "    Valid symlinks:"
    for link in "${existing_links[@]}"; do
        target=$(readlink "$local_dir/$link")
        echo "      🔗 $link → $target"
    done
fi

if [[ ${#existing_files[@]} -gt 0 ]]; then
    echo "    Regular files:"
    for file in "${existing_files[@]}"; do
        echo "      📄 $file"
    done
fi

if [[ ${#broken_links[@]} -gt 0 ]]; then
    echo "    Broken symlinks:"
    for broken in "${broken_links[@]}"; do
        target=$(readlink "$local_dir/$broken" 2>/dev/null || echo "unknown")
        echo "      💔 $broken → $target"
    done
fi
```

### Step 4: Plan Synchronization Actions
```bash
echo ""
echo "📋 Planning synchronization actions..."

actions_add=()
actions_update=()
actions_remove=()
actions_clean_broken=()
actions_conflicts=()

# Process each global command
for global_cmd in "${global_commands[@]}"; do
    local_path="$local_dir/$global_cmd"
    global_path="$global_dir/$global_cmd"
    
    if [[ -L "$local_path" ]]; then
        # Local symlink exists
        current_target=$(readlink "$local_path")
        if [[ "$current_target" == "$global_path" ]]; then
            # Already correctly linked - no action needed
            continue
        else
            # Symlink points to wrong location - update needed
            actions_update+=("$global_cmd")
        fi
    elif [[ -f "$local_path" ]]; then
        # Regular file exists - potential conflict
        if [[ "$force" == "true" ]]; then
            actions_update+=("$global_cmd")
        else
            actions_conflicts+=("$global_cmd")
        fi
    else
        # Doesn't exist locally - needs to be added
        # Ensure parent directory exists
        parent_dir=$(dirname "$local_path")
        if [[ "$parent_dir" != "$local_dir" ]] && [[ ! -d "$parent_dir" ]]; then
            mkdir -p "$parent_dir" 2>/dev/null || true
        fi
        actions_add+=("$global_cmd")
    fi
done

# Process broken symlinks for cleanup
for broken in "${broken_links[@]}"; do
    actions_clean_broken+=("$broken")
done

# Process symlinks that no longer have global counterparts
if [[ "$clean" == "true" ]]; then
    for link in "${existing_links[@]}"; do
        # Check if this symlink points to a global command that still exists
        target=$(readlink "$local_dir/$link")
        if [[ "$target" == "$global_dir"* ]]; then
            # It's a global symlink, check if target still exists
            if [[ ! -f "$target" ]]; then
                actions_remove+=("$link")
            fi
        fi
    done
fi

# Display planned actions
echo ""
echo "📋 Planned actions:"
echo "  ➕ Add new symlinks: ${#actions_add[@]}"
echo "  🔄 Update existing symlinks: ${#actions_update[@]}"
echo "  🗑️ Remove obsolete symlinks: ${#actions_remove[@]}"
echo "  🧹 Clean broken symlinks: ${#actions_clean_broken[@]}"
echo "  ⚠️ Conflicts (need --force): ${#actions_conflicts[@]}"

if [[ ${#actions_add[@]} -gt 0 ]]; then
    echo ""
    echo "  ➕ Will add:"
    for cmd in "${actions_add[@]}"; do
        echo "    🔗 $cmd → $global_dir/$cmd"
    done
fi

if [[ ${#actions_update[@]} -gt 0 ]]; then
    echo ""
    echo "  🔄 Will update:"
    for cmd in "${actions_update[@]}"; do
        echo "    🔗 $cmd → $global_dir/$cmd"
    done
fi

if [[ ${#actions_remove[@]} -gt 0 ]]; then
    echo ""
    echo "  🗑️ Will remove:"
    for cmd in "${actions_remove[@]}"; do
        echo "    ❌ $cmd (global command no longer exists)"
    done
fi

if [[ ${#actions_clean_broken[@]} -gt 0 ]]; then
    echo ""
    echo "  🧹 Will clean broken:"
    for cmd in "${actions_clean_broken[@]}"; do
        target=$(readlink "$local_dir/$cmd" 2>/dev/null || echo "unknown")
        echo "    💔 $cmd → $target"
    done
fi

if [[ ${#actions_conflicts[@]} -gt 0 ]]; then
    echo ""
    echo "  ⚠️ Conflicts (use --force to overwrite):"
    for cmd in "${actions_conflicts[@]}"; do
        echo "    ⚠️ $cmd (regular file exists, would overwrite)"
    done
fi
```

### Step 5: Execute Actions (or Dry Run)
```bash
if [[ "$dry_run" == "true" ]]; then
    echo ""
    echo "🔍 DRY RUN: No changes made"
    echo "Remove --dry-run to execute these actions"
    exit 0
fi

# Confirm if there are conflicts and no force flag
if [[ ${#actions_conflicts[@]} -gt 0 ]] && [[ "$force" != "true" ]]; then
    echo ""
    echo "❌ Conflicts detected. Use --force to overwrite existing files:"
    for conflict in "${actions_conflicts[@]}"; do
        echo "  ⚠️ $conflict"
    done
    echo ""
    echo "Or rename/move conflicting files manually"
    exit 1
fi

# Execute actions
total_actions=$((${#actions_add[@]} + ${#actions_update[@]} + ${#actions_remove[@]} + ${#actions_clean_broken[@]}))

if [[ $total_actions -eq 0 ]]; then
    echo ""
    echo "✅ No changes needed - all symlinks are up to date"
    exit 0
fi

echo ""
echo "⚡ Executing synchronization..."

# Add new symlinks
for cmd in "${actions_add[@]}"; do
    local_path="$local_dir/$cmd"
    global_path="$global_dir/$cmd"
    
    echo "  ➕ Adding: $cmd"
    ln -sf "$global_path" "$local_path"
    
    if [[ $? -eq 0 ]]; then
        echo "    ✅ Created symlink: $cmd"
    else
        echo "    ❌ Failed to create symlink: $cmd"
    fi
done

# Update existing symlinks  
for cmd in "${actions_update[@]}"; do
    local_path="$local_dir/$cmd"
    global_path="$global_dir/$cmd"
    
    echo "  🔄 Updating: $cmd"
    rm -f "$local_path"
    ln -sf "$global_path" "$local_path"
    
    if [[ $? -eq 0 ]]; then
        echo "    ✅ Updated symlink: $cmd"
    else
        echo "    ❌ Failed to update symlink: $cmd"
    fi
done

# Remove obsolete symlinks
for cmd in "${actions_remove[@]}"; do
    local_path="$local_dir/$cmd"
    
    echo "  🗑️ Removing: $cmd"
    rm -f "$local_path"
    
    if [[ $? -eq 0 ]]; then
        echo "    ✅ Removed obsolete symlink: $cmd"
    else
        echo "    ❌ Failed to remove symlink: $cmd"
    fi
done

# Clean broken symlinks
for cmd in "${actions_clean_broken[@]}"; do
    local_path="$local_dir/$cmd"
    
    echo "  🧹 Cleaning broken: $cmd"
    rm -f "$local_path"
    
    if [[ $? -eq 0 ]]; then
        echo "    ✅ Cleaned broken symlink: $cmd"
    else
        echo "    ❌ Failed to clean symlink: $cmd"
    fi
done
```

### Step 6: Verification and Summary  
```bash
echo ""
echo "🔍 Verifying synchronization..."

# Re-scan to verify results
verified_links=0
failed_links=0

for global_cmd in "${global_commands[@]}"; do
    local_path="$local_dir/$global_cmd"
    global_path="$global_dir/$global_cmd"
    
    if [[ -L "$local_path" ]] && [[ "$(readlink "$local_path")" == "$global_path" ]] && [[ -e "$local_path" ]]; then
        ((verified_links++))
    else
        ((failed_links++))
        echo "  ❌ Verification failed: $global_cmd"
    fi
done

echo ""
echo "🎯 SYNCHRONIZATION COMPLETE"
echo "=========================="
echo "📊 Results:"
echo "  ✅ Successfully linked: $verified_links"
echo "  ❌ Failed links: $failed_links" 
echo "  📄 Total global commands: ${#global_commands[@]}"

if [[ $failed_links -eq 0 ]]; then
    echo ""
    echo "🎉 All global commands successfully synchronized!"
    echo ""
    echo "Available commands:"
    for cmd in "${global_commands[@]}"; do
        # Convert file path to command format
        command_name=$(echo "$cmd" | sed 's|^pm/|/pm:|' | sed 's|\.md$||' | sed 's|^|/|')
        echo "  $command_name"
    done
    
    echo ""
    echo "💡 Usage tips:"
    echo "  • Run /pm:update regularly to stay in sync"
    echo "  • Use /pm:update --dry-run to preview changes"
    echo "  • Use /pm:update --clean to remove obsolete links"
    
    exit 0
else
    echo ""
    echo "⚠️ Some synchronization issues occurred"
    echo "Check the error messages above and try again"
    exit 1
fi
```

This command provides comprehensive synchronization of project commands with global bert-global commands, including:
- Adding new command symlinks  
- Updating existing symlinks to correct targets
- Removing obsolete symlinks (with --clean flag)
- Cleaning up broken symlinks
- Conflict detection and resolution with --force flag
- Dry-run mode to preview changes
- Full verification of results