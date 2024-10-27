#!/bin/bash

#---------------------------------------------------------
# Get the Infos IDF Infos used for bulid: Commit, Branch 
# to create IDF-Version-String
#---------------------------------------------------------
idf_version_string=${IDF_BRANCH//\//_}"-$IDF_COMMIT"
# ----------------------
# Set the archive path
# ----------------------
         archiveFN="arduino-esp32-libs-$1-$idf_version_string.tar.gz"
#archive_path="dist/arduino-esp32-libs-$1-$idf_version_string.tar.gz"
#-----------------------------------
# Set the DIRERCTORY for the archive
#-----------------------------------
targetFolder=$(realpath $SH_ROOT/../)/Arduino
# ---------------------------------------------
# Make DIR and remove Target-File if it exists
# ---------------------------------------------
mkdir -p $targetFolder 
rm -rf "$targetFolder/$archiveFN"
# ---------------------------------------------
# Create the Archive with tar
# ---------------------------------------------
if [ -d $sourceFolder ]; then
	echo -e "       to Folder: $(shortFP $targetFolder)/"
	echo -e "       Filename: $ePF $archiveFN $eNO"
	currentDir=$(pwd)
	cd $sourceFolder # Change to the out-Folder
	tar -zcf "$targetFolder/$archiveFN" * # Create the Archive
	cd $currentDir
	# cd out && tar zcf "../$archive_path" * && cd ..
fi