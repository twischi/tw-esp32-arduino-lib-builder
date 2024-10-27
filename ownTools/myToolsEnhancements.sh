#!/bin/bash
# --------------------------------------------------
# my Tools and enhancements to origin the build.sh
# -------------------------------------------------
# This script is a collection of functions and variables 
# to enhance the build.sh script.
#    ./build.sh 
# --------------------------------

#---------------------------------------
# Define the colors for the echo output
#---------------------------------------
export ePF="\x1B[35m"   # echo Color (Purple) for Path and File outputs
export eGI="\x1B[32m"   # echo Color (Green) for Git-Urls
export eTG="\x1B[31m"   # echo Color (Red) for Targets
export eSR="\x1B[9;31m" # echo Color (Strikethrough in Red) for Skipped Targets
export eUS="\x1B[34m"   # echo Color (blue) for Files that are executed or used 
export eNO="\x1B[0m"    # Back to    (Black)

# ---------------------------------------
# Process enhanced COMMAND-LINE-ARGUMENTS
# ---------------------------------------
# Option '-G' : Save all downloads from GitHub in ONE folder, affect
# - arduino-esp32 / /- esp-idf / - esp32-arduino-libs
process_GH_Folder() {
    local oneUpDir=$(realpath $(pwd)/../)  # Find directory above the current one
    GitHubSources=$oneUpDir/GitHub-Sources # GitHub-Sources-Folder
    export GitHubSources
    mkdir -p "$GitHubSources"              # if not exists create the Target-Folder
    #echo GitHubSources="$GitHubSources"
    # -----------------------------------------
    # Set OWN Arduino Folder location (AR_PATH)
    # -----------------------------------------
        local Temp_PATH="$GitHubSources""/arduino-esp32" # New Location
        mkdir -p "$Temp_PATH" # if not exists create the Target-Folder
        # Check if symbolic link at $AR_ROOT/components/arduino NOT exists
        if [ ! -L "$PWD"/components/arduino ]; then # >> Create a symlink
            # from  <Source>       to  <target> new Folder that's symlink
            ln -s   "$Temp_PATH"       "$PWD"/components/arduino > /dev/null
        fi
    # ----------------------------------------------
    # Set OWN Arduino Folder location (IDF_LIBS_DIR)
    # ----------------------------------------------
        local Temp_PATH="$GitHubSources""/esp32-arduino-libs" # New Location
        mkdir -p "$Temp_PATH" # if not exists create the Target-Folder
        # Modify path to 'esp32-arduino-libs'
        export IDF_LIBS_DIR=$(realpath "$Temp_PATH"/../)/esp32-arduino-libs
    # -----------------------------------------
    # Set OWN IDF-Folder location (IDF_PATH)
    # -----------------------------------------
        local Temp_PATH="$GitHubSources""/esp-idf" # New Location
        mkdir -p "$Temp_PATH" # if not exists create the Target-Folder
        # Check if symbolic link at $AR_ROOT/esp-idf NOT exists
        if [ ! -L $PWD/esp-idf ]; then # >> Create a symlink 
            # from  <Source>       to  <target> new Folder that's symlink
            ln -s   "$Temp_PATH"      "$PWD"/esp-idf > /dev/null
        fi
    #ls -la "$GitHubSources"
    # echo "Press Enter to continue..." && read
}     
# Option '-o' : Set OWN arduino-esp32-BUILD Output Folder location
process_OWN_OutFolder_AR() {
    # ---------------------------------------------------
    # Set OWN arduino-esp32-BUILD Output Folder location
    # ---------------------------------------------------
    local oneUpDir=$(realpath $(pwd)/../)  # Find directory above the current one
    export AR_Build_Output="$oneUpDir"/"OUT-from_build" # Define Output Folder path
    mkdir -p "$AR_Build_Output" # if not exists create the Target-Folder
    local StdOut="$PWD"/out
    # Check if StdOut folder is already a symlink
    if [ ! -L "$StdOut" ]; then
         echo "StdOut NOT a symlink"
        # Check if StdOut folder exists
        if [ -d "$StdOut" ]; then
            # StdOut folder exists
            echo "StdOut Standard folder EXISTS"
            rm -rf "$StdOut" # Delete Standard-Target-Folder
            # >> Create a symlink
            # from  <Source>          to  <target> new Folder that's symlink
            ln -s  "$AR_Build_Output"     "$StdOut"  > /dev/null
        else 
            # StdOut folder does not exist
            echo "StdOut Standard folder NOT EXISTS"
            # >> Create a symlink        
            # from  <Source>          to  <target> new Folder that's symlink
            ln -s  "$AR_Build_Output"     "$StdOut"  > /dev/null
            echo "synlink created"
        fi
    fi
}
#-------------------------------------------------------------------------------
# Function to extract file names from semicolon-separated paths and format them
#-------------------------------------------------------------------------------
extractFileName() {
    local configs="$1"
    # Convert the semicolon-separated string into an array
    IFS=';' read -ra paths <<< "$configs"   
    # Initialize an empty array to hold file names
    local helperArray=()
    # Iterate over each path and extract the file name
    for path in "${paths[@]}"; do
        local extractedFN
        extractedFN=$(basename "$path")
        helperArray+=("$extractedFN")
    done
    local result
    # Join the file names into a semicolon-separated string
    result=$(IFS=';'; echo "${helperArray[*]}")
    # Replace semicolons with " - " for better readability
    result=${result//;/ - }
    echo "$result"
}

# Function to shorten the File-Pathes for put buy remove parts
# usage: echo -e "$(shortFP "/Users/thomas/JOINED/esp32-arduino-lib-builder/out/tools")
shortFP() {   
    local filePathLong="$1"
    local removePart="$(realpath $(pwd)/../)/" # DIR above the current directory
    local filePathShort=$(echo "$filePathLong" | sed "s|$removePart||")     
    echo "$ePF$filePathShort$eNO"
}
echo "myTools & Enhancements > Variables & Functions loaded successfully."