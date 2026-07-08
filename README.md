# thin-edge.io Router App for Advantech ICR-1642

A [Router App](https://icr.advantech.com/products/software/user-modules) that runs
[thin-edge.io](https://thin-edge.io) on Advantech ICR cellular routers to connect
them to **Cumulocity IoT**. The primary target is the **ICR-1642** (platform
`v4i`, aarch64); the app also builds for `v2i`, `v3` and `v4`.

It packages the self-contained [thin-edge.io *standalone*](https://github.com/thin-edge/tedge-standalone)
runtime (the `tedge` multi-call binary + a statically linked Mosquitto broker)
into an ICR-OS `*.tgz` module, adds an ICR-OS service integration, and exposes
the Cumulocity connection settings on the router's Router App configuration page.

## What it does

Once installed and enabled, the app:

- registers the router as a device in Cumulocity IoT,
- forwards telemetry, events and alarms,
- enables remote device management: configuration, log collection, software
  management and remote commands,
- connects securely using thin-edge.io's **built-in MQTT bridge over TLS** (the
  bundled Mosquitto is only the local broker, so no SSL config is needed on it).

It supervises three daemons directly (no dependency on the host init system or
runit): `mosquitto`, `tedge-mapper-c8y`, and `tedge-agent`.

## Repository layout

```
advantec-tedge-router-app/
├── Makefile                # top-level build (PLATFORMS="v4i" ...)
├── Rules.mk                # locates ../ModulesSDK, pulls in SDK make macros
├── packages/
│   └── tedge/              # fetches + prepares the thin-edge.io standalone bundle
│       └── Makefile        #   -> tedge-standalone-<ver>.<platform>.pkg
├── modules/
│   ├── Rules.mk            # platform compatibility matrix
│   └── tedge/              # the Router App itself
│       ├── Makefile        # bundles the package + overlays merge/ + builds source/
│       ├── CHANGELOG.txt
│       ├── merge/etc/      # on-router /opt/tedge/etc/*
│       │   ├── name, version, summary, description   # module metadata
│       │   ├── defaults    # configurable settings (shown in the web UI)
│       │   ├── init        # service control: start|stop|restart|status
│       │   ├── install     # first-install setup
│       │   └── uninstall   # cleanup
│       └── source/         # the web interface (compiled CGI)
│           ├── module_cgi.c    # config form, status page, system-log view
│           ├── module_cfg.c/.h # read/write the settings file
│           ├── module.h        # module name / paths
│           └── Makefile        # -> /opt/tedge/{bin/cgi, www/*.cgi}
├── scripts/setup-build-env.sh
└── docs/PLATFORMS.md       # ICR platform ↔ architecture reference
```

On the router the module installs to `/opt/tedge/`.

## Web interface

The module adds a page under **Customization → Router Apps → thin-edge.io** with:

- **Configuration** — a form for the Cumulocity connection settings (URL,
  registration mode, device ID/OTP, and Basic-auth credentials). Saving writes
  `/opt/tedge/etc/settings` and runs `etc/init restart` to apply the change.
- **Status** — the live daemon status and the most recent Cumulocity mapper log.
- **System Log** — the router's system log, filtered to this module.

The page is a single compiled CGI (`source/module_cgi.c`) built against the
SDK's `libum`. The router's web server enforces login on it (via the standard
`www/.htpasswd` link) and `libum` adds the CSRF check.

## Building

Building requires an **Ubuntu 24.04+** host, the Advantech **Toolchains** and the
Advantech **ModulesSDK**, checked out *next to* this repository:

```
<workspace>/
├── ModulesSDK/                 # https://bitbucket.org/bbsmartworx/modulessdk
├── Toolchains/                 # https://bitbucket.org/bbsmartworx/toolchains
└── advantec-tedge-router-app/  # this repository
```

Set it up automatically:

```sh
./scripts/setup-build-env.sh
```

...or manually per the [ModulesSDK README](https://bitbucket.org/bbsmartworx/modulessdk).

Then build for the ICR-1642:

```sh
make PLATFORMS="v4i"
```

The Router App is produced at:

```
images/tedge/tedge.v4i.tgz
```

Build for other / all platforms:

```sh
make PLATFORMS="v2i v3 v4 v4i"      # everything
cd modules/tedge && make PLATFORM=v4i   # just this app, one platform
```

> The build fetches the matching thin-edge.io standalone release from GitHub
> (internet access required). The pinned version lives in
> `packages/tedge/Makefile` (`TEDGE_VERSION`) and `packages/tedge/version.txt`.

## Installing on the router

1. Open the router web interface → **Customization → Router Apps** (User Modules).
2. **Add** the `tedge.v4i.tgz` file and install it.
3. Open the **thin-edge.io** module's configuration page and set:
   - **Cumulocity URL** (`MOD_TEDGE_C8Y_URL`), e.g. `mytenant.cumulocity.com`
   - **Registration mode** (`MOD_TEDGE_CA`): `c8y-ca` (recommended), `basic`, or `self-signed`
   - credentials / device ID as required by the chosen mode
   - **Enabled** (`MOD_TEDGE_ENABLED`) = `1`
4. Restart the module (or reboot). thin-edge.io then starts on every boot.

You can also edit `/opt/tedge/etc/settings` over SSH and run
`/opt/tedge/etc/init restart`.

### Registration modes

| `MOD_TEDGE_CA` | How it authenticates |
|----------------|----------------------|
| `c8y-ca`       | Downloads a device certificate from the Cumulocity Certificate Authority using a one-time password. The registration URL (with the OTP) is printed to the log; the OTP defaults to `md5(device-id)` if not set. **Recommended.** |
| `basic`        | Uses a device username + password (`MOD_TEDGE_DEVICE_USER` / `MOD_TEDGE_DEVICE_PASSWORD`). |
| `self-signed`  | Creates a self-signed certificate that you upload to Cumulocity manually. |

## Operating

Over SSH (the app also symlinks `tedge` onto the system `PATH`):

```sh
. /opt/tedge/env

/opt/tedge/etc/init status      # daemon status
/opt/tedge/etc/init restart     # apply settings changes
tedge config list               # show effective configuration
tedge cert show                 # show device certificate
tail -f /var/log/tedge/*.log    # logs (mosquitto / mapper / agent)
```

## Upgrading thin-edge.io

Bump `TEDGE_VERSION` in `packages/tedge/Makefile`, update
`packages/tedge/version.txt` and `modules/tedge/CHANGELOG.txt`, then rebuild.
Config files are shipped as `*.default` and are **not** overwritten on reinstall,
so operator settings survive upgrades.

## References

- thin-edge.io standalone: <https://github.com/thin-edge/tedge-standalone>
- Advantech RouterApps examples: <https://bitbucket.org/bbsmartworx/routerapps>
- Advantech Router App SDK: <https://bitbucket.org/bbsmartworx/modulessdk>
- ICR-1642 product page: <https://icr.advantech.com/support/router-models/detail/icr-1642>
- Platform / architecture details: [docs/PLATFORMS.md](docs/PLATFORMS.md)
