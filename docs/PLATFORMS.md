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

## Notes

- `v2i` and `v3` use a soft-float (`gnueabi`) ABI in the Advantech toolchain. The
  mapped thin-edge.io `armel` (v2i) build matches; the `armhf` build used for
  `v3` is hard-float — verify it runs on your specific `v3` unit before shipping.
- The primary and fully-supported target of this project is **`v4i` (ICR-1642)**.
- Architecture confirmed via the ModulesSDK `Rules.mk` toolchain table and the
  Advantech "Platform v4i" product category, which lists the ICR-1642.
