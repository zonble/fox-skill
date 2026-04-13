#!/usr/bin/env bash

set -euo pipefail

SOURCE_ROOT="${1:-$PWD}"
TARGET_DIRS=(
  "$HOME/.codex/skills"
  "$HOME/.claude/skills"
  "$HOME/.gemini/skills"
)

is_skill_dir() {
  local dir="$1"
  [[ -d "$dir" && -f "$dir/SKILL.md" ]]
}

ensure_target_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

link_skill() {
  local source_dir="$1"
  local target_root="$2"
  local skill_name
  local target_path
  local current_target

  skill_name="$(basename "$source_dir")"
  target_path="$target_root/$skill_name"

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_dir" ]]; then
      printf 'skip: %s already points to %s\n' "$target_path" "$source_dir"
      return
    fi

    rm "$target_path"
  elif [[ -e "$target_path" ]]; then
    printf 'warn: %s exists and is not a symlink, skipped\n' "$target_path" >&2
    return
  fi

  ln -s "$source_dir" "$target_path"
  printf 'linked: %s -> %s\n' "$target_path" "$source_dir"
}

main() {
  local source_dir
  local target_dir

  for target_dir in "${TARGET_DIRS[@]}"; do
    ensure_target_dir "$target_dir"
  done

  for source_dir in "$SOURCE_ROOT"/*; do
    [[ -d "$source_dir" ]] || continue
    is_skill_dir "$source_dir" || continue

    for target_dir in "${TARGET_DIRS[@]}"; do
      link_skill "$source_dir" "$target_dir"
    done
  done
}

main "$@"
