#!/bin/bash

#SKIP_BUILD=1 # Un-comment for: TESTING DEBUGING ONLY 
#------------------------------------------
# Ensure that a alternative bash potentially 
# installed on an the system will be used
#------------------------------------------
# Determine the path to the bash executable
# BASH_PATH=$(which bash)
# # Ensure the bash executable is found
# if [ -z "$BASH_PATH" ]; then
#   echo "bash not found in PATH"
#   exit 1
# fi
# # If the script is not running with the correct bash, re-execute it with the found bash
# if [ "$BASH" != "$BASH_PATH" ]; then
#   exec "$BASH_PATH" "$0" "$@"
# fi
#--------------------------
# Check for Comands needed 
#--------------------------
if ! [ -x "$(command -v python3)" ]; then
    echo "ERROR: python is not installed! Please install python first."
    exit 1
fi
if ! [ -x "$(command -v git)" ]; then
    echo "ERROR: git is not installed! Please install git first."
    exit 1
fi
# Set the current path of the script
export SH_ROOT=$(pwd)
#-----------------------------------------------------------------------------
# Load the functions extractFileName() > For pretty output of compiler configs
#source $SH_ROOT/tools/prettiyfiHelpers.sh
source $SH_ROOT/ownTools/myToolsEnhancements.sh
#---------------------------
# Show intro of the build.sh 
echo -e "\n~~~~~~~~~~~~~~~~~~~~   $eTG Starting of the build.sh $eNO to get the Arduino-Libs    ~~~~~~~~~~~~~~~~~~~~"
echo -e   "~~ Purpose: Get the Arduino-Libs for manifold  ESP32-Variants > Targets"
echo -e   "~~          It will generate 'Static Libraries'-Files (*.a) and 'Bootloader'-Files (*.elf)"
echo -e   "~~          along with may others neeed files."
echo -e   "~~ Steps of Sricpt:"
echo -e   "~~          1) Check & Process Parameter with calling build.sh"
echo -e   "~~          2) Load or Update Components/Tools to do compile"
echo -e   "~~          3) Compile the Targets with the given Configurations"
echo -e   "~~          4) Create outputs and move this files"
echo -e   "~~ build.sh started at Folder (SH_ROOT):"
echo -e   "~~          >>$ePF $SH_ROOT $eNO"
echo -e   "~~          >> Bash version:$eGI $BASH_VERSION $eNO"
echo -e   "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#-----------------------------------------------------------
# Set the default values to be overwritten by the arguments
#-----------------------------------------------------------
TARGET="all"
BUILD_TYPE="all"
BUILD_DEBUG="default"
SKIP_ENV=0
COPY_OUT=0
ARCHIVE_OUT=0
IDF_InstallSilent=0     # 0 = not silent, 1 = silent
IS_Shown=0              # Flag to show message only once
IDF_BuildTargetSilent=0 # 0 = not silent, 1 = silent
BTS_Shown=0
IDF_BuildInfosSilent=0  # 0 = not silent, 1 = silent
BTI_Shown=0
if [ -z $DEPLOY_OUT ]; then
    DEPLOY_OUT=0
fi
#-------------------------------------
#  Function to print the help message
#-------------------------------------
function print_help() {
    echo "Usage: build.sh [-s] [-A <arduino_branch>] [-I <idf_branch>] [-D <debug_level>] [-i <idf_commit>] [-c <path>] [-t <target>] [-b <build|menuconfig|reconfigure|idf-libs|copy-bootloader|mem-variant>] [config ...]"
    echo 
    echo "       -G     <Git-Hub>       Save all downloads from GitHub in ONE folder ../GitHubSources"
    echo
    echo "       -A     <arduino-esp32> Set BRANCH to be used for compilation (AR_BRANCH)"
    echo "       -a     <arduino-esp32> Set COMMIT to be used for compilation (AR_COMMIT)"
    echo "       -g     <arduino-esp32> Set TAG    to be used for compilation (AR_TAG)"
    echo 
    echo "       -s     <esp-idf>       SKIP installing/updating of ESP-IDF and all components (SKIP_ENV)=1"
    echo "       -I     <esp-idf>       Set BRANCH to be used for compilation (IDF_BRANCH)"
    echo "       -i     <esp-idf>       Set COMMIT to be used for compilation (IDF_COMMIT)"
    echo "       -T     <esp-idf>       Set TAG    to be used for compilation (IDF_TAG)"
    echo "      ++++    ---------       only '-I' BRANCH <OR> COMMIT '-i' can be used"
    echo "       -D     <esp-idf>       Set DEBUG level compilation. Allowed: default,none,error,warning,info,debug or verbose (BUILD_DEBUG)"
    echo 
    echo "       -t     building        Set target(chip) eg. 'esp32s3' or multiple by separating with comma ex. 'esp32,esp32s3,esp32c3'"
    echo "       -o     building        Set a OWN Out-Folder, that take building output. Works with a simlink, refers to 'normal' out-folder"
    echo "       -X     building        SKIP building for TESTING DEBUGING of creating outputs from buid. Build must be there (SKIP_BUILD)=1"
    echo "       -b     building        Set the build type. ex. 'build' to build the project and prepare for uploading to a board (BUILD_TYPE)"
    echo "       ...                    Specify additional configs to be applied. ex. 'qio 80m' to compile for QIO Flash@80MHz. Requires -b"
    echo 
    echo "       -c     Arduino         Copy the build to Arduino folder, e.g to (ESP32_ARDUINO) '$HOME/Arduino/hardware/espressif/esp32'"
    echo "       -e     Arduino         Create folder & archive (ARCHIVE_OUT)=1"
    echo "       -d     Arduino         Deploy the build to Github arduino-esp32 (DEPLOY_OUT)=1"
    echo 
    echo "       -e     PlatformIO      PIO Create folder structure & archive (PIO_OUT_F)=1"
    echo 
    echo "       -S     Silent mode for Installation - Components. Don't use this unless you are sure the installs goes without errors (IDF_InstallSilent)"
    echo "       -V     Silent mode for Building - Targets with idf.py. Don't use this unless you are sure the buildings goes without errors (IDF_BuildTargetSilent)"
    echo "       -W     Silent mode for Creating - Infos. Don't use this unless you are sure the creations goes without errors"
    exit 1
}
#-------------------------------------
# Check if any arguments were passed
#-------------------------------------
if [ $# -eq 0 ]; then
    # Check if the script is running with bashdb (debug mode)
    if [[ -n "$_Dbg_file" ]]; then
        echo "Running in debug mode"
        source $SH_ROOT/setMyParameters.sh
    else
        # No arguments were passed then set MY defaults
        # Dialog to decide it to use the default values or not
        echo "No Parameters were passed:"
        while true; do
            read -p "Do you want to use your default Parameters? (y/n): " choice
            case "$choice" in
                y|yes ) 
                    source $SH_ROOT/setMyParameters.sh
                    break
                    ;;
                n|No ) 
                    echo "Proceed without Parameters..."
                    break
                    ;;
                * ) 
                    echo "Please answer y or n."
                    ;;
            esac
        done
    fi
fi
#-------------------------------
# Process Arguments were passed
#-------------------------------
echo -e "\n--------------------------    1) Given ARGUMENTS Process & Check    -----------------------------"
while getopts ":A:a:b:c:D:g:i:I:T:t:delosGSVWX" opt; do
    case ${opt} in
        s )
            SKIP_ENV=1
            echo -e '-s  <esp-idf>\t Skip installing/updating of ESP-IDF and all components'
            ;;
        d )
            DEPLOY_OUT=1
            echo -e '-d \t..\t Deploy the build to github arduino-esp32 (DEPLOY_OUT)=1'
            ;;
        e )
            ARCHIVE_OUT=1
            echo -e '-e \t..\t Arduiono create folder & archive (ARCHIVE_OUT)=1'
            ;;
        l )
            PIO_OUT_F=1
            echo -e '-l \tPIO\t Create structure & archive (PIO_OUT_F)=1'
            echo -e "\t\t >> '$(shortFP "PIO")'"
            ;;
        c )
            export ESP32_ARDUINO="$OPTARG"
            echo -e "-c \t..\t Copy the build to arduino-esp32 Folder:"
            echo -e "\t\t >> '$(shortFP $ESP32_ARDUINO)'"
            COPY_OUT=1
            ;;
        o )
            echo -e "-o \t..\t Use a own OUT-Folder for build-outputs):"
            process_OWN_OutFolder_AR
            echo -e "\t\t >> $ePF'../$(shortFP $AR_Build_Output)'"
            ;;
        A )
            export AR_BRANCH="$OPTARG"
            echo -e "-A  <ar.-esp32>\t Set BRANCH to be used for compilation (AR_BRANCH)=$eTG'$AR_BRANCH'$eNO"
            pioAR_verStr="AR_$AR_BRANCH"
            ;;
        a )
            export AR_COMMIT="$OPTARG"
            echo -e "-a  <ar.-esp32>\t Set COMMIT to be used for compilation (AR_COMMIT):$eTG '$AR_COMMIT' $eNO"
            pioAR_verStr="AR_$AR_COMMIT"
            ;;
        g )
            export AR_TAG="$OPTARG"
            echo -e "-g  <ar.-esp32>\t Set TAG to be used for compilation (AR_COMMIT):$eTG '$AR_TAG' $eNO"
            pioAR_verStr="AR_tag_$AR_TAG"
            ;;
       G )
            echo -e "-G  <Git-Hub>\t Save GitHub Download to ONE folder."
            process_GH_Folder "$Temporarily"            
            echo -e "\t\t >> $ePF'../$(shortFP $GitHubSources)'"
            ;;
        I )
            export IDF_BRANCH="$OPTARG"
            echo -e "-I  <esp-idf>\t Set BRANCH to be used for compilation (IDF_BRANCH):$eTG '$IDF_BRANCH' $eNO"
            pioIDF_verStr="IDF_$IDF_BRANCH"
            ;;
        i )
            export IDF_COMMIT="$OPTARG"
            echo -e "-i  <esp-idf>\t Set COMMIT to be used for compilation (IDF_COMMIT):$eTG '$IDF_COMMIT' $eNO"
            pioIDF_verStr="IDF_$IDF_COMMIT"
            ;;
        T )
            export IDF_TAG="$OPTARG"
            echo -e "-G  <esp-idf>\t Set TAG to be used for compilation (IDF_TAG):$eTG '$IDF_TAG' $eNO"
            pioIDF_verStr="IDF_tag_$IDF_TAG"
            ;;
        D )
            BUILD_DEBUG="$OPTARG"
            echo -e "-D  <esp-idf>\t Set DEBUG level compilation (BUILD_DEBUG):$eTG '$BUILD_DEBUG' $eNO"
            ;;
        t )
            IFS=',' read -ra TARGET <<< "$OPTARG"
            echo -e "-t \tbuild\t Set the build target(chip):$eTG '${TARGET[@]}' $eNO"
            ;;
        S )
            IDF_InstallSilent=1
            echo -e '-S  <esp-idf>\t Silent mode for installing ESP-IDF and components'
            ;;
        V )
            IDF_BuildTargetSilent=1
            echo -e '-V \tbuild\t Silent mode for building Targets with idf.py'
            ;;
        W )
            IDF_BuildInfosSilent=1
            echo -e '-W \tOutput\t Silent mode for building of Infos.'
            ;;
        X )
            SKIP_BUILD=1
            echo -e '-X \tbuild\t Skip building for TESTING DEBUGING.'
            ;;
        b )
            b=$OPTARG
            if [ "$b" != "build" ] && 
            [ "$b" != "menuconfig" ] && 
            [ "$b" != "reconfigure" ] && 
            [ "$b" != "idf-libs" ] && 
            [ "$b" != "copy-bootloader" ] && 
            [ "$b" != "mem-variant" ]; then
                print_help
            fi
            BUILD_TYPE="$b"
            echo -e '-b \t Set the build type BUILD_TYPE='$BUILD_TYPE
            ;;
        \? )
            echo -e $eTG "Invalid option: -$OPTARG $eNO" 1>&2
            print_help
            ;;
        : )
            echo -e $eTG "Invalid option: -$OPTARG requires an argument$eNO" 1>&2
            print_help
            ;;
    esac
done
echo -e   "------------------------------     DONE:  processing ARGUMENTS     ------------------------------\n"
# --------------------
# Misc
shift $((OPTIND -1))
CONFIGS=$@

# **********************************************
# ******     LOAD needed Components      *******
# **********************************************
if [ $SKIP_ENV -eq 0 ]; then
    echo -e   '--------------------------------  2) Load the Compontents   -------------------------------------'
    echo -e   "-- Load arduino_tinyusb component with > $eUS                            /tools/update-components.sh$eNO"
    # update components from git
    source $SH_ROOT/tools/update-components.sh
    osascript -e 'beep 3' # Beep 3 times
    if [ $? -ne 0 ]; then exit 1; fi    
    echo -e "\n-- Load arduino-esp32 component with > $eUS                                /tools/install-arduino.sh$eNO"
    # install arduino component
    source $SH_ROOT/tools/install-arduino.sh
    osascript -e 'beep 3' # Beep 3 times
    if [ $? -ne 0 ]; then exit 1; fi
    # install esp-idf
    echo -e "\n-- Load esp-idf component with > $eUS                                      /tools/install-esp-idf.sh$eNO"
    source $SH_ROOT/tools/install-esp-idf.sh
    osascript -e 'beep 3' # Beep 3 times
    if [ $? -ne 0 ]; then exit 1; fi
    echo -e   '----------------------------------   Components load DONE    ------------------------------------\n'
else
    echo -e "\n--- NO load of Components: Just get the Pathes with > $eUS                         /tools/config.sh$eNO"
    # $IDF_PATH/install.sh
    # source $IDF_PATH/export.sh
    source $SH_ROOT/tools/config.sh
    osascript -e 'beep 3' # Beep 3 times
    echo -e   '--- NO load of Components: DONE--------------------\n'
fi
# Hash of managed components
if [ -f "$AR_MANAGED_COMPS/espressif__esp-sr/.component_hash" ]; then
    rm -rf $AR_MANAGED_COMPS/espressif__esp-sr/.component_hash
fi

#------------------------------------------------------------------------
# TESTING DEBUGING ONLY - TESTING DEBUGING ONLY - TESTING DEBUGING ONLY
if [ -z $SKIP_BUILD ]; then  # SKIP BUILD for testing purpose ONLY
# **********************************************
# *****   Build II ALL   ******
# **********************************************
if [ "$BUILD_TYPE" != "all" ]; then
    echo -e '------------------- 3)BUILD Target-List (NOT ALL)  -------------------' 
    if [ "$TARGET" = "all" ]; then
        echo "ERROR: You need to specify target for non-default builds"
        print_help
    fi
    # Target Features Configs
    echo -e '***** Loop over given the Targets *****'
    for target_json in `jq -c '.targets[]' configs/builds.json`; do
        # Get the target name from the json
        target=$(echo "$target_json" | jq -c '.target' | tr -d '"')
        # Check if $target is in the $TARGET array
        target_in_array=false
        for item in "${TARGET[@]}"; do
            if [ "$item" = "$target" ]; then
                target_in_array=true
                break
            fi
        done
        if [ "$target_in_array" = false ]; then
            # Skip building for targets that are not in the $TARGET array
            continue
        fi
        configs="configs/defconfig.common;configs/defconfig.$target;configs/defconfig.debug_$BUILD_DEBUG"
        for defconf in `echo "$target_json" | jq -c '.features[]' | tr -d '"'`; do
            configs="$configs;configs/defconfig.$defconf"
        done
        echo "-- Building for Target:$target"
        # Configs From Arguments
        for conf in $CONFIGS; do
        echo "   ...Get his configs"
            configs="$configs;configs/defconfig.$conf"
        done
        echo -e "   ...Build with >$eUS idf.py$eNO -DIDF_TARGET=\"$target\" -DSDKCONFIG_DEFAULTS=\"$configs\" $BUILD_TYPE"
        rm -rf build sdkconfig
        idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$configs" $BUILD_TYPE
        if [ $? -ne 0 ]; then exit 1; fi
        echo    "   Building for Target:$target DONE"
    done
    echo -e '-----------------     BUILD Target-List   DONE    -----------------\n'
    exit 0
fi
# **********************************************
# ******     BUILD the Components        *******
# **********************************************
echo -e   '--------------------------------- 3) BUILD for Named Targets ------------------------------------'
# Clean the build- and out- folders
rm -rf build sdkconfig # Clean the build folders
# Special treatment for the out folder as is could be a symlink
rm -rf out/* # Clean the out folders

Out_RealPath=$(realpath out) 
echo -e "-- Create the Out-folder\n   to: $(shortFP "$Out_RealPath")"

# Recreate the targetsBuildList.txt file 
rm -rf out/targetsBuildList.txt && touch out/targetsBuildList.txt
# ----------------------------------------------
# Count the number of POSSIBLE targets to build
# ----------------------------------------------
# Therefore create a array from from JSON File: 'configs/builds.json'
# Extract the Possible Target-Names 
possibleTargetsArray=($(jq -r '.targets[].target' configs/builds.json)) # -r option to get raw output, leads to an array
activeTargetsArray=($(jq -r '.targets[] | select(.skip != 1) | .target' configs/builds.json))
# And count the number of elements in the array   
possibleTargetsCount=${#possibleTargetsArray[@]} && activeTargetsCount=${#activeTargetsArray[@]}
echo -e "...Number of ACTIVE Targets=$eTG $activeTargetsCount$eNO from$eTG $possibleTargetsCount$eNO possible Targets, see: 'configs/builds.json'" 
echo -e "   List:$eUS ${possibleTargetsArray[@]}$eNO"
# ----------------------------------------------
# MAIN Loop over for BUILDING the Targets
# ----------------------------------------------
targetCount=0 # Counter for the loop 
echo -e "###############################      Loop over given Target      ################################"
for target_json in `jq -c '.targets[]' configs/builds.json`; do
    target=$(echo "$target_json" | jq -c '.target' | tr -d '"')
    target_skip=$(echo "$target_json" | jq -c '.skip // 0')
    # Check if $target is in the $TARGET array if not "all"
    if [ "$TARGET" != "all" ]; then
        target_in_array=false
        for item in "${TARGET[@]}"; do
            if [ "$item" = "$target" ]; then
                target_in_array=true
                break
            fi
        done
        # If $target is not in the $TARGET array, skip processing
        if [ "$target_in_array" = false ]; then
            echo -e "-- Skipping Target: $eSR$target$eNO"
            continue
        fi
    fi
    # Skip chips that should not be a part of the final libs
    # WARNING!!! this logic needs to be updated when cron builds are split into jobs
    if [ "$TARGET" = "all" ] && [ $target_skip -eq 1 ]; then
        echo -e "-- Skipping Target: $eSR$target$eNO"
        continue
    fi
    targetCount=$((targetCount+1)) # Increment the counter
    echo -e "****************************   Building $targetCount of $activeTargetsCount for Target:$eTG $target $eNO   ***************************"
    echo -e "-- Target Out-folder"
    echo -e "   to: $(shortFP "$Out_RealPath"/tools/esp32-arduino-libs/)$eTG$target $eNO"
    #-------------------------
    # Build Main Configs List
    #-------------------------
    echo "-- 1) Getting his Configs-List"
    main_configs="configs/defconfig.common;configs/defconfig.$target;configs/defconfig.debug_$BUILD_DEBUG"
    for defconf in `echo "$target_json" | jq -c '.features[]' | tr -d '"'`; do
        main_configs="$main_configs;configs/defconfig.$defconf"
    done
    #---------------------
    # Build IDF Libs List
    #---------------------
    echo "-- 2) Getting his Lib-List"
    idf_libs_configs="$main_configs"
    for defconf in `echo "$target_json" | jq -c '.idf_libs[]' | tr -d '"'`; do
        idf_libs_configs="$idf_libs_configs;configs/defconfig.$defconf"
    done
    if [ -f "$AR_MANAGED_COMPS/espressif__esp-sr/.component_hash" ]; then
        rm -rf $AR_MANAGED_COMPS/espressif__esp-sr/.component_hash
    fi
    #-------------------------------------------------------
    # Build the Arduiono Libs for the current target/CHIP 
    #------------------------------------------------------
    echo "-- 3) Build Arduiono-Libs with IDF for the target"
    rm -rf build sdkconfig
    echo -e "   Build with >$eUS idf.py$eNO -Target:$eTG $target $eNO"
    echo -e "     -Config:$eUS "$(extractFileName $idf_libs_configs)"$eNO"
    echo -e "     -Mode:   idf-libs to $ePF.../$eTG$target$ePF/lib$eNO (*.a)"
    if [ $IDF_BuildTargetSilent -eq 1 ]; then
        [ $BTS_Shown -eq 0 ] && echo -e "  $eTG Silent Build$eNO - don't use this as long as your not sure build goes without errors!" && BTS_Shown=1
        idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$idf_libs_configs" idf-libs > /dev/null 2>&1
    else 
        idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$idf_libs_configs" idf-libs
    fi
    osascript -e 'beep 3' # Beep 3 times
    if [ $? -ne 0 ]; then exit 1; fi
    #----------------
    # Build SR Models
    #-----------------
    if [ "$target" == "esp32s3" ]; then
        echo " -- 3b) Build SR (esp32s3) Models for the target"
        echo -e "   Build with >$eUS idf.py$eNO -Target:$eTG $target $eNO"
        echo -e "     -Config:$eUS "$(extractFileName $idf_libs_configs)"$eNO"
        echo -e "     -Mode:   srmodels_bin"
        if [ $IDF_BuildTargetSilent -eq 1 ]; then
            [ $BTS_Shown -eq 0 ] && echo -e "  $eTG Silent Build$eNO - don't use this as long as your not sure build goes without errors!" && BTS_Shown=1
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$idf_libs_configs" srmodels_bin > /dev/null 2>&1
        else
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$idf_libs_configs" srmodels_bin
        fi
        osascript -e 'beep 3' # Beep 3 times
        if [ $? -ne 0 ]; then exit 1; fi
        AR_SDK="$AR_TOOLS/esp32-arduino-libs/$target"
        # sr model.bin
        if [ -f "build/srmodels/srmodels.bin" ]; then
#            echo "$AR_SDK/esp_sr"
            mkdir -p "$AR_SDK/esp_sr"
            cp -f "build/srmodels/srmodels.bin" "$AR_SDK/esp_sr/"
            cp -f "partitions.csv" "$AR_SDK/esp_sr/"
        fi
    fi
    #-------------------
    # Build Bootloaders
    #-------------------
    bootloadersArray=$(echo "$target_json" | jq -c '.bootloaders[]') # Get a array of bootloaders from $target_json
    countBL=0 && numBL=0 && for mem_conf in $bootloadersArray; do numBL=$((numBL+1)); done;
    for boot_conf in $bootloadersArray; do
        bootloader_configs="$main_configs"
        for defconf in `echo "$boot_conf" | jq -c '.[]' | tr -d '"'`; do
            bootloader_configs="$bootloader_configs;configs/defconfig.$defconf";
        done
        countBL=$((countBL+1))
        if [ -f "$AR_MANAGED_COMPS/espressif__esp-sr/.component_hash" ]; then
            rm -rf $AR_MANAGED_COMPS/espressif__esp-sr/.component_hash
        fi
        [ $numBL -eq 1 ] && addOn="" || addOn=".$countBL"
        echo "-- 4$addOn) Build BootLoader ( $countBL of $numBL )"
        rm -rf build sdkconfig
        echo -e "   Build with >$eUS idf.py$eNO -Target:$eTG $target $eNO"
        echo -e "     -Config:$eUS "$(extractFileName $bootloader_configs)"$eNO"
        echo -e "     -Mode:   copy-bootloader to $ePF.../$eTG$target/$ePF/bin$eNO (*.elf)"     
        if [ $IDF_BuildTargetSilent -eq 1 ]; then
            [ $BTS_Shown -eq 0 ] && echo -e "  $eTG Silent Build$eNO - don't use this as long as your not sure build goes without errors!" && BTS_Shown=1
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$bootloader_configs" copy-bootloader > /dev/null 2>&1
        else
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$bootloader_configs" copy-bootloader
        fi
        if [ $? -ne 0 ]; then exit 1; fi
        osascript -e 'beep 3' # Beep 3 times
    done
    #-----------------------
    # Build Memory Variants
    #-----------------------
    memVariantsArray=$(echo "$target_json" | jq -c '.mem_variants[]') # Get a array of memory variants from $target_json
    countMV=0 && numMV=0 && for mem_conf in $memVariantsArray; do numMV=$((numMV+1)); done;
    for mem_conf in $memVariantsArray; do
        mem_configs="$main_configs"
        for defconf in `echo "$mem_conf" | jq -c '.[]' | tr -d '"'`; do
            mem_configs="$mem_configs;configs/defconfig.$defconf";
        done
        countMV=$((countMV+1))
        if [ -f "$AR_MANAGED_COMPS/espressif__esp-sr/.component_hash" ]; then
            rm -rf $AR_MANAGED_COMPS/espressif__esp-sr/.component_hash
        fi
        rm -rf build sdkconfig
        [ "$numMV" -eq 1 ] && addOn="" || addOn=".$countMV"
        echo "-- 5$addOn) Build Memory Variants ( $countMV of $numMV )"
        echo -e "   Build with >$eUS idf.py$eNO -Target:$eTG $target $eNO"
        echo -e "     -Config:$eUS "$(extractFileName $mem_configs)"$eNO"
        echo -e "     -Mode:   mem-variant to $ePF.../$eTG$target$ePF/dio_qspi$eNO and/or$ePF qio_qspi$eNO (*.a)"
        if [ $IDF_BuildTargetSilent -eq 1 ]; then
            [ $BTS_Shown -eq 0 ] && echo -e "  $eTG Silent Build$eNO - don't use this as long as your not sure build goes without errors!" && BTS_Shown=1
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$mem_configs" mem-variant > /dev/null 2>&1
        else
            idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$mem_configs" mem-variant
        fi
        if [ $? -ne 0 ]; then exit 1; fi
        osascript -e 'beep 3' # Beep 3 times
    done
    #----------------------------------------------
    # Export the Name of the build target to file 
    #    targetsBuildList.txt
    #---------------------------------------------
    if [ "$targetCount" -gt 1 ]; then
        echo -n ", " >> out/targetsBuildList.txt
    fi
    echo -n "$target" >> out/targetsBuildList.txt
    echo -e "***************************   FINISHED Building for Target:$eTG $target $eNO   **************************"
done
# Clean the build-folder and sdkconfig
rm -rf build sdkconfig
echo -e '-----------------------------    DONE: BUILD for Named Targets     ------------------------------\n'
fi # TESTING DEBUGING ONLY - TESTING DEBUGING ONLY - TESTING DEBUGING ONLY

#------------------------------------------------------------------------
# **********************************************
# ******  Add components version info    *******
# **********************************************
# echo -e '----------------------------- 4) Create Version by using the build ------------------------------'
# [ $BTI_Shown -eq 0 ] && echo -e "  $eTG Silent Info creation$eNO - don't use this as long as your not sure creation goes without errors!\n" && BTI_Shown=1
# ################################
# # Create NEW Version Info-File
# ################################
# echo -e   "-- 1) Create NEW Version Info-File (one file, not Target-specific!)"
# echo -e   "   ...at: $(shortFP $(realpath "$AR_TOOLS/esp32-arduino-libs")/)$eTG"versions.txt"$eNO"
# rm -rf "$AR_TOOLS/esp32-arduino-libs/versions.txt"
# # -------------------------
# # Write lib-builder version
# # -------------------------
# echo -e   '   ...   a) Write Lib-Builder Version'
# component_version="lib-builder: "$(git -C "$AR_ROOT" symbolic-ref --short HEAD || git -C "$AR_ROOT" tag --points-at HEAD)" "$(git -C "$AR_ROOT" rev-parse --short HEAD)
# echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
# # -------------------------
# # Write ESP-IDF version
# # -------------------------
# echo -e   '   ...   b) Write esp-idf Version'
# component_version="esp-idf: $IDF_BRANCH $IDF_COMMIT"
# echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
# # -------------------------
# # Write components version
# # -------------------------
# echo -e   '   ...   c) Components Versions'
# for component in `ls "$AR_COMPS"`; do
#     compPath=$(realpath "$AR_COMPS/$component")
#     gitFile="$compPath/.git"
#     if [ -d "$gitFile" ]; then
#         if [ "$component" == 'arduino' ]; then  # Arduino component
#             component_version="$component: $AR_BRANCH $AR_COMMIT"
#         else                                    # All other components
#             component_version="$component: "$(git -C "$compPath" symbolic-ref --short HEAD || git -C "$compPath" tag --points-at HEAD)" "$(git -C "$compPath" rev-parse --short HEAD)
#         fi
#         echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
#     fi
# done
# # -------------------------
# # Write TinyUSB version
# # -------------------------
# echo -e   '   ...   d) Write TinyUSB Version'
# component_version="tinyusb: "$(git -C "$AR_COMPS/arduino_tinyusb/tinyusb" symbolic-ref --short HEAD || git -C "$AR_COMPS/arduino_tinyusb/tinyusb" tag --points-at HEAD)" "$(git -C "$AR_COMPS/arduino_tinyusb/tinyusb" rev-parse --short HEAD)
# echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
# # ----------------------------------
# # Write managed components version
# # ---------------------------------
# echo -e   '   ...   e) Write Managed components version'
# for component in `ls "$AR_MANAGED_COMPS"`; do
#     if [ -d "$AR_MANAGED_COMPS/$component/.git" ]; then
#         component_version="$component: "$(git -C "$AR_MANAGED_COMPS/$component" symbolic-ref --short HEAD || git -C "$AR_MANAGED_COMPS/$component" tag --points-at HEAD)" "$(git -C "$AR_MANAGED_COMPS/$component" rev-parse --short HEAD)
#         echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
#     elif [ -f "$AR_MANAGED_COMPS/$component/idf_component.yml" ]; then
#         component_version="$component: "$(cat "$AR_MANAGED_COMPS/$component/idf_component.yml" | grep "^version: " | cut -d ' ' -f 2)
#         echo $component_version >> "$AR_TOOLS/esp32-arduino-libs/versions.txt"
#     fi
# done
# osascript -e 'beep 1'
# # #########################################
# # Generate JSONs
# #    - package_esp32_index.template.json
# #    - tools.json
# # #########################################
# if [ "$BUILD_TYPE" = "all" ]; then
#     # - package_esp32_index.template.json
#     echo -e "\n-- 2) Generate Package Infos (One file, not Target-specific!) with >    $eUS/tools/gen_tools_json.py$eNO"
#     echo -e   "   ...   a) Common Package Infos"
#     echo -e   "   ...      at: $(shortFP $(realpath $AR_OUT)/)$eTG"package_esp32_index.template.json"$eNO"
#     if [ $IDF_BuildInfosSilent -eq 1 ]; then
#         [ $BTI_Shown -eq 0 ] && echo -e "  $eTG Silent Info creation$eNO - don't use this as long as your not sure creation goes without errors!" && BTI_Shown=1
#         python3 $SH_ROOT/tools/gen_tools_json.py -i "$IDF_PATH" -j "$AR_COMPS/arduino/package/package_esp32_index.template.json" -o "$AR_OUT/" > /dev/null 2>&1
#     else 
#         python3 $SH_ROOT/tools/gen_tools_json.py -i "$IDF_PATH" -j "$AR_COMPS/arduino/package/package_esp32_index.template.json" -o "$AR_OUT/" 
#     fi
#     echo -e   "   ...   b) Tools Package Infos"
#     echo -e   "   ...      at: $(shortFP $(realpath $TOOLS_JSON_OUT)/)$eTG"tools.json"$eNO"
#     if [ $IDF_BuildInfosSilent -eq 1 ]; then
#         python3 $SH_ROOT/tools/gen_tools_json.py -i "$IDF_PATH" -o "$TOOLS_JSON_OUT/" > /dev/null 2>&1
#     else 
#         python3 $SH_ROOT/tools/gen_tools_json.py -i "$IDF_PATH" -o "$TOOLS_JSON_OUT/" 
#     fi
#     # - tools.json
#     if [ $? -ne 0 ]; then exit 1; fi
#     osascript -e 'beep 1'
# fi
# # ###################################
# # Generate PlatformIO manifest file
# # ###################################
# if [ "$BUILD_TYPE" = "all" ]; then
#     echo -e "\n-- 3) Generate$eTG PlatformIO$eNO manifest file with >                 $eUS/tools/gen_platformio_manifest.py$eNO"
#     #$eUS'package.json'$eNO"
#     pushd $IDF_PATH  > /dev/null
#     ibr=$(git describe --all --exact-match 2>/dev/null)
# #    export IDF_COMMIT=$(git -C "$IDF_PATH" rev-parse --short HEAD)
#     popd  > /dev/null
#     echo -e   "   ...at: $(shortFP $(realpath $TOOLS_JSON_OUT)/)$eTG"package.json"$eNO"
#     if [ $IDF_BuildInfosSilent -eq 1 ]; then
#         [ $BTI_Shown -eq 0 ] && echo -e "  $eTG Silent Info creation$eNO - don't use this as long as your not sure creation goes without errors!" && BTI_Shown=1
#         python3 $SH_ROOT/tools/gen_platformio_manifest.py -o "$TOOLS_JSON_OUT/" -s "$ibr" -c "$IDF_COMMIT" > /dev/null 2>&1
#     else
#         python3 $SH_ROOT/tools/gen_platformio_manifest.py -o "$TOOLS_JSON_OUT/" -s "$ibr" -c "$IDF_COMMIT"
#     fi    
#     if [ $? -ne 0 ]; then exit 1; fi
#     osascript -e 'beep 1'
# fi
# # ##############################################
# # Copy everything to arduino-esp32 installation
# # ##############################################
# if [ $COPY_OUT -eq 1 ]; then
#     mkdir -p $ESP32_ARDUINO # Create the Folder if it does not exist
#     echo -e "\n-- 4) Create a 'ready to use'-copy of 'arduino-esp32' with >           $eUS/tools/copy-to-arduino.sh$eNO"
#     echo -e   "   ...at: $(shortFP $ESP32_ARDUINO)"
#     source $SH_ROOT/tools/copy-to-arduino.sh
#     if [ $? -ne 0 ]; then exit 1; fi
#     osascript -e 'beep 1'
# fi
# # ##############################################
# # push changes to esp32-arduino-libs and create pull request into arduino-esp32
# # ##############################################
# if [ $DEPLOY_OUT -eq 1 ]; then
#     echo -e "\n-- 5) Push changes to esp32-arduino-libs with >                         $eUS/tools/push-to-arduino.sh$eNO"
#     echo -e   "   ...with:$eUS $SH_ROOT/tools/push-to-arduino.sh $eNO"
#     source $SH_ROOT/tools/push-to-arduino.sh
#     if [ $? -ne 0 ]; then exit 1; fi
#     osascript -e 'beep 1'
# fi
# ###############################################
# # Write *.tar.gz archive with the build stuff
# ###############################################
# if [ $ARCHIVE_OUT -eq 1 ]; then
#     echo -e "\n-- 6) Create a archive of build for Arduiono with >                      $eUS/tools/archive-build.sh$eNO"
#     source $SH_ROOT/tools/archive-build.sh "$TARGET"
#     if [ $? -ne 0 ]; then exit 1; fi
#     osascript -e 'beep 1'
# fi
# ##########################################################
# PIO create File-structure & archive *.tar.gz 
# >> adapted from GH 'Jason2866/esp32-arduino-lib-builder'
##########################################################
if [ $PIO_OUT_F -eq 1 ]; then
    echo -e "\n-- 7)$eTG PIO$eNO create File-structure & archive *.tar.gz with >$eUS           /ownTools/PIO-create-archive.sh$eNO"
    source $SH_ROOT/ownTools/PIO-create-archive.sh "$TARGET"
    if [ $? -ne 0 ]; then exit 1; fi
    osascript -e 'beep 1'
fi
echo -e '--------------------------------    DONE Create Version Info    ---------------------------------'
osascript -e 'beep 10' # Beep 10 times