wt() {
  if [ $# -lt 1 ]; then
    echo "Usage:"
    echo "  wt <branch>"
    echo "  wt ls"
    echo "  wt remove [--force|-f] [<branch>]"
    return 1
  fi

  cmd="$1"
  shift

  # ----------------------------------------------
  # LIST COMMAND
  # ----------------------------------------------

  if [ "$cmd" = "ls" ]; then
    git worktree list
    return
  fi

  # Helper: resolve the worktree path for a branch
  _worktree_for_branch() {
    git worktree list --porcelain 2>/dev/null \
      | awk -v want="refs/heads/$1" '
          /^worktree / { path=$2 }
          /^branch /    { if ($2==want) { print path; exit } }
        '
  }

  # Helper: find another worktree to cd into after removal
  # Prioritizes main worktree (first in list), then any other worktree
  _find_other_worktree() {
    local exclude="$1"
    git worktree list --porcelain \
      | awk '/^worktree /{print $2}' \
      | while read p; do
          [ "$p" = "$exclude" ] && continue
          echo "$p"
          break
        done
  }

  # ----------------------------------------------
  # REMOVE COMMAND
  # ----------------------------------------------

  if [ "$cmd" = "remove" ]; then
    force=""
    if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
      force="--force"
      shift
    fi
    branch="$1"

    # If no branch specified, remove current worktree
    if [ -z "$branch" ]; then
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }

      # Check if we're in the main worktree
      main_wt=$(git worktree list --porcelain | awk 'NR==1 && /^worktree /{print $2}')

      if [ "$repo_root" = "$main_wt" ]; then
        echo "You are in the main worktree. Please specify a branch to remove."
        echo "Usage: wt remove [--force|-f] <branch>"
        return 1
      fi

      wtpath="$repo_root"

      # Get the branch name for this worktree
      branch=$(git worktree list --porcelain | awk -v want="$wtpath" '
        /^worktree / { path=$2 }
        /^branch /   { if (path == want) { sub(/^refs\/heads\//, "", $2); print $2; exit } }
      ')

      echo "Current worktree: $wtpath (branch: $branch)"
      read -r "answer?Remove this worktree? [y/N] "

      case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; return 1 ;;
      esac
    else
      wtpath="$(_worktree_for_branch "$branch")"

      if [ -z "$wtpath" ]; then
        echo "No worktree found for '$branch'"
        return 1
      fi
    fi

    curdir="$(pwd)"

    # Determine where to move BEFORE removing (if we're in the worktree)
    move_to=""
    if [[ "$curdir" == "$wtpath"* ]]; then
      other="$(_find_other_worktree "$wtpath")"
      if [ -n "$other" ]; then
        move_to="$other"
      else
        move_to="$(dirname "$wtpath")"
      fi
    fi

    # Move first if needed
    if [ -n "$move_to" ]; then
      echo "Moving to: $move_to"
      cd "$move_to"
    fi

    # Now remove the worktree
    echo "Removing worktree for '$branch' at $wtpath"
    if git worktree remove $force "$wtpath"; then
      echo "Removed."
    else
      echo "Remove failed."
      return 1
    fi

    return
  fi

  # ----------------------------------------------
  # OPEN / CREATE WORKTREE
  # ----------------------------------------------

  branch="$cmd"
  folder="${branch##*/}"

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1; }

  base_dir=${GIT_WT_BASE:-"$(dirname "$repo_root")"}
  target="$base_dir/$folder"

  existing_path="$(_worktree_for_branch "$branch")"

  if [ -n "$existing_path" ]; then
    echo "Found worktree: $existing_path"
    cd "$existing_path"
    return
  fi

  # Already on this branch?
  curr_branch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$curr_branch" = "$branch" ]; then
    echo "Already on branch '$branch'. Moving to repo root."
    cd "$repo_root"
    return
  fi

  # Ask to create
  echo "Worktree for '$branch' does not exist."
  echo "Target: $target"
  read -r "answer?Create this worktree? [y/N] "

  case "$answer" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; return 1 ;;
  esac

  # Determine branch source
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Using local branch."
    git worktree add "$target" "$branch"
  else
    echo "Checking remote..."
    git fetch --quiet
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      echo "Creating branch from origin/$branch"
      git worktree add -b "$branch" "$target" "origin/$branch"
    elif git show-ref --verify --quiet "refs/remotes/origin/main"; then
      echo "Creating new branch from origin/main"
      git worktree add -b "$branch" "$target" "origin/main"
    else
      echo "Creating new branch from HEAD"
      git worktree add -b "$branch" "$target" "HEAD"
    fi
  fi

  cd "$target"
}
