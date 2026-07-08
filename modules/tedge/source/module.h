// Definitions for the thin-edge.io Router App web interface.
//
// The CGI (source/module_cgi.c) reads and writes the same settings file that
// etc/init sources (/opt/tedge/etc/settings), using the MOD_TEDGE_* keys shown
// on the module's configuration page. Keep these in sync with merge/etc/defaults
// and merge/etc/init.

#ifndef _MODULE_H_
#define _MODULE_H_

// module title (shown as the page heading)
#define MODULE_TITLE    "thin-edge.io"

// module name (matches the on-router install dir /opt/<name>)
#define MODULE_NAME     "tedge"

// prefix for all settings keys
#define MODULE_PREFIX   "MOD_TEDGE_"

// settings file written by set.cgi and sourced by etc/init
#define MODULE_SETTINGS "/opt/" MODULE_NAME "/etc/settings"

// service control script (etc/init restart applies changes)
#define MODULE_INIT     "/opt/" MODULE_NAME "/etc/init"

#endif
