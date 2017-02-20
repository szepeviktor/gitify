#!/bin/bash
#
# Convert release zip archives to a git repository.
#
# VERSION       :0.2.0
# DATE          :2017-02-20
# URL           :https://github.com/szepeviktor/gitify
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install unzip
# CI            :shelllcheck gitify-zips.sh
# SEMVER_SH     :https://github.com/warehouseman/semver_bash
# LOCATION      :/usr/local/bin/gitify-zips.sh

# Usage
#
#     gitify-zips.sh "sitepress-multilingual-cms."


# --- BEGIN semver.sh ---

function semverParseInto() {
    val=$1;
    if [[ "X${val}X" == "XX" ]]; then val="0.0.0"; fi;
    local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)[-]\{0,1\}\([0-9A-Za-z.-]*\)'
    #MAJOR
    eval $2=`echo ${val} | sed -e "s#$RE#\1#"`
    #MINOR
    eval $3=`echo ${val} | sed -e "s#$RE#\2#"`
    #MINOR
    eval $4=`echo ${val} | sed -e "s#$RE#\3#"`
    #SPECIAL
    eval $5=`echo ${val} | sed -e "s#$RE#\4#"`
}

function semverConstruct() {
    if [[ $# -eq 5 ]]; then
        eval $5=`echo "$1.$2.$3-$4"`
    fi

    eval $4=`echo "$1.$2.$3"`
}

function semverCmp() {
    local MAJOR_A=0
    local MINOR_A=0
    local PATCH_A=0
    local SPECIAL_A=0

    local MAJOR_B=0
    local MINOR_B=0
    local PATCH_B=0
    local SPECIAL_B=0

    semverParseInto "$1" MAJOR_A MINOR_A PATCH_A SPECIAL_A
    semverParseInto "$2" MAJOR_B MINOR_B PATCH_B SPECIAL_B

    # major
    if [ $MAJOR_A -lt $MAJOR_B ]; then
        return -1
    fi

    if [ $MAJOR_A -gt $MAJOR_B ]; then
        return 1
    fi

    # minor
    if [ $MINOR_A -lt $MINOR_B ]; then
        return -1
    fi

    if [ $MINOR_A -gt $MINOR_B ]; then
        return 1
    fi

    # patch
    if [ $PATCH_A -lt $PATCH_B ]; then
        return -1
    fi

    if [ $PATCH_A -gt $PATCH_B ]; then
        return 1
    fi

    # special
    if [[ ( "$SPECIAL_A" == "" ) && ( "$SPECIAL_B" != "" ) ]]; then
        return -1
    fi

    if [[ ( "$SPECIAL_A" != "" ) && ( "$SPECIAL_B" == "" ) ]]; then
        return 1
    fi

    if [[ "$SPECIAL_A" < "$SPECIAL_B" ]]; then
        return -1
    fi

    if [[ "$SPECIAL_A" > "$SPECIAL_B" ]]; then
        return 1
    fi

    # equal
    return 0
}

function semverEQ() {
    semverCmp $1 $2
    local RESULT=$?

    if [ $RESULT -ne 0 ]; then
        # not equal
        return 1
    fi

    return 0
}

function semverLT() {
    semverCmp $1 $2
    local RESULT=$?

    # XXX: compare to 255, as returning -1 becomes return value 255
    if [ $RESULT -ne 255 ]; then
        # not lesser than
        return 1
    fi

    return 0
}

function semverGT() {
    semverCmp $1 $2
    local RESULT=$?

    if [ $RESULT -ne 1 ]; then
        # not greater than
        return 1
    fi

    return 0
}

function semverBumpMajor() {
    local MAJOR=0
    local MINOR=0
    local PATCH=0
    local SPECIAL=""

    semverParseInto $1 MAJOR MINOR PATCH SPECIAL
    MAJOR=$(($MAJOR + 1))
    MINOR=0
    PATCH=0
    SPECIAL=""

    semverConstruct $MAJOR $MINOR $PATCH $SPECIAL $2
}

function semverBumpMinor() {
    local MAJOR=0
    local MINOR=0
    local PATCH=0
    local SPECIAL=""

    semverParseInto $1 MAJOR MINOR PATCH SPECIAL
    MINOR=$(($MINOR + 1))
    PATCH=0
    SPECIAL=""

    semverConstruct $MAJOR $MINOR $PATCH $SPECIAL $2
}

function semverBumpPatch() {
    local MAJOR=0
    local MINOR=0
    local PATCH=0
    local SPECIAL=""

    semverParseInto $1 MAJOR MINOR PATCH SPECIAL
    PATCH=$(($PATCH + 1))
    SPECIAL=""

    semverConstruct $MAJOR $MINOR $PATCH $SPECIAL $2
}

function semverStripSpecial() {
    local MAJOR=0
    local MINOR=0
    local PATCH=0
    local SPECIAL=""

    semverParseInto $1 MAJOR MINOR PATCH SPECIAL
    SPECIAL=""

    semverConstruct $MAJOR $MINOR $PATCH $SPECIAL $2
}

if [ "___semver.sh" == "___`basename $0`" ]; then
    if [ "$2" == "" ]; then
        echo "$0 <version> <command> [version]"
        echo "Commands: cmp, eq, lt, gt, bump_major, bump_minor, bump_patch, strip_special"
        echo ""
        echo "cmp: compares left version against right version, return 0 if equal, 255 (-1) if left is lower than right, 1 if left is higher than right"
        echo "eq: compares left version against right version, returns 0 if both versions are equal"
        echo "lt: compares left version against right version, returns 0 if left version is less than right version"
        echo "gt: compares left version against right version, returns 0 if left version is greater than than right version"
        echo ""
        echo "bump_major: bumps major of version, setting minor and patch to 0, removing special"
        echo "bump_minor: bumps minor of version, setting patch to 0, removing special"
        echo "bump_patch: bumps patch of version, removing special"
        echo ""
        echo "strip_special: strips special from version"
        exit 255
    fi

    if [ "$2" == "cmp" ]; then
        semverCmp $1 $3
        RESULT=$?
        echo $RESULT
        exit $RESULT
    fi

    if [ "$2" == "eq" ]; then
        semverEQ $1 $3
        RESULT=$?
        echo $RESULT
        exit $RESULT
    fi

    if [ "$2" == "lt" ]; then
        semverLT $1 $3
        RESULT=$?
        echo $RESULT
        exit $RESULT
    fi

    if [ "$2" == "gt" ]; then
        semverGT $1 $3
        RESULT=$?
        echo $RESULT
        exit $RESULT
    fi

    if [ "$2" == "bump_major" ]; then
        semverBumpMajor $1 VERSION
        echo ${VERSION}
        exit 0
    fi

    if [ "$2" == "bump_minor" ]; then
        semverBumpMinor $1 VERSION
        echo ${VERSION}
        exit 0
    fi

    if [ "$2" == "bump_patch" ]; then
        semverBumpPatch $1 VERSION
        echo ${VERSION}
        exit 0
    fi

    if [ "$2" == "strip_special" ]; then
        semverStripSpecial $1 VERSION
        echo ${VERSION}
        exit 0
    fi
fi

# --- END semver.sh ---

On_exit() {
    local -i STATUS="$1"
    local BASH_CMD="$2"

    set +e

    if [ "$STATUS" -ne 0 ]; then
        echo "ERROR at command: \`${BASH_CMD}\`" 1>&2
    fi

    exit "$STATUS"
}

Get_raw_version() {
    local FILE_NAME="$1"
    local RAW_VERSION

    # Remove prefix and suffix
    RAW_VERSION="${FILE_NAME#${NAME_PREFIX}}"
    RAW_VERSION="${RAW_VERSION%${SUFFIX}}"

    if [ -z "$RAW_VERSION" ]; then
        exit 100
    fi

    echo "$RAW_VERSION"
}

Get_version() {
    local FILE_NAME="$1"
    local VERSION

    VERSION="$(Get_raw_version "$FILE_NAME")"

    # Convert "1.2" to "1.2.0"
    if [ "${VERSION//[^.]/}" == "." ]; then
        VERSION="$(sed -e 's|^\(.\+\)\.\(.\+\)$|\1.\2.0|' <<< "$VERSION")"
    fi
    semverParseInto "$VERSION" MAJOR_A MINOR_A PATCH_A SPECIAL_A
    # Check version
    if [ -z "$MAJOR_A" ] || [ -z "$MINOR_A" ] || [ -z "$PATCH_A" ]; then
        exit 100
    fi
    # Fix dotSPECIAL
    if [ "${SPECIAL_A:0:1}" == "." ]; then
        SPECIAL_A="${SPECIAL_A:1}"
    fi

    if [ -n "$SPECIAL_A" ]; then
        echo "${MAJOR_A}.${MINOR_A}.${PATCH_A}-${SPECIAL_A}"
    else
        echo "${MAJOR_A}.${MINOR_A}.${PATCH_A}"
    fi
}

# Constants
declare -r SUFFIX=".zip"
declare -r GITIFY_DIR="git"

declare -A RELEASES
declare -a RELEASES_KEYS
declare -i BUBBLE="1"
declare -i SKIPPED="1"

trap 'On_exit "$?" "$BASH_COMMAND"' EXIT HUP INT QUIT PIPE TERM

set -e

NAME_PREFIX="$1"

# Empty prefix?
test -n "$NAME_PREFIX"

# At least one file exists?
test -n "$(find -maxdepth 1 -type f -name "${NAME_PREFIX}*")"

# Parse zip names
ALL_ZIPS="$(find -maxdepth 1 -type f -name "${NAME_PREFIX}*" -printf "%P\n")"
while read -r ZIP; do
    RAW_VERSION="$(Get_raw_version "$ZIP")"
    RELEASE="$(Get_version "$ZIP")"
    RELEASES[${RELEASE}]+="$RAW_VERSION"
done <<< "$ALL_ZIPS"

# Check uniqueness
test -z "$(echo "${!RELEASES[@]}" | tr ' ' '\n' | sort | uniq --repeated)"

# Create repo dir
if ! [ -d "$GITIFY_DIR" ]; then
    mkdir "${GITIFY_DIR}"
    if ! [ -d "${GITIFY_DIR}/.git" ]; then
        git --git-dir="${GITIFY_DIR}/.git" init
    fi
fi

# Bubble sort releases
RELEASES_KEYS=( "${!RELEASES[@]}" )
while [ "$BUBBLE" -eq 1 ]; do
    # Progress indicator
    echo -n "."
    BUBBLE="0"
    SKIPPED="0"
    for INDEX in "${!RELEASES_KEYS[@]}"; do
        # Skip first element
        if [ "$SKIPPED" == 0 ]; then
            SKIPPED="1"
            PREVIOUS="$INDEX"
            continue
        fi

        # Swap elements
        if semverGT "${RELEASES_KEYS[$PREVIOUS]}" "${RELEASES_KEYS[$INDEX]}"; then
            BUBBLE="1"
            BUFFER="${RELEASES_KEYS[$INDEX]}"
            RELEASES_KEYS[$INDEX]="${RELEASES_KEYS[$PREVIOUS]}"
            RELEASES_KEYS[$PREVIOUS]="$BUFFER"
        fi

        PREVIOUS="$INDEX"
    done
done

# Gitify!
cd "$GITIFY_DIR" || exit 101
for RELEASE in "${RELEASES_KEYS[@]}"; do
    RAW_VERSION="${RELEASES[${RELEASE}]}"
    ZIP="${NAME_PREFIX}${RAW_VERSION}${SUFFIX}"
    # Deletes dotfiles also
    git rm -qrf -- * &> /dev/null || true
    unzip -q "../${ZIP}"

    # Detect one parent directory
    ONE_DIR="$(find -mindepth 1 -maxdepth 1 -type d -not -name ".git")"
    if [ -z "$(find -maxdepth 1 -type f)" ] && [ "$(echo "$ONE_DIR" | wc -l)" == 1 ]; then
        (
            # Move dotfiles also
            shopt -s dotglob nullglob
            mv "$ONE_DIR"/* .
            rmdir "$ONE_DIR"
        )
    fi

    # Commit all quietly
    git add --all
    # Release without changes causes an error
    git commit -q -m "Release ${RAW_VERSION} from ${ZIP}"
    git tag "v${RAW_VERSION}"
    echo "Processed release ${RAW_VERSION} from ${ZIP}."
done

# Success feedback
echo "OK."
