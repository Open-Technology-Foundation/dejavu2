#!/bin/bash
#!shellcheck disable=SC1090,SC1091

# import defaults from config files ---------------
# This file must be SOURCED from the script.
declare _config_file
for _config_file in "${CONF_FILES[@]}"; do
  [[ -f "$_config_file" ]] || continue
  [[ "${_config_file:0:2}" == './' ]] \
      && _config_file=$(readlink -f -- "$_config_file")
  source "$_config_file"
done
unset _config_file

#fin
