#/bin/bash

source $SH_ROOT/tools/config.sh

#---------------
# Check for SED
#---------------
if ! [ -x "$(command -v $SED)" ]; then
  	echo "ERROR: $SED is not installed! Please install $SED first."
  	exit 1
fi
# ------------------------------------------------
# Processing for new OPTION -f > IDF_PATH is given
# ------------------------------------------------
if [ ! -z $IDF_PATH_OWN ]; then
	# ********  Other <esp-idf>-Path ********
	# Check if symbolic link at $AR_ROOT/components/arduino already exists
	if [ ! -L $AR_ROOT/esp-idf ]; then
		# NOT there, than >> Create a symlink 
		# from  <Source>     to  <target> new Folder that's symlink
		ln -s   $IDF_PATH_OWN    $AR_ROOT/esp-idf > /dev/null
	fi
fi
#--------------------------------
# Get <esp-idf> 
#--------------------------------
echo "...ESP-IDF installing local copy..."
# ................................
# Get it by cloning or updating
# ................................
if [ ! -d "$IDF_PATH" ]; then
	mkdir -p $IDF_PATH # create the directory if not exists
	echo -e "   cloning $eGI$IDF_REPO_URL$eNO\n   to: $(shortFP $IDF_PATH)"
#	git clone $IDF_REPO_URL -b $IDF_BRANCH $IDF_PATH --quiet
	git clone $IDF_REPO_URL $IDF_PATH --quiet
	idf_was_installed="1"
else
	echo -e "   updating(already there)$eGI $IDF_REPO_URL$eNO\n   to: $(shortFP $IDF_PATH)"
	git -C "$IDF_PATH" fetch --tags --quiet
fi
# ................................
# Checkout what is given, BRANCH, COMMIT or TAG
# ................................
if  [ ! -z "$IDF_BRANCH" ]; then
	# BRANCH
	echo -e "   Checkout Branch:$eTG '$IDF_BRANCH' $eNO"
	git -C "$IDF_PATH" pull --ff-only --quiet
	git -C "$IDF_PATH" checkout $IDF_BRANCH --quiet
elif [ ! -z "$IDF_COMMIT" ]; then
	# COMMIT
	echo -e "   checkout $IDF_COMMIT of: $(shortFP $IDF_PATH)"
    git -C "$IDF_PATH" checkout "$IDF_COMMIT" --quiet
	commit_predefined="1"
elif [ ! -z "$IDF_TAG" ]; then
	# TAG
	echo -e "   checkout $IDF_TAG of: $(shortFP $IDF_PATH)"
    git -C "$IDF_PATH" checkout $IDF_TAG --quiet
    idf_was_installed="1"
fi
# .........................................
# Get current (IDF_COMMIT) and (IDF_BRANCH)
# .........................................
echo "...export environment variables..."
export IDF_COMMIT=$(git -C "$IDF_PATH" rev-parse --short HEAD)
if  [ -z "$IDF_BRANCH" ]; then  # BRANCH was not set before  > means > TAG or COMMIT was given
	branchOfCommit=$(git -C $IDF_PATH branch --contains $IDF_COMMIT | sed '/^\*/d' | sed 's/^[[:space:]]*//') # Remove lines starting with '*' as it name the current head
	export IDF_BRANCH=$branchOfCommit
fi
echo -e "         (IDF_COMMIT)= $IDF_COMMIT\t//\t(IDF_BRANCH)= $IDF_BRANCH"
#----------------------------------------------------------------------
# CHECKOUT esp32-arduino-libs that has be loaded with Arduino -Install
#----------------------------------------------------------------------
# Inherit Branch-Name from <esp-idf>-Branch
libsBRANCH="idf-$IDF_BRANCH" # HOPE there is a systematic behind that will work in future too
echo "...esp32-arduino-libs installing locally ..."
echo -e "   Checkout Branch:$eTG '$libsBRANCH' $eNO   to: $(shortFP $IDF_LIBS_DIR)"
git -C "$IDF_LIBS_DIR" checkout $libsBRANCH --quiet
#----------------------------------
# UPDATE ESP-IDF TOOLS AND MODULES
#----------------------------------
echo "...Updating IDF-Tools and Modules"
echo "   to same path like above"
git -C $IDF_PATH submodule update --init --recursive --quiet
# submodule:   Command to work with submodules inside this repository.
# update:      Action to updates submodules to the commit specified in the superproject's
# --init:      If a submodule is not initzialzed, initzialize it.
# --recursive: Update submodules recursively if nested submodules are found.
if [ ! -x $idf_was_installed ] || [ ! -x $commit_predefined ]; then
	echo -e "...Installing ESP-IDF Tools"
	[ $IS_Shown -eq 0 ] && [ $IDF_InstallSilent -eq 1 ] && echo -e "  $eTG Silent install$eNO - don't use this as long as your not sure install goes without errors!" && IS_Shown=1
	echo -e "   with:                                                       $(shortFP $IDF_PATH/install.sh)"
	# BUG FIX
	# Change to LIB folder to avoid error in the install script
	if [ $IDF_InstallSilent -eq 1 ] ; then
		$IDF_PATH/install.sh > /dev/null
	else
		echo "   NOT Silent install - use this if you want to see the output of the install script!"
		$IDF_PATH/install.sh 
	fi
	# Temporarily patch the ESP32-S2 I2C LL driver to keep the clock source
	cd $IDF_PATH
	echo "...Patch difference..."
	patchFile=$(realpath $SH_ROOT'/patches/esp32s2_i2c_ll_master_init.diff')
	patch --quiet -p1 -N -i $patchFile > /dev/null
	cd - > /dev/null
fi
#----------------------------------
# SETUP ESP-IDF ENV
#----------------------------------
echo -e "...Setting up ESP-IDF Environment"
[ $IS_Shown -eq 0 ] && [ $IDF_InstallSilent -eq 1 ] && echo -e "  $eTG Silent install$eNO - don't use this as long as your not sure install goes without errors!" && IS_Shown=1  
echo -e "   with:                                                         $(shortFP $IDF_PATH/export.sh)"
if [ $IDF_InstallSilent -eq 1 ] ; then
	source $IDF_PATH/export.sh > /dev/null
else
	echo "   NOT Silent install - use this if you want to see the output of the install script!"
	source $IDF_PATH/export.sh
fi
#----------------------------------
# SETUP ARDUINO DEPLOY
#----------------------------------
if [ "$GITHUB_EVENT_NAME" == "schedule" ] || [ "$GITHUB_EVENT_NAME" == "repository_dispatch" -a "$GITHUB_EVENT_ACTION" == "deploy" ]; then
	echo "...Setting up Arduino Deploy"
	# format new branch name and pr title
	if [ -x $commit_predefined ]; then #commit was not specified at build time
		AR_NEW_BRANCH_NAME="idf-$IDF_BRANCH"
		AR_NEW_COMMIT_MESSAGE="IDF $IDF_BRANCH $IDF_COMMIT"
		AR_NEW_PR_TITLE="IDF $IDF_BRANCH"
	else
		AR_NEW_BRANCH_NAME="idf-$IDF_COMMIT"
		AR_NEW_COMMIT_MESSAGE="IDF $IDF_COMMIT"
		AR_NEW_PR_TITLE="$AR_NEW_COMMIT_MESSAGE"
	fi
	LIBS_VERSION="idf-"${IDF_BRANCH//\//_}"-$IDF_COMMIT"

	AR_HAS_COMMIT=`git_commit_exists "$AR_COMPS/arduino" "$AR_NEW_COMMIT_MESSAGE"`
	AR_HAS_BRANCH=`git_branch_exists "$AR_COMPS/arduino" "$AR_NEW_BRANCH_NAME"`
	AR_HAS_PR=`github_pr_exists "$AR_REPO" "$AR_NEW_BRANCH_NAME"`

	LIBS_HAS_COMMIT=`git_commit_exists "$IDF_LIBS_DIR" "$AR_NEW_COMMIT_MESSAGE"`
	LIBS_HAS_BRANCH=`git_branch_exists "$IDF_LIBS_DIR" "$AR_NEW_BRANCH_NAME"`

	if [ "$LIBS_HAS_COMMIT" == "1" ]; then
		echo "Commit '$AR_NEW_COMMIT_MESSAGE' Already Exists in esp32-arduino-libs"
	fi

	if [ "$AR_HAS_COMMIT" == "1" ]; then
		echo "Commit '$AR_NEW_COMMIT_MESSAGE' Already Exists in arduino-esp32"
	fi

	if [ "$LIBS_HAS_COMMIT" == "1" ] && [ "$AR_HAS_COMMIT" == "1" ]; then
		exit 0
	fi

	export AR_NEW_BRANCH_NAME
	export AR_NEW_COMMIT_MESSAGE
	export AR_NEW_PR_TITLE

	export AR_HAS_COMMIT
	export AR_HAS_BRANCH
	export AR_HAS_PR

	export LIBS_VERSION
	export LIBS_HAS_COMMIT
	export LIBS_HAS_BRANCH
fi