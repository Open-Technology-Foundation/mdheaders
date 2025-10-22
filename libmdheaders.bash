#!/usr/bin/env bash
# libmdheaders.bash - Library for manipulating markdown header levels
# Handles upgrading/downgrading headers while preserving code blocks
# NOTE: This is a library file meant to be sourced, not executed directly

# Process markdown content and modify header levels
# Args:
#   $1: delta (positive=upgrade, negative=downgrade)
#   $2: error mode ("skip" or "stop")
#   $3: quiet mode (0=verbose, 1=quiet)
# Input: markdown content via stdin
# Output: modified markdown to stdout
# Returns: 0 on success, 1 on error
mdh_process() {
  local -i delta=$1
  local -- error_mode="${2:-skip}"
  local -i quiet="${3:-0}"

  local -i in_code_block=0
  local -- fence_type=""
  local -- line
  local -i modified=0
  local -i skipped=0
  local -i line_num=0

  while IFS= read -r line; do
    ((line_num+=1))

    # Check for code fence toggle (``` or ~~~)
    # Using variables to avoid backtick interpretation issues
    local -- fence_regex='^[[:space:]]*(```|~~~)'
    if [[ "$line" =~ $fence_regex ]]; then
      if ((in_code_block)); then
        # Check if closing fence matches opening type
        local -- close_regex="^[[:space:]]*${fence_type}"
        if [[ "$line" =~ $close_regex ]]; then
          in_code_block=0
          fence_type=""
        fi
      else
        # Opening fence
        in_code_block=1
        fence_type="${BASH_REMATCH[1]}"
      fi
      printf '%s\n' "$line"
      continue
    fi

    # Process headers only when NOT in code block
    if ((in_code_block == 0)) && [[ "$line" =~ ^(#+)([[:space:]]+.*)?$ ]]; then
      local -- hashes="${BASH_REMATCH[1]}"
      local -- rest="${BASH_REMATCH[2]}"
      local -i current_level=${#hashes}
      local -i new_level=$((current_level + delta))

      # Validate new level (H1=1 to H6=6)
      if ((new_level < 1)); then
        ((skipped+=1))
        if ((quiet == 0)); then
          printf 'Warning: Line %d: Cannot downgrade H%d (already at minimum)\n' "$line_num" "$current_level" >&2
        fi
        if [[ "$error_mode" == "stop" ]]; then
          return 1
        fi
        printf '%s\n' "$line"
      elif ((new_level > 6)); then
        ((skipped+=1))
        if ((quiet == 0)); then
          printf 'Warning: Line %d: Cannot upgrade H%d (already at maximum)\n' "$line_num" "$current_level" >&2
        fi
        if [[ "$error_mode" == "stop" ]]; then
          return 1
        fi
        printf '%s\n' "$line"
      else
        # Create new header with adjusted level
        local -- new_hashes
        new_hashes=$(printf '#%.0s' $(seq 1 "$new_level"))
        printf '%s%s\n' "$new_hashes" "$rest"
        ((modified+=1))
      fi
    else
      # Not a header or inside code block - output as-is
      printf '%s\n' "$line"
    fi
  done

  # Warn if file ended with unclosed code block
  if ((in_code_block && quiet == 0)); then
    printf 'Warning: File ended with unclosed code block\n' >&2
  fi

  # Report summary
  if ((quiet == 0 && (modified > 0 || skipped > 0))); then
    printf 'Processed %d header(s), skipped %d\n' "$modified" "$skipped" >&2
  fi

  # Return success if we modified anything, or if nothing needed modification
  ((skipped > 0 && modified == 0)) && return 1
  return 0
}

# Upgrade headers by N levels
# Args:
#   $1: number of levels to upgrade (default: 1)
#   $2: error mode ("skip" or "stop", default: "skip")
#   $3: quiet mode (0=verbose, 1=quiet, default: 0)
# Input: markdown content via stdin
# Output: modified markdown to stdout
mdh_upgrade() {
  local -i levels="${1:-1}"
  local -- error_mode="${2:-skip}"
  local -i quiet="${3:-0}"

  if ((levels < 1)); then
    printf 'Error: Upgrade levels must be >= 1\n' >&2
    return 1
  fi

  mdh_process "$levels" "$error_mode" "$quiet"
}

# Downgrade headers by N levels
# Args:
#   $1: number of levels to downgrade (default: 1)
#   $2: error mode ("skip" or "stop", default: "skip")
#   $3: quiet mode (0=verbose, 1=quiet, default: 0)
# Input: markdown content via stdin
# Output: modified markdown to stdout
mdh_downgrade() {
  local -i levels="${1:-1}"
  local -- error_mode="${2:-skip}"
  local -i quiet="${3:-0}"

  if ((levels < 1)); then
    printf 'Error: Downgrade levels must be >= 1\n' >&2
    return 1
  fi

  mdh_process "-$levels" "$error_mode" "$quiet"
}

# Detect minimum header level in document
# Args: none
# Input: markdown content via stdin
# Output: minimum header level (1-6) to stdout
# Returns: 0 if headers found, 1 if no headers
mdh_detect_min_level() {
  local -i in_code_block=0
  local -- fence_type=""
  local -- line
  local -i min_level=7  # Start higher than max (H6=6)

  while IFS= read -r line; do
    # Check for code fence toggle
    local -- fence_regex='^[[:space:]]*(```|~~~)'
    if [[ "$line" =~ $fence_regex ]]; then
      if ((in_code_block)); then
        local -- close_regex="^[[:space:]]*${fence_type}"
        if [[ "$line" =~ $close_regex ]]; then
          in_code_block=0
          fence_type=""
        fi
      else
        in_code_block=1
        fence_type="${BASH_REMATCH[1]}"
      fi
      continue
    fi

    # Check for headers only when NOT in code block
    if ((in_code_block == 0)) && [[ "$line" =~ ^(#+)([[:space:]]+.*)?$ ]]; then
      local -- hashes="${BASH_REMATCH[1]}"
      local -i level=${#hashes}
      # Track minimum level found
      ((level < min_level)) && min_level=$level
    fi
  done

  # Return error if no headers found
  if ((min_level == 7)); then
    return 1
  fi

  printf '%d' "$min_level"
  return 0
}

# Normalize document to start at specified header level
# Args:
#   $1: target starting level (1-6)
#   $2: error mode ("skip" or "stop", default: "skip")
#   $3: quiet mode (0=verbose, 1=quiet, default: 0)
# Input: markdown content via stdin
# Output: modified markdown to stdout
# Returns: 0 on success, 1 on error
mdh_normalize() {
  local -i target_level="${1:-1}"
  local -- error_mode="${2:-skip}"
  local -i quiet="${3:-0}"

  # Validate target level
  if ((target_level < 1 || target_level > 6)); then
    printf 'Error: Target level must be between 1 and 6\n' >&2
    return 1
  fi

  # Store stdin to temp file so we can read it twice
  local -- temp_content
  temp_content=$(mktemp) || {
    printf 'Error: Failed to create temporary file\n' >&2
    return 1
  }
  trap 'rm -f "${temp_content:-}"' RETURN

  # Read all input to temp file
  cat > "$temp_content"

  # First pass: detect minimum level
  local -i min_level
  if ! min_level=$(mdh_detect_min_level < "$temp_content"); then
    printf 'Error: No headers found in document\n' >&2
    rm -f "$temp_content"
    return 1
  fi

  # Calculate delta needed
  local -i delta=$((target_level - min_level))

  # Report what we're doing
  if ((quiet == 0)); then
    printf 'Detected minimum level: H%d, target: H%d, delta: %+d\n' "$min_level" "$target_level" "$delta" >&2
  fi

  # If already at target, just output as-is
  if ((delta == 0)); then
    if ((quiet == 0)); then
      printf 'Document already normalized to H%d\n' "$target_level" >&2
    fi
    cat "$temp_content"
    rm -f "$temp_content"
    return 0
  fi

  # Second pass: apply delta
  mdh_process "$delta" "$error_mode" "$quiet" < "$temp_content"
  local result=$?

  rm -f "$temp_content"
  return "$result"
}

#fin
