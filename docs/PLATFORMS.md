# ICR platform / architecture reference

Advantech ICR routers are grouped into build "platforms". Each platform maps to
a CPU architecture, an Advantech cross-toolchain and a thin-edge.io standalone
release architecture.

| ICR platform | CPU / ABI            | Advantech toolchain prefix     | thin-edge.io arch | Router App suffix |
|--------------|----------------------|--------------------------------|-------------------|-------------------|
| `v2i`        | ARM armv5 (EABI)     | `armv5-linux-gnueabi-`         | `armel`           | `.v2i.tgz`        |
| `v3`         | ARM armv7 (EABI)     | `armv7-linux-gnueabi-`         | `armhf`           | `.v3.tgz`         |
| `v4`         | ARM64 aarch64        | `aarch64-linux-gnu-`           | `arm64`           | `.v4.tgz`         |
| `v4i`        | ARM64 aarch64        | `aarch64-linux-gnu-`           | `arm64`           | `.v4i.tgz`        |

## ICR-1642

The **ICR-1642** belongs to the **`v4i`** platform (aarch64 / ARM64). Build with:

```sh
make PLATFORMS="v4i"
```

The resulting Router App is `images/tedge/tedge.v4i.tgz`.

## ICR-4400 family (ICR-44xx)

The **ICR-4400** routers (e.g. ICR-4434, ICR-4461) belong to the **`v4`**
platform (aarch64 / ARM64). Build with:

```sh
make PLATFORMS="v4"
```

`v4` and `v4i` share the aarch64 toolchain and thin-edge.io `arm64` build, and
both are built by default, so a single `make` produces apps for the ICR-1642 and
the ICR-44xx. The relay extension uses the same ICR-OS `io` command on both; note
the ICR-1642 has one binary output (OUT0) while the ICR-44xx has two (OUT0/OUT1),
selectable via `MOD_RELAY_OUTPUT`.

## Notes

- `v2i` and `v3` use a soft-float (`gnueabi`) ABI in the Advantech toolchain. The
  mapped thin-edge.io `armel` (v2i) build matches; the `armhf` build used for
  `v3` is hard-float — verify it runs on your specific `v3` unit before shipping.
- The primary and fully-supported target of this project is **`v4i` (ICR-1642)**.
- Architecture confirmed via the ModulesSDK `Rules.mk` toolchain table and the
  Advantech "Platform v4i" product category, which lists the ICR-1642.
