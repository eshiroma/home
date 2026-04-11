---
name: anki-vm
description: Start, stop, and SSH into the auto-anki GCE dev VM (auto-anki-dev, us-central1-a)
argument-hint: [start|stop|ssh|status]
---

The auto-anki GCE VM runs the Android emulator and Claude Code for autonomous build/test loops.

- Instance: `auto-anki-dev`, zone: `us-central1-a`, project: `firm-pentameter-309918`
- SSH alias: `anki-vm` (updated automatically on start)
- Idle auto-shutdown: after 2h with no SSH or tmux sessions

## Start

```bash
anki-vm-start
```

This starts the VM, updates `~/.ssh/config` with the new IP, and waits for the emulator to be ready.

## Stop

```bash
anki-vm-stop
```

## SSH

```bash
ssh anki-vm
```

Once in, attach to the tmux session if one exists:
```bash
tmux attach || tmux new -s main
```

## Check VM status

```bash
gcloud compute instances describe auto-anki-dev \
  --zone=us-central1-a \
  --project=firm-pentameter-309918 \
  --format='get(status)'
```

## Troubleshooting

- **Emulator not ready after start**: VM takes ~2 min to boot emulator; `anki-vm-start` waits, but if it times out, SSH in and run `adb shell getprop sys.boot_completed` until it returns `1`
- **Permission denied (adb/emulator)**: `erika` must be in `kvm` group — requires new SSH session after adding (`sudo usermod -aG kvm erika`)
- **`ANTHROPIC_API_KEY` missing**: fetched from GCP Secret Manager on boot via startup script; if missing, check VM has `cloud-platform` scope (`gcloud compute instances describe ... --format='get(serviceAccounts[0].scopes)'`)
- **Secrets stale after scope change**: use metadata server REST API instead of `gcloud secrets` CLI — the CLI token can be stale after scope changes
- **Claude Code not updated**: auto-update runs on boot; if outdated, SSH in and run `claude update`
