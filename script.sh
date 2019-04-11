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
  rm -rf tmp mirror
  mkdir -p tmp mirror
  #curl -s https://v.firebog.net/hosts/lists.php?type=nocross -o tmp/urls.tmp
  curl -s https://v.firebog.net/hosts/lists.php?type=tick -o tmp/urls.tmp
  cat list_urls/pihole.urls >> tmp/urls.tmp
  U=$(sort -u tmp/urls.tmp)
}

###
# For each URL in $U
# Download list and save into tmp/
###
get_lists(){
  i=0
  for u in $U; do
    echo "=============================="
    echo "Downloading $u"
    echo "=============================="
    wget "$u" -O- > tmp/list.${i}
    i=$((i+1))
  done
}

###
# For each blocklist in `tmp/`
# generate github raw url pointing to the list in `mirror/`
# and add the list url to a plaintext file
# for copy-paste add to pihole
###
compile_list(){
  # https://raw.githubusercontent.com/$USER/$REPO/$BRANCH/$DIR/$FILE
  user=$(git remote get-url --all origin | cut -f 2 -d":" | cut -f 1 -d"." | cut -f 1 -d"/")
  repo=$(git remote get-url --all origin | cut -f 2 -d":" | cut -f 1 -d"." | cut -f 2 -d"/")
  for u in $(find tmp/list.* | cut -f 2 -d"/" | sort -t . -k 2 -g); do
    echo "https://raw.githubusercontent.com/${user}/${repo}/master/mirror/${u}" >> tmp/adlists.list
  done
}

###
# make sure we're on master
# move tmp/adlists.list to root of project
# move all lists.i to mirror dir
# add relevent files
# commit to master
# push to origin
###
save_list(){
  msg="$(date +%d-%m-%Y_%H:%M -u) UTC"
  git checkout master
  mv tmp/adlists.list adlists.list
  mv tmp/list.* mirror/
  git add adlists.list mirror/
  git commit -m "${msg}"
  git push
}

clean_tmp(){
  git clean -dfX
}

main(){
  get_urls
  get_lists
  compile_list
  save_list
  clean_tmp
}

main
