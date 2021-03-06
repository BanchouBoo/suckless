#!/bin/sh

############################### SETTINGS ##############################

ST_VERSION=045a0fab4f80b57f4a982ae6bc5f33fe21d66111    # May 06 2020
DWM_VERSION=a8e9513783f335b1ac7255e40a663adfffc4b475   # Apr 20 2020
SLOCK_VERSION=35633d45672d14bd798c478c45d1a17064701aa9 # Mar 25 2017
DVTM_VERSION=311a8c0c28296f8f87fb63349e0f3254c7481e14  # Mar 30 2018
BOOX_VERSION=bbbb883436d505b5f85cbb3024d14c82da548d9b  # Jul 31 2020

SCRIPT_PATH="$(realpath "$(dirname "$0")")"

#######################################################################

log() {
	printf "\n[ \033[00;34m..\033[0m ] %s\n" "$@"
}

die() {
	>&2 printf "[\033[0;31m xx \033[0m] %s\n" "$@"
	exit 1
}

usage() {
	die "Usage: ./build.sh [dwm] [st] [slock] [dvtm] [crud]"
}

clone() {
	name="$1"
	commit="$2"
	gitbaseurl="${3:-git://git.suckless.org}"

	mkdir -p .builds && cd .builds
	[ -d "$name" ] || git clone "$gitbaseurl/$name"
	cd "$name"
	git clean -df
	git fetch --all
	git reset --hard "$commit"
	cd "$SCRIPT_PATH"
}

[ "$1" ] || usage

cd "$SCRIPT_PATH"

for name in "$@"; do
	case "$name" in
		st)
			clone "$name" "$ST_VERSION"
			;;
		dwm)
			clone "$name" "$DWM_VERSION"
			;;
		slock)
			clone "$name" "$SLOCK_VERSION"
			;;
		dvtm)
			clone "$name" "$DVTM_VERSION" "git://github.com/martanne"
			;;
		boox)
			clone "$name" "$BOOX_VERSION" "git://github.com/BanchouBoo"
			;;
		*)
			die "Invalid option '$name'"
			;;
	esac

	source_path="$SCRIPT_PATH/$name"
	build_path="$SCRIPT_PATH/.builds/$name"

	cd "$build_path"

	sed -e 's/#.*$//g' -e '/^[[:space:]]*$/d' "$source_path/patchlist" | \
	while read -r patch; do
		patch_path="$source_path/$patch"
		[ -f "$patch_path" ] || die "$patch_path is not a file"
		log "Applying $patch..."
		patch -F 3 -l -p1 < "$patch_path"
	done

	printf "\n"

	[ -d "$source_path/cfg" ] && cp -r "$source_path/cfg"/* "$build_path"

	make clean > /dev/null
	make -j 8 && make install

	cd "$SCRIPT_PATH"
done
