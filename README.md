# wt
A simple git worktree helper that makes managing git worktrees effortless.

## Features

- Quickly switch to existing worktrees or create new ones
- Automatically handles branch creation from local, remote, or main branch
- Safely remove worktrees with automatic navigation
- Interactive confirmations to prevent accidents

## Installation

### Method 1: Direct sourcing

1. Clone or download this repository:
   ```bash
   git clone <repo-url> ~/wt
   ```

2. Add the following line to your shell configuration file:

   **For Bash** (`~/.bashrc` or `~/.bash_profile`):
   ```bash
   source ~/wt/wt.sh
   ```

   **For Zsh** (`~/.zshrc`):
   ```zsh
   source ~/wt/wt.sh
   ```

3. Reload your shell configuration:
   ```bash
   source ~/.bashrc  # or ~/.zshrc for Zsh
   ```

### Method 2: Zsh custom plugin (Oh My Zsh or similar)

1. Clone this repository into your Zsh custom plugins directory:
   ```bash
   git clone <repo-url> ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/wt
   ```

2. Add `wt` to your plugins array in `~/.zshrc`:
   ```zsh
   plugins=(... wt)
   ```

3. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## Usage

### Switch to or create a worktree

```bash
wt <branch-name>
```

This command will:
- Switch to the worktree if it already exists
- Prompt to create a new worktree if it doesn't exist
- Use an existing local branch, or fetch from remote
- Fall back to creating a new branch from `origin/main` or `HEAD`

**Example:**
```bash
wt feature/new-feature
```

### Remove a worktree

```bash
wt remove <branch-name>
wt remove --force <branch-name>  # Force removal even with uncommitted changes
wt remove -f <branch-name>       # Short form
```

This command will:
- Find the worktree for the specified branch
- Automatically navigate to another worktree if you're currently in the one being removed
- Remove the worktree directory

**Example:**
```bash
wt remove feature/old-feature
```

## Configuration

By default, worktrees are created in the parent directory of your repository. You can customize this location by setting the `GIT_WT_BASE` environment variable:

```bash
export GIT_WT_BASE="$HOME/projects/worktrees"
```

Add this to your shell configuration file to make it permanent.

## How It Works

The `wt` function is a shell wrapper around `git worktree` commands that:
1. Automatically determines the best location for worktrees
2. Handles branch existence checks (local and remote)
3. Manages safe directory navigation when removing worktrees
4. Provides user-friendly prompts and error messages
