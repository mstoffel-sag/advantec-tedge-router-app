# 3rd-party package compatibility matrix (see modules/Rules.mk for details).
#
# The `tedge` package fetches the matching thin-edge.io *standalone* release
# binaries for the target architecture and repackages them for the Router App.
tedge = v2i v3 v4 v4i

# The `tedge-container` package fetches the matching tedge-container-plugin
# binary and lays it into the tedge platform tree (folded into the tedge module,
# not a standalone Router App).
tedge-container = v2i v3 v4 v4i
