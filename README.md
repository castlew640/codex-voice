# codex-voice

Push-to-talk voice typing for WSL. Press Space, talk, and press Space again. Your speech is transcribed **locally** with [faster-whisper](https://github.com/SYSTRAN/faster-whisper) and copied to the Windows clipboard, so you can paste it into Codex, Claude Code, a chat box, or anything else with Ctrl+V.

It was built for accessibility, for people who find typing slow or painful:

- **Nothing leaves your computer.** Audio is transcribed on your CPU with no API key and no cloud service.
- **Clear visual feedback.** A status bar across the bottom of the terminal always shows what the tool is doing, and it turns **red while recording**. The newest transcript is shown in **bold green** and older ones are dimmed.
- **Few keys.** Everything is done with Space, Esc, and one command, `/clear`.

## Requirements

- Windows 10/11 with **WSL 2** and WSLg. WSLg gives WSL access to your microphone and is included in current WSL versions.
- An Ubuntu/Debian distro (other distros work if you install the same packages)
- `sox` and `python3-venv`:

  ```bash
  sudo apt install sox python3-venv
  ```

- Optional: [Windows Terminal](https://aka.ms/terminal) and systemd, both needed only for `--autostart`

## Install

```bash
git clone https://github.com/castlew640/codex-voice.git
cd codex-voice
./install.sh
```

This creates a private Python environment in `~/.local/share/codex-voice` and installs the `codex-voice` command to `~/.local/bin`. The first run downloads the Whisper speech model (about 500 MB).

### Keep it open automatically (optional)

```bash
./install.sh --autostart
```

This opens the voice window in Windows Terminal when WSL starts and reopens it within about 20 seconds if it's closed. It requires systemd to be enabled in WSL: add the following to `/etc/wsl.conf`, then run `wsl --shutdown` from Windows.

```ini
[boot]
systemd=true
```

To turn it off: `systemctl --user disable --now codex-voice-watchdog.timer`

## Usage

```bash
codex-voice
```

| Key / command     | What it does                                           |
| ----------------- | ------------------------------------------------------ |
| `voice` + Enter   | Arm the microphone                                     |
| **Space**         | Start recording; press again to stop and transcribe    |
| **Esc**           | While recording: cancel. While armed: disarm           |
| `/clear` + Enter  | Clear old transcripts from the screen (stays armed)    |
| Ctrl+C            | Quit                                                   |

After each recording, the text is on your clipboard. Switch to the app you want and press **Ctrl+V**.

### Options

- `codex-voice --model base.en` uses a smaller, faster model that is a bit less accurate. The default is `small.en`. `medium.en` is more accurate but slower.
- `codex-voice --loop` is hands-free mode with no keys: speak, pause for about 2 seconds, and the text is copied automatically. Then it repeats.

### Tuning the vocabulary

Whisper is primed with a list of developer terms (git, npm, PowerShell…) so it doesn't turn them into ordinary words. Edit `INITIAL_PROMPT` near the top of `codex-voice` to add names or jargon you use often, then re-run `./install.sh`.

## Uninstall

```bash
./install.sh --uninstall
```

## License

MIT
