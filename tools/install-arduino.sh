#/bin/bash

source $SH_ROOT/tools/config.sh
echo     "...Component ESP32 Arduino installing/updating local copy...."
# ------------------------------------------------
# Checks for set Variables AR_COMMIT & AR_BRANCH
# -----------------------------------------------
# Check if COMMIT is set >> ALLWAYS WINs!
if [ ! -z $AR_COMMIT ]; then
	# YES >> AR_COMMIT is SET 
	# Check if BRANCH ist set in addition
	if [ ! -z $AR_BRANCH ]; then
		# YES >> AR_BRANCH is SET
		# Error Message & Exit 
		echo -e "  $eTG ERROR in Arguments for <arduino-esp32>:"
		echo -e "   >> BOTH 'AR_COMMIT' & 'AR_BRANCH' are set. Only ONE of it is allowed!$eNO"
		exit 1
	fi 
fi
# --------------------------------------------
# Get <arduino-esp32> Folder arduino
#    -by cloning or updating, if already there
# --------------------------------------------
ArduionoCOMPS=$(realpath "$AR_COMPS/arduino")
if [ -d "$ArduionoCOMPS" ] && [ -z "$(ls -A "$ArduionoCOMPS")" ]; then
	mkdir -p $ArduionoCOMPS # create the directory if not exists
	echo -e "   cloning $eGI$AR_REPO_URL$eNO\n   to: $(shortFP $ArduionoCOMPS)"
	git clone $AR_REPO_URL "$ArduionoCOMPS" --quiet
else
	echo -e "   updating (already there)$eGI $AR_REPO_URL$eNO\n   to: $(shortFP $ArduionoCOMPS)"
	git -C $ArduionoCOMPS fetch --tags --quiet
fi
#--------------------------------------------------------
# Checkout, could be BRANCH, COMMIT or TAG
#--------------------------------------------------------
if [ "$AR_BRANCH" ]; then
	# BRANCH
	echo -e "...Checkout BRANCH:$eTG '$AR_BRANCH'$eNO"
	git -C $ArduionoCOMPS pull --ff-only --quiet
	git -C $ArduionoCOMPS checkout "$AR_BRANCH" --quiet
elif [ "$AR_COMMIT" ]; then
	# COMMIT
	echo -e "...Checkout COMMIT:$eTG '$AR_COMMIT'$eNO"
	git -C $ArduionoCOMPS checkout "$AR_COMMIT" --quiet
	export AR_BRANCH=$(git -C "$ArduionoCOMPS" branch --contains "$AR_COMMIT" | sed '/^\*/d' | sed 's/^[[:space:]]*//') # Remove lines starting with '*' as it name the current head
	echo -e "   Branch of the Commit is at: $eTG$AR_BRANCH$eNO"
elif [ ! -z "$AR_TAG" ]; then
	# TAG
	echo -e "   checkout TAG:$eTG $AR_TAG$eNO"
	export AR_BRANCH=$(git -C "$ArduionoCOMPS" branch --contains "$AR_COMMIT" | sed '/^\*/d' | sed 's/^[[:space:]]*//') # Remove lines starting with '*' as it name the current head
    git -C "$ArduionoCOMPS" checkout $AR_TAG --quiet
fi
#--------------------------------------------------------
# Get additional infos
#--------------------------------------------------------
if [ -z "$AR_BRANCH" ] && [ -z "$AR_COMMIT" ]  && [ -z "$AR_TAG" ]; then
	# Set HEAD_REF if not already set 
	if [ -z $GITHUB_HEAD_REF ]; then
		current_branch=`git branch --show-current --quiet`
	else
		current_branch="$GITHUB_HEAD_REF"
	fi
	echo -e "   Current Branch:$eTG $current_branch $eNO"
	if [[ "$current_branch" != "master" && `git_branch_exists "$ArduionoCOMPS" "$current_branch"` == "1" ]]; then
		export AR_BRANCH="$current_branch"
	else
		if [ "$IDF_TAG" ]; then #tag was specified at build time
			AR_BRANCH_NAME="idf-$IDF_TAG"
		elif [ "$IDF_COMMIT" ]; then #commit was specified at build time
			AR_BRANCH_NAME="idf-$IDF_COMMIT"
		else
			AR_BRANCH_NAME="idf-$IDF_BRANCH"
		fi
		has_ar_branch=`git_branch_exists "$ArduionoCOMPS" "$AR_BRANCH_NAME"`
		if [ "$has_ar_branch" == "1" ]; then
			export AR_BRANCH="$AR_BRANCH_NAME"
		else
			has_ar_branch=`git_branch_exists "$ArduionoCOMPS "$AR_PR_TARGET_BRANCH"`
			if [ "$has_ar_branch" == "1" ]; then
				export AR_BRANCH="$AR_PR_TARGET_BRANCH"
			fi
		fi
	fi
fi
# $?: Status of the last executed command => 0:OK, 1:Error 
if [ $? -ne 0 ]; then exit 1; fi
#--------------------------------------------------------
# Get esp32-arduino-libs COMPONENT
#--------------------------------------------------------
if [ ! -d "$IDF_LIBS_DIR" ]; then
	echo -e "...Cloning esp32-arduino-libs from: $eGI$AR_LIBS_REPO_URL$eNO"
	echo -e "   to: $(shortFP $IDF_LIBS_DIR)"
	git clone "$AR_LIBS_REPO_URL" "$IDF_LIBS_DIR" --quiet
else
	echo -e "...Updating existing esp32-arduino-libs from $eGI$AR_LIBS_REPO_URL$eNO"
	echo -e "   in: $(shortFP $(realpath $IDF_LIBS_DIR))"
	#git -C "$IDF_LIBS_DIR" fetch --quiet && \
	#git -C "$IDF_LIBS_DIR" pull --quiet --ff-only
	git -C $IDF_LIBS_DIR fetch --tags --quiet
fi
if [ $? -ne 0 ]; then exit 1; fi