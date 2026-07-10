# On-device validation checklist (relay + configuration management)

Everything in this PR is verified locally (shell logic, packaging, changelog),
but a few things can only be confirmed on a real ICR router connected to a
Cumulocity IoT tenant. Work through this once on an **ICR-1642 (v4i)** and once
on an **ICR-44xx (v4)**.

Legend: ☐ = to verify. Commands assume SSH to the router with `. /opt/tedge/env`
sourced (puts `tedge` on `PATH`).

## 0. Prerequisites

- ☐ tedge platform module installed and the device is **online** in Cumulocity
  (`MOD_TEDGE_ENABLED=1`, `MOD_TEDGE_C8Y_URL` set, registered).
- ☐ relay module installed; `/opt/relay/etc/settings` has `MOD_RELAY_ENABLED=1`
  and `MOD_RELAY_OUTPUTS` set (`"out0"` on ICR-1642; `"out0 out1"` on ICR-44xx).
- ☐ `/opt/relay/etc/init restart` run after editing settings.

## 1. Hardware I/O names (the main unknown)

- ☐ `io` exists and the output names are as expected — check the
  [CLI application note](https://icr.advantech.com/support/router-models/download/211/command-line-interface-20260423.pdf).
- ☐ `relay-control CLOSED out0` energizes the relay (hear the click / LED /
  multimeter continuity). `relay-control OPEN out0` releases it.
- ☐ ICR-44xx only: `relay-control CLOSED out1` drives the **second** output.
- ☐ Expansion-port output (if used): confirm its exact `io` name and that
  `relay-control CLOSED <name>` works; put that name in `MOD_RELAY_OUTPUTS`.

## 2. Operations are announced to Cumulocity (SmartREST 114)

- ☐ In Cumulocity, the device's **supported operations** include `c8y_Relay`
  and `c8y_RelayArray` (Device → Info, or the operations API). thin-edge should
  announce these automatically from `/opt/tedge/operations/c8y/`.
- ☐ If missing: `ls -l /opt/tedge/operations/c8y/` shows the relay symlinks;
  `tail -f /var/log/tedge/tedge-mapper-c8y.log` while running
  `tedge reconnect c8y`.

## 3. c8y_Relay (single) delivery + reflection

Watch operations: `tedge mqtt sub 'c8y/#'` in one shell.

- ☐ Send a `c8y_Relay` from Cumulocity (Device → Control, or POST
  `/devicecontrol/operations` with `{"deviceId":"...","c8y_Relay":{"relayState":"CLOSED"}}`).
- ☐ The relay physically switches, and the operation transitions
  **EXECUTING → SUCCESSFUL** (not FAILED).
- ☐ The device managed object gains `c8y_Relay: {relayState: CLOSED}` (Device →
  raw MO, or REST `GET /inventory/managedObjects/<id>`).

## 4. c8y_RelayArray (multi) + the RelayArray widget

- ☐ On start, `relay-seed` published the initial array — the device MO has
  `c8y_RelayArray: ["OPEN", ...]` with **one element per configured output**
  (`grep relay-seed /var/log/relay/seed.log`).
- ☐ Add a **RelayArray widget** to a dashboard for the device; it renders one
  toggle per output (1 on ICR-1642, 2 on ICR-44xx).
- ☐ Toggling relay 0 drives `out0`; on ICR-44xx toggling relay 1 drives `out1`.
- ☐ After a toggle, the widget reflects the new state (the `c8y_RelayArray`
  fragment updates) and the operation is SUCCESSFUL.

## 5. Configuration management (Pattern C)

- ☐ Device → **Configuration** tab lists `tedge.toml`, `system.toml` (from the
  bundle) **and** the `relay` type (registered by the relay module).
- ☐ `/opt/tedge/plugins/tedge-configuration-plugin.toml` still contains the
  bundle's `[[files]]` entries **plus** a `reg:relay` block (helper must not
  clobber the bundle's).
- ☐ Snapshot the `relay` config (Get snapshot) — it returns
  `/opt/relay/etc/settings`.
- ☐ Change `MOD_RELAY_OUTPUTS`, upload, and **Send configuration to device**;
  confirm the file on the device changed and the **next** relay operation uses
  the new output list (no restart required).
- ☐ Confirm the module **settings are not** exposed with secrets — the tedge
  module settings file is intentionally *not* a config type.

## 6. Enable/disable + boot behaviour

- ☐ With `MOD_RELAY_ENABLED=0`, `/opt/relay/etc/init status` reports disabled and
  no seed is published.
- ☐ Reboot the router: after boot, the device reconnects and the RelayArray
  widget still renders (seed re-published; `relay-seed` retries until the broker
  is up).

## 7. Both device families

- ☐ Repeat sections 1–6 on the other platform (`relay.v4i.tgz` on ICR-1642,
  `relay.v4.tgz` on ICR-44xx), confirming the single build works on both.

---

If any hardware step differs (e.g. the output isn't `out0`/`out1`), the only
file to change is `drive_output()` in `modules/relay/merge/bin/relay-control`
and/or the `MOD_RELAY_OUTPUTS` value — everything else is device-agnostic.
