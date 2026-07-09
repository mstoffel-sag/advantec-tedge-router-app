# Router App compatibility matrix.
#
# Lists, for each module, the platforms it can be built for. The recursive
# Makefiles use this to decide what to build for a requested PLATFORM.
#
#   v2i  = armv5   routers
#   v3   = armv7   routers
#   v4   = aarch64 routers
#   v4i  = aarch64 routers  <-- ICR-1642
#
tedge = v2i v3 v4 v4i
relay = v2i v3 v4 v4i
