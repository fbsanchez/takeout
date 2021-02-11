#!/bin/bash

FOLDER="./originales"
TARGET="./conversions"
TEMPORAL="./tmp"
if [ ! -e "$FOLDER" ]; then
	echo "You should set \"FOLDER\" to folder containing original files."
	exit 1
fi

[ -e "$TARGET" ] || mkdir -p $TARGET
[ -e "$TEMPORAL" ] || mkdir -p $TEMPORAL

find $FOLDER -iname '*.json' -type f -print0 | while IFS= read -r -d '' file; do
	datecreation="$(cat "$file"  | jq .creationTime.timestamp)"
	filename="$(echo -n "$file" | sed 's/\.json//' | sed 's/^.*\///' ).*"
	pic="$(find "$(dirname "$file")" -type f -iname "$filename"  ! -name "*.json")"
	if [ "$pic" == "" ]; then
		# Google sometimes uses file.ext.json and file.ext
		# Another times uses file.json and file.ext
		filename="$(echo -n "$file" | sed 's/\.json//' | sed 's/^.*\///' )"
		pic="$(find "$(dirname "$file")" -type f -iname "$filename"  ! -name "*.json")"
	fi
	destination="$(echo -n "$pic" | sed 's/^.*\///' )"
	targetfile="$TARGET/$destination"
	if [ -e "$pic" ]; then
		cp -f "$pic" "$targetfile"
		if [ ! -e "$targetfile" ]; then
			echo "ERROR!!  ["$targetfile"] not found."
			exit 1
		fi

		timefile="/$TEMPORAL/$destination.timestamp"

		# Calculate usable date.
		datecreation=$(echo $datecreation | tr -d '"')
		newDate=$(printf '%(%Y%m%d%H%M.%S)T\n' $datecreation);

		# Create golden file.
		touch -t $newDate "$timefile"
		
		# Apply new timestamp.
		touch -r "$timefile" "$targetfile"

		# Clear temporary files.
		rm "$timefile"
		echo " + processed: $pic"
	else
		echo " - ignored: $file"
	fi
done
