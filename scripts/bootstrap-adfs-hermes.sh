#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_HOME="${SOURCE_HERMES_HOME:-$HOME/.hermes}"
TARGET_HOME="${ADFS_HERMES_HOME:-$HOME/.adfs-hermes}"
SANDBOX_DIR="${ADFS_HERMES_SANDBOX:-$HOME/hermes-sandbox}"
QBO_REPO="${ADFS_QBO_REPO:-$HOME/Documents/CodingProjects/adfs-qbo-mcp}"
FIRM_REPO="${ADFS_FIRM_REPO:-$HOME/Documents/CodingProjects/adfs-firm-supabase-mcp}"
ADFS_CONFIG_DIR="${ADFS_SHARED_CONFIG_DIR:-$HOME/.config/adfs}"
LAUNCHER_PATH="$HOME/.local/bin/adfs-hermes"
SKIN_SOURCE="$REPO_DIR/assets/skins/light-paper.yaml"

log() {
  printf '==> %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

find_uv() {
  if command -v uv >/dev/null 2>&1; then
    command -v uv
    return
  fi
  if [ -x "$HOME/.local/bin/uv" ]; then
    printf '%s\n' "$HOME/.local/bin/uv"
    return
  fi
  if [ -x "$HOME/.cargo/bin/uv" ]; then
    printf '%s\n' "$HOME/.cargo/bin/uv"
    return
  fi
  return 1
}

copy_if_exists() {
  local src="$1"
  local dest="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
  fi
}

mkdir -p "$TARGET_HOME" "$SANDBOX_DIR" "$HOME/.local/bin"
mkdir -p "$SANDBOX_DIR/bin"

log "Initializing git submodules"
git -C "$REPO_DIR" submodule update --init --recursive

UV_CMD="$(find_uv)" || {
  warn "uv not found. Install uv first: https://docs.astral.sh/uv/getting-started/installation/"
  exit 1
}

if [ ! -d "$REPO_DIR/venv" ]; then
  log "Creating virtual environment"
  "$UV_CMD" venv "$REPO_DIR/venv" --python 3.11
fi

export VIRTUAL_ENV="$REPO_DIR/venv"

log "Installing adfs-hermes into the virtual environment"
"$UV_CMD" pip install -e "$REPO_DIR[all]"
"$UV_CMD" pip install -e "$REPO_DIR/mini-swe-agent"
if [ -f "$REPO_DIR/tinker-atropos/pyproject.toml" ]; then
  "$UV_CMD" pip install -e "$REPO_DIR/tinker-atropos" || warn "tinker-atropos install skipped"
fi

if [ ! -f "$TARGET_HOME/.adfs-bootstrap-complete" ]; then
  log "Migrating reusable Hermes state into $TARGET_HOME"
  copy_if_exists "$SOURCE_HOME/.env" "$TARGET_HOME/.env"
  copy_if_exists "$SOURCE_HOME/auth.json" "$TARGET_HOME/auth.json"
  copy_if_exists "$SOURCE_HOME/SOUL.md" "$TARGET_HOME/SOUL.md"
  copy_if_exists "$SOURCE_HOME/config.yaml" "$TARGET_HOME/config.yaml"
  copy_if_exists "$SOURCE_HOME/memories" "$TARGET_HOME/memories"
  copy_if_exists "$SOURCE_HOME/skills" "$TARGET_HOME/skills"
  copy_if_exists "$SOURCE_HOME/sessions" "$TARGET_HOME/sessions"
  copy_if_exists "$SOURCE_HOME/state.db" "$TARGET_HOME/state.db"
  copy_if_exists "$SOURCE_HOME/state.db-shm" "$TARGET_HOME/state.db-shm"
  copy_if_exists "$SOURCE_HOME/state.db-wal" "$TARGET_HOME/state.db-wal"
  copy_if_exists "$SOURCE_HOME/cron" "$TARGET_HOME/cron"
  copy_if_exists "$SOURCE_HOME/images" "$TARGET_HOME/images"
else
  log "Existing ADFS Hermes home found; preserving current state"
fi

mkdir -p "$TARGET_HOME/skins"
cp "$SKIN_SOURCE" "$TARGET_HOME/skins/light-paper.yaml"

log "Syncing bundled skills into $TARGET_HOME"
HERMES_HOME="$TARGET_HOME" "$REPO_DIR/venv/bin/python" "$REPO_DIR/tools/skills_sync.py" >/dev/null \
  || warn "Bundled skills sync skipped"

log "Writing ADFS Hermes runtime defaults"
HERMES_HOME="$TARGET_HOME" SANDBOX_DIR="$SANDBOX_DIR" QBO_REPO="$QBO_REPO" FIRM_REPO="$FIRM_REPO" ADFS_CONFIG_DIR="$ADFS_CONFIG_DIR" "$REPO_DIR/venv/bin/python" - <<'PY'
from pathlib import Path
import os
import yaml

home = Path(os.environ["HERMES_HOME"])
sandbox = Path(os.environ["SANDBOX_DIR"])
qbo_repo = Path(os.environ["QBO_REPO"]).expanduser()
firm_repo = Path(os.environ["FIRM_REPO"]).expanduser()
adfs_config_dir = Path(os.environ["ADFS_CONFIG_DIR"]).expanduser()
config_path = home / "config.yaml"

if config_path.exists():
    data = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
else:
    data = {}

model = data.setdefault("model", {})
model["default"] = "MiniMax-M2.7-highspeed"
model["provider"] = "minimax"
model.pop("base_url", None)

agent = data.setdefault("agent", {})
agent["max_turns"] = 100
agent.setdefault("verbose", False)
agent.setdefault("reasoning_effort", "medium")

display = data.setdefault("display", {})
display["skin"] = "light-paper"
display.setdefault("compact", False)
display.setdefault("resume_display", "full")
display.setdefault("bell_on_complete", False)
display.setdefault("show_reasoning", False)
display.setdefault("tool_progress", "all")
display.setdefault("background_process_notifications", "all")

terminal = data.setdefault("terminal", {})
terminal["backend"] = "docker"
terminal["cwd"] = "/pilot"
terminal["docker_image"] = "nikolaik/python-nodejs:python3.11-nodejs20"
terminal["singularity_image"] = "docker://nikolaik/python-nodejs:python3.11-nodejs20"
terminal["modal_image"] = "nikolaik/python-nodejs:python3.11-nodejs20"
terminal["daytona_image"] = "nikolaik/python-nodejs:python3.11-nodejs20"
terminal["timeout"] = 180
terminal["container_cpu"] = 2
terminal["container_memory"] = 8192
terminal["container_disk"] = 20480
terminal["container_persistent"] = False
docker_volumes = [f"{sandbox}:/pilot"]
if qbo_repo.exists():
    docker_volumes.append(f"{qbo_repo}:/opt/adfs-qbo-mcp")
if firm_repo.exists():
    docker_volumes.append(f"{firm_repo}:/opt/adfs-firm")
if adfs_config_dir.exists():
    docker_volumes.append(f"{adfs_config_dir}:/root/.config/adfs")
terminal["docker_volumes"] = docker_volumes
terminal["lifetime_seconds"] = 900

memory = data.setdefault("memory", {})
memory["memory_enabled"] = True
memory["user_profile_enabled"] = True
memory["memory_char_limit"] = 6000
memory["user_char_limit"] = 2500
memory["nudge_interval"] = 14
memory["flush_min_turns"] = 10

compression = data.setdefault("compression", {})
compression.setdefault("enabled", False)
compression.setdefault("threshold", 0.85)
compression.setdefault("summary_model", "google/gemini-3-flash-preview")
compression.setdefault("summary_provider", "auto")

toolsets = data.get("toolsets")
if not toolsets:
    data["toolsets"] = ["all"]

config_path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
PY

log "Installing CLI wrapper helpers into sandbox"
cat > "$SANDBOX_DIR/bin/qbo" <<'EOF'
#!/bin/bash
set -euo pipefail
ADFS_ENV_FILE=""
if [ -r /root/.config/adfs/runtime.env ] && [ ! -L /root/.config/adfs/runtime.env ]; then
  ADFS_ENV_FILE=/root/.config/adfs/runtime.env
elif [ -r /root/.config/adfs/qbo.env ]; then
  ADFS_ENV_FILE=/root/.config/adfs/qbo.env
fi
if [ -n "$ADFS_ENV_FILE" ]; then
  set -a
  source "$ADFS_ENV_FILE"
  set +a
fi
export ADFS_SHARED_ENV_FILE="${ADFS_SHARED_ENV_FILE:-${ADFS_ENV_FILE:-/root/.config/adfs/qbo.env}}"
exec node /opt/adfs-qbo-mcp/bin/qbo.js "$@"
EOF
chmod +x "$SANDBOX_DIR/bin/qbo"

cat > "$SANDBOX_DIR/bin/adfs-firm" <<'EOF'
#!/bin/bash
set -euo pipefail
ADFS_ENV_FILE=""
if [ -r /root/.config/adfs/runtime.env ] && [ ! -L /root/.config/adfs/runtime.env ]; then
  ADFS_ENV_FILE=/root/.config/adfs/runtime.env
elif [ -r /root/.config/adfs/qbo.env ]; then
  ADFS_ENV_FILE=/root/.config/adfs/qbo.env
fi
if [ -n "$ADFS_ENV_FILE" ]; then
  set -a
  source "$ADFS_ENV_FILE"
  set +a
fi
export DEFAULT_WRITE_SOURCE="${DEFAULT_WRITE_SOURCE:-adfs-hermes}"
exec node /opt/adfs-firm/dist/cli.js "$@"
EOF
chmod +x "$SANDBOX_DIR/bin/adfs-firm"

cat > "$SANDBOX_DIR/bin/adfs-tools-info" <<'EOF'
#!/bin/bash
set -euo pipefail
cat <<INFO
ADFS Hermes firm CLI lane
- qbo wrapper: /pilot/bin/qbo
- adfs-firm wrapper: /pilot/bin/adfs-firm
- QBO repo mount: /opt/adfs-qbo-mcp
- Firm repo mount: /opt/adfs-firm
- Shared env dir: /root/.config/adfs

Examples:
  /pilot/bin/qbo companies
  /pilot/bin/qbo report pnl --realm-id <realm_id>
  /pilot/bin/adfs-firm health
  /pilot/bin/adfs-firm client find --query "ACME"
INFO
EOF
chmod +x "$SANDBOX_DIR/bin/adfs-tools-info"

cat > "$LAUNCHER_PATH" <<EOF
#!/bin/bash
set -euo pipefail
export HERMES_HOME="${TARGET_HOME}"
exec "${REPO_DIR}/venv/bin/hermes" "\$@"
EOF
chmod +x "$LAUNCHER_PATH"

touch "$TARGET_HOME/.adfs-bootstrap-complete"

log "ADFS Hermes bootstrap complete"
log "Launcher: $LAUNCHER_PATH"
log "Home: $TARGET_HOME"
log "Sandbox: $SANDBOX_DIR"
