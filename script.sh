#!/usr/bin/env bash
U=""

###
# Get blocklist urls from firebog
# Copy pihole urls to tmp file
# Sort tmp file into $U
# Delete tmp file
###
get_urls(){
  curl -s https://v.firebog.net/hosts/lists.php?type=nocross -o urls.tmp
  cat list_urls/pihole.urls >> urls.tmp
  U=$(sort -u urls.tmp)
  rm -f urls.tmp
}

###
# For each URL in $U
# Download list into single file
###
get_lists(){
  for u in $U; do
    printf "==============================\n"
    printf "Downloading $u \n"
    printf "==============================\n"
    wget $u -O- >> list
  done
}

###
# I'm a little ashamed that I copy-pasted this from pihole -g
# This little function here will:
# Remove all comments, trailing '/', and IP addresses
# Returning only the domains
# Seriously, full credit for this function right here goes to the guys and gals
# over at Pi-Hole
# https://github.com/pi-hole/pi-hole/blob/master/gravity.sh#L333
###
parse_domains(){
  local source="${1}" destination="${2}"
  
  < ${source} awk -F '#' '{print $1}' | \
  awk -F '/' '{print $1}' | \
  awk '($1 !~ /^#/) { if (NF>1) {print $2} else {print $1}}' | \
  sed -nr -e 's/\.{2,}/./g' -e '/\./p' >  ${destination}
}

###
# Sort and extract unique domains
###
sort_masterlist(){
  printf "=== Sorting and extracting unique domains ===\n"
  sort -u list.domains > list.sorted
}

main(){
  get_urls
  get_lists
  parse_domains list list.domains
  sort_masterlist
}

main