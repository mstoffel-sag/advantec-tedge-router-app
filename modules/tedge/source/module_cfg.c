// Configuration of the thin-edge.io Router App (load/save the settings file).
//
// The settings file is a flat, shell-sourceable KEY=value file so that etc/init
// can read it with ". $MOD_SETTINGS". um_cfg_get_str never returns NULL (it
// returns "" for a missing key) and um_cfg_put_str quotes values containing
// spaces, so empty/optional fields round-trip safely.

#define _GNU_SOURCE

#include <stdio.h>

#include "um_cfg.h"

#include "module.h"
#include "module_cfg.h"

// **************************************************************************
// load configuration from file
void module_cfg_load(module_cfg_t *cfg_ptr)
{
  FILE                  *file_ptr;

  file_ptr                   = um_cfg_open(MODULE_SETTINGS, "r");
  cfg_ptr->enabled           = um_cfg_get_int(file_ptr, MODULE_PREFIX "ENABLED"        );
  cfg_ptr->c8y_url           = um_cfg_get_str(file_ptr, MODULE_PREFIX "C8Y_URL"        );
  cfg_ptr->ca                = um_cfg_get_str(file_ptr, MODULE_PREFIX "CA"             );
  cfg_ptr->device_id         = um_cfg_get_str(file_ptr, MODULE_PREFIX "DEVICE_ID"      );
  cfg_ptr->otp               = um_cfg_get_str(file_ptr, MODULE_PREFIX "OTP"            );
  cfg_ptr->device_user       = um_cfg_get_str(file_ptr, MODULE_PREFIX "DEVICE_USER"    );
  cfg_ptr->device_password   = um_cfg_get_str(file_ptr, MODULE_PREFIX "DEVICE_PASSWORD");
  um_cfg_close(file_ptr);
}

// **************************************************************************
// save configuration to file
int module_cfg_save(module_cfg_t *cfg_ptr)
{
  FILE                  *file_ptr;

  if ((file_ptr = um_cfg_open(MODULE_SETTINGS, "w"))) {
    um_cfg_put_bool(file_ptr, MODULE_PREFIX "ENABLED"        , cfg_ptr->enabled        );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "C8Y_URL"        , cfg_ptr->c8y_url        );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "CA"             , cfg_ptr->ca             );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "DEVICE_ID"      , cfg_ptr->device_id      );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "OTP"            , cfg_ptr->otp            );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "DEVICE_USER"    , cfg_ptr->device_user    );
    um_cfg_put_str (file_ptr, MODULE_PREFIX "DEVICE_PASSWORD", cfg_ptr->device_password);
    um_cfg_save(file_ptr, MODULE_SETTINGS);
    return 1;
  }

  return 0;
}
