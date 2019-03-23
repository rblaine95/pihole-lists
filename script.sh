#!/usr/bin/env bash
set -e

###
# Get blocklist urls from firebog
# Copy pihole urls to tmp file
# Sort tmp file into $U
###
get_urls(){
  echo "=============================="
  echo "Getting blocklist URLs to download"
  echo "=============================="
  mkdir -p tmp
  #curl -s https://v.firebog.net/hosts/lists.php?type=nocross -o tmp/urls.tmp
  curl -s https://v.firebog.net/hosts/lists.php?type=tick -o tmp/urls.tmp
  cat list_urls/pihole.urls >> tmp/urls.tmp
  U=$(sort -u tmp/urls.tmp)
}

###
# For each URL in $U
# Download list into single file
###
get_lists(){
  for u in $U; do
    echo "=============================="
    echo "Downloading $u"
    echo "=============================="
    wget $u -O- >> tmp/blocklist.raw
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
  echo "=============================="
  echo "Parse list to domains only"
  echo "=============================="
  
  < tmp/blocklist.raw awk -F '#' '{print $1}' | \
  awk -F '/' '{print $1}' | \
  awk '($1 !~ /^#/) { if (NF>1) {print $2} else {print $1}}' | \
  sed -nr -e 's/\.{2,}/./g' -e '/\./p' >  tmp/blocklist.domains
}

###
# Sort and extract unique domains
###
sort_masterlist(){
  echo "=============================="
  echo "Sorting and extracting unique domains"
  echo "=============================="
  sort -u tmp/blocklist.domains > tmp/blocklist
}

###
# Checkout dedicated branch for storing blocklist
# Overwrite old blocklist with new blocklist
# Add blocklist
# Amend previous commit with latest version
# rebase on master so blocklist is always one commit above master
# push to origin
###
save_list(){
  git checkout blocklist
  git reset --soft HEAD~1
  mv tmp/blocklist blocklist
  git add blocklist
  git commit -m "$(date +%d-%m-%Y_%H:%M -u) UTC"
  git rebase master
  git push --force
}

clean_tmp(){
  git clean -dfX
}

main(){
  get_urls
  get_lists
  parse_domains
  sort_masterlist
  save_list
}

main
