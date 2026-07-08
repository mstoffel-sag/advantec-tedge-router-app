# Builds the thin-edge.io Router App web interface (a single CGI binary).
#
# build-module (in the SDK) compiles this source/ tree automatically and then
# runs the install target below with DESTDIR=tmp/opt/tedge, so the CGI and its
# www/ symlinks are packaged alongside the thin-edge.io runtime bundle.
#
# ../../../Rules.mk is this repository's Rules.mk, which pulls in the SDK
# (build-program macro, cross-toolchain, -I<SDK>/library, -l:libum.a).

include ../../../Rules.mk

MODULE_CGI_EXE = module_cgi
MODULE_CGI_SRC = module_cgi.c module_cfg.c

$(eval $(call build-program, $(MODULE_CGI_EXE), $(MODULE_CGI_SRC)))

# One binary, symlinked per page; dispatch is on argv[0] (see module_cgi.c).
# The .htpasswd symlink makes the router's httpd require a valid login.
install:
	@install -d $(DESTDIR)/bin
	@install -d $(DESTDIR)/www
	@install -m 755 $(OBJDIR)/$(MODULE_CGI_EXE) $(DESTDIR)/bin/cgi
	@ln -s ../bin/cgi   $(DESTDIR)/www/index.cgi
	@ln -s ../bin/cgi   $(DESTDIR)/www/set.cgi
	@ln -s ../bin/cgi   $(DESTDIR)/www/status.cgi
	@ln -s ../bin/cgi   $(DESTDIR)/www/slog.cgi
	@ln -s /etc/htpasswd $(DESTDIR)/www/.htpasswd
