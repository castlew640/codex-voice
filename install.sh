#!/usr/bin/env bash
# Installs codex-voice for the current user (no sudo needed once deps exist).
#
#   ./install.sh               install / update
#   ./install.sh --autostart   also open the voice window at login and
#                              relaunch it if closed (systemd user timer)
#   ./install.sh --uninstall   remove everything this script installed
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/codex-voice"
CONFIG_DIR="$HOME/.config/codex-voice"
UNIT_DIR="$HOME/.config/systemd/user"
TIMER=codex-voice-watchdog.timer

autostart=0
case "${1:-}" in
    "") ;;
    --autostart) autostart=1 ;;
    --uninstall)
        if [[ -e "$UNIT_DIR/$TIMER" ]]; then
            systemctl --user disable --now "$TIMER" 2>/dev/null || true
            rm -f "$UNIT_DIR/codex-voice-watchdog.service" "$UNIT_DIR/$TIMER"
            systemctl --user daemon-reload 2>/dev/null || true
        fi
        rm -f "$BIN_DIR/codex-voice" "$BIN_DIR/codex-voice-watchdog"
        rm -rf "$SHARE_DIR" "$CONFIG_DIR"
        echo "codex-voice removed."
        exit 0
        ;;
    *) echo "usage: $0 [--autostart | --uninstall]" >&2; exit 2 ;;
esac

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "warning: this doesn't look like WSL; the clipboard and window launcher need Windows." >&2
fi

missing=()
command -v sox >/dev/null || missing+=(sox)
python3 -c "import venv, ensurepip" 2>/dev/null || missing+=(python3-venv)
if ((${#missing[@]})); then
    echo "Missing packages: ${missing[*]}"
    echo "Install them with:  sudo apt install ${missing[*]}"
    exit 1
fi

echo "Setting up Python environment in $SHARE_DIR/venv ..."
mkdir -p "$SHARE_DIR/models"
python3 -m venv "$SHARE_DIR/venv"
"$SHARE_DIR/venv/bin/pip" install --quiet --upgrade pip
"$SHARE_DIR/venv/bin/pip" install --quiet -r "$REPO_DIR/requirements.txt"

mkdir -p "$BIN_DIR"
install -m 755 "$REPO_DIR/codex-voice" "$REPO_DIR/codex-voice-watchdog" "$BIN_DIR/"
echo "Installed codex-voice to $BIN_DIR"

if ((autostart)); then
    if ! command -v systemctl >/dev/null || ! systemctl --user show-environment >/dev/null 2>&1; then
        echo "error: --autostart needs systemd. Add this to /etc/wsl.conf, run 'wsl --shutdown'" >&2
        echo "from Windows, then re-run:  [boot]  systemd=true" >&2
        exit 1
    fi
    wt="$(command -v wt.exe || true)"
    if [[ -z "$wt" ]]; then
        localappdata="$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')"
        [[ -n "$localappdata" ]] && wt="$(wslpath "$localappdata")/Microsoft/WindowsApps/wt.exe"
    fi
    if [[ -z "$wt" || ! -e "$wt" ]]; then
        echo "error: couldn't find Windows Terminal (wt.exe). Install it from the Microsoft Store." >&2
        exit 1
    fi
    mkdir -p "$CONFIG_DIR" "$UNIT_DIR"
    printf 'CODEX_VOICE_WT_EXE=%s\nCODEX_VOICE_DISTRO=%s\n' "$wt" "${WSL_DISTRO_NAME:?not running under WSL}" \
        > "$CONFIG_DIR/watchdog.env"
    install -m 644 "$REPO_DIR"/systemd/codex-voice-watchdog.{service,timer} "$UNIT_DIR/"
    systemctl --user daemon-reload
    systemctl --user enable --now "$TIMER"
    echo "Autostart enabled: the voice window opens at login and reopens if closed."
    echo "Turn it off with:  systemctl --user disable --now $TIMER"
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "note: $BIN_DIR isn't on your PATH yet -- open a new terminal (or add it to ~/.bashrc)." ;;
esac

echo "Done. Run 'codex-voice' to start (the first run downloads the ~500 MB speech model)."
