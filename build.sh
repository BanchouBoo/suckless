#!/bin/sh

############################### SETTINGS ##############################

ST_VERSION=51e19ea11dd42eefed1ca136ee3f6be975f618b1    # Feb 18 2020
DWM_VERSION=cb3f58ad06993f7ef3a7d8f61468012e2b786cab   # Feb 02 2019
SLOCK_VERSION=35633d45672d14bd798c478c45d1a17064701aa9 # Mar 25 2017

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
	die "Usage: ./build.sh [dwm] [st]"
}

clone() {
	mkdir -p .builds && cd .builds
	[ -d "$1" ] || git clone "git://git.suckless.org/$1"
	cd "$1"
	git clean -df
	git fetch --all
	git reset --hard "$2"
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
		*)
			die "Invalid option '$name'"
			;;
	esac

	source_path="$SCRIPT_PATH/$name"
	build_path="$SCRIPT_PATH/.builds/$name"

	cd "$build_path"

	while read -r patch; do
		patch_path="$source_path/$patch"
		[ -f "$patch_path" ] || die "$patch_path is not a file"
		log "Applying $patch..."
		patch -F 3 -l -p1 < "$patch_path"
	done < "$source_path/patchlist"

	printf "\n"

	[ -f "$source_path/config.h" ] && cp -i "$source_path/config.h" "$build_path"

	make clean > /dev/null
	sudo make install

	cd "$SCRIPT_PATH"
done
