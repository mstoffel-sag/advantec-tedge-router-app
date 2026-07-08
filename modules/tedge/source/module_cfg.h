// Configuration of the thin-edge.io Router App (load/save the settings file).

#ifndef _MODULE_CFG_H_
#define _MODULE_CFG_H_

// thin-edge.io Router App configuration (mirrors merge/etc/defaults).
typedef struct {
  unsigned int   enabled;          // MOD_TEDGE_ENABLED         (0/1)
  char           *c8y_url;         // MOD_TEDGE_C8Y_URL
  char           *ca;              // MOD_TEDGE_CA              (c8y-ca|basic|self-signed)
  char           *device_id;       // MOD_TEDGE_DEVICE_ID
  char           *otp;             // MOD_TEDGE_OTP
  char           *device_user;     // MOD_TEDGE_DEVICE_USER
  char           *device_password; // MOD_TEDGE_DEVICE_PASSWORD
} module_cfg_t;

// load configuration from the settings file (missing keys become "" / 0)
extern void module_cfg_load(module_cfg_t *cfg_ptr);

// save configuration to the settings file; returns non-zero on success
extern int module_cfg_save(module_cfg_t *cfg_ptr);

#endif
