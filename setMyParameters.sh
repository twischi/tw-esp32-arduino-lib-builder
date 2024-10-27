#!/bin/bash

# ----------------------------------
# Set Parameters for the build.sh
# ---------------------------------
# Call his upfront, if you call
#    ./build.sh 
# from a other scrpt,
# see: yourBuild_with_log.sh
# --------------------------------
echo "Set Parameters for ./build.sh   by this script >> 'setMyParameters.sh'"
oneUpDir=$(realpath $(pwd)/../)        # DIR above the current directory
GitHubSources=$oneUpDir/GitHub-Sources # GitHub-Sources-Folder
timeStampAR=$(date +"%Y%m%d_%Hh%Mm")   # Shorter Timestamp for the arduino-esp32 build
# --------------------------
# Target Chips               (TARGET)      to be build for. Separate them with comma.
# --------------------------
#sS+=" -t esp32h2,esp32s3"
sS+=" -t esp32h2"
# sS+=" -t esp32s3"
# --------------------------
# Save all downloads from GitHub in ONE folder, affect
# - arduino-esp32
# - esp-idf
# - esp32-arduino-libs
# --------------------------
sS+=" -G"
# --------------------------
# <arduino-esp32>
# --------------------------
# BRANCH                     (AR_BRANCH)   for the building.  
sS+=" -A release/v3.1.x"
#sS+=" -A idf-release/v5.1"
#sS+=" -A master"
# COMMIT                     (AR_COMMIT)   for the building.
#sS+=" -a 2ba3ed3"
# TAG                        (AR_TAG)      for the building.   
#sS+=" -g 3.0.6"
# --------------------------
# <esp-idf>  
# --------------------------
# BRANCH                     (IDF_BRANCH)  for the building.   
# sS+=" -I release/v5.1"
sS+=" -I release/v5.3"
# COMMIT                     (IDF_COMMIT)  for the building.   
#sS+=" -i '<commit-hash>'"
# TAG                        (IDF_TAG)     for the building.   
#sS+=" -T v5.1.4"
# DEBUG flag                 (BUILD_DEBUG) for compile with idf.py 
#                            Allowed: default,none,error,warning,info,debug or verbose (BUILD_DEBUG)
sS+=" -D info"
# SKIP                       (SKIP_ENV)    install./update IDF & components. (IDF_InstallSilent)  
#sS+=" -s" 
# ------------------------------------
# Build out Folder & post-Build flags
# ------------------------------------
#        ~~ NO building  ~   (SKIP_BUILD)   SKIP building for TESTING DEBUGING ONLY
#sS+=" -X"
# OUT    ~~ during build ~~  (AR_OWN_OUT)  to store the build output.
sS+=" -o $oneUpDir/Out-from_build"
# Arduino  ~~ post-build ~~  (ESP32_ARDUINO) for use with Arduino.
#                            Copy the build to Arduino folder
#                            ' e.g to (ESP32_ARDUINO) '$HOME/Arduino/hardware/espressif/esp32'"
#sS+=" -c $oneUpDir/Arduino/copy/arduino-esp32-$timeStampAR"
# Arduiono  ~~ post-build ~~ (ARCHIVE_OUT) Set flag to create Arduiono archives
#sS+=" -e"
#-d                          Deploy the build to github arduino-esp32"
# PIO       ~~ post-build ~~ (POI_OUT_F) Set flag to create PIO archives
sS+=" -l"
# ----------------
# Silent Settings
# ----------------
# Install/loads              (IDF_InstallSilent) for Load & Install - Components. 
sS+=" -S"
# BUILD                      (IDF_BuildTargetSilent) for buildings with idf.py
sS+=" -V" 
# Outputs after build        (IDF_BuildInfosSilent) for create output & arrange after build 
sS+=" -W"
# ---------------------------
# Set the Command-Arguments
# --------------------------
# The command `set -- $sS` in a shell script is used to set the positional parameters for the current shell instance.
echo "Build-Command-Parameters set to:"
echo "   $sS"
set -- $sS

# <arduino-esp32> Find suitable:
# --  BRANCH      https://github.com/espressif/arduino-esp32/branches
#                 master
#                 release/v3.1.x
# --  COMMIT      https://github.com/espressif/arduino-esp32/commits/master/
# --  TAG         https://github.com/espressif/arduino-esp32/tags
#                 3.0.7 (10/2024) --> IDF 5.1.4
#                 3.0.1           --> IDF 5.1.4 

#  <esp-idf>      Find suitable:
# --  BRANCH      https://github.com/espressif/esp-idf/branches
#                 release/v5.1
#                 release/v5.3
# --  COMMIT      https://github.com/espressif/esp-idf/commits/master/
# --  TAG         https://github.com/espressif/esp-idf/tags
#                 v5.1.4 (10/2024)
#                

#  <esp32-AR-libs>  https://github.com/espressif/esp32-arduino-libs                   
# --  Releases    https://github.com/espressif/esp32-arduino-libs/releases
#                 idf-release/v5.1 (10/2024)