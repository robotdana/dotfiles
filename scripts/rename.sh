#!/bin/bash
# based on: https://gist.github.com/octocat/0831f3fbd83ac4d46451#gistcomment-2178506
# Uses the .mailmap file to correct all names/emails
# Then removes the unnecessary .mailmap file

function correct_names () {
  ( git shortlog -sen ; git shortlog -secn ) | cut -f2 | sort | uniq
}

function all_names () {
  ( git log --format="%an <%ae>" ; git log --format="%cn <%ce>" ) | sort | uniq
}

function incorrect_names () {
  comm -23 <( all_names ) <( correct_names )
}

function split_name () {
  local name=${@% <*}

  echo -e "$name"
}

function split_email () {
  local email=${@#* <}
  local email=${email%>}

  echo -e "$email"
}

function env_filter () {
  incorrect_names | while read -r line; do
    local old_pair=$line
    local old_name=$(split_name "$old_pair")
    local old_email=$(split_email "$old_pair")

    local new_pair=$(git check-mailmap "$old_pair")
    local new_name=$(split_name "$new_pair")
    local new_email=$(split_email "$new_pair")

    local author_types="COMMITTER AUTHOR"

    for author in ${author_types}; do
      echo "if [ \"\$GIT_${author}_NAME\" = '${old_name}' ]\
&& [ \"\$GIT_${author}_EMAIL\" = '${old_email}' ]
then
  export GIT_${author}_NAME='${new_name}'
  export GIT_${author}_EMAIL='${new_email}'
fi"
    done
  done
}

echo -e "\033[1;90m git filter-branch --force \\
--env-filter \"$(env_filter)\" \\
--index-filter 'git rm --cached --ignore-unmatch \".mailmap\"' \\
--prune-empty --tag-name-filter cat -- --branches --tags \033[0m " >/dev/tty

git filter-branch --force \
--env-filter "$(env_filter)" \
--index-filter 'git rm --cached --ignore-unmatch ".mailmap"' \
--prune-empty --tag-name-filter cat -- --branches --tags
