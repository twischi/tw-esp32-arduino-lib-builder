#!/bin/bash

#---------------------------------------
# Define the colors for the echo output
#---------------------------------------
export ePF="\x1B[35m"   # echo Color (Purple) for Path and File outputs
export eGI="\x1B[32m"   # echo Color (Green) for Git-Urls
export eTG="\x1B[31m"   # echo Color (Red) for Targets
export eSR="\x1B[9;31m" # echo Color (Strikethrough in Red) for Skipped Targets
export eUS="\x1B[34m"   # echo Color (blue) for Files that are executed or used 
export eNO="\x1B[0m"    # Back to    (Black)

# Function to extract file names from semicolon-separated paths and format them
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
echo "Function 'extractFileName()' and loaded successfully."