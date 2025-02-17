#!/bin/bash

PREFIX="Copyright \(c\)"
PUBLISHED_YEAR="2016"
CURRENT_YEAR=$(date +"%Y")
OWNER="Yegor Bugayenko"

OLD_COPYRIGHT="$PREFIX $PUBLISHED_YEAR-[0-9]{4} $OWNER"
NEW_COPYRIGHT="$PREFIX $PUBLISHED_YEAR-$CURRENT_YEAR $OWNER"

TARGETS=(
  "." # or set specific directory/files
)

update_copyright_year() {
  local file=$1
  sed -i -E "s/$OLD_COPYRIGHT/$NEW_COPYRIGHT/g" "$file"
}

find "${TARGETS[@]}" -type f | while read -r file; do
  update_copyright_year "$file"
done

print_success_message() {
  local G="\033[0;32m" # GREEN
  local Y="\033[1;33m" # YELLOW
  local R="\033[0m"    # RESET

  echo -e "${G}           ${R}*${G}-${R}*${G},"
  echo -e "${G}       ,${R}*${G}\\/|\'| \\"
  echo -e "${G}       \'  | |\'| ${R}*${G},"
  echo -e "${G}        \\ \\\`| | |/ )"
  echo -e "${G}         | |\'| , /"
  echo -e "${G}         |\'| |, /"
  echo -e "${Y}       __${G}|${Y}_${G}|${Y}_${G}|${Y}_${G}|${Y}__"
  echo -e "${Y}      [___________]"
  echo -e "${Y}       |         |"
  echo -e "${Y}       |         |"
  echo -e "${Y}       |         |"
  echo -e "${Y}       |_________|"
  echo -e "${R}"

  echo "Copyright years updated to $CURRENT_YEAR"
}

print_success_message

