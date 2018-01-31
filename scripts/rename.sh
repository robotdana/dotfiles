#!/bin/bash
# based on: https://gist.github.com/octocat/0831f3fbd83ac4d46451#gistcomment-2178506
# will use the .mailmap file to rewrite all names/emails

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

function rename () {
  local old_pair=$@
  local old_name=$(split_name "$old_pair")
  local old_email=$(split_email "$old_pair")

  local new_pair=$(git check-mailmap "$old_pair")
  local new_name=$(split_name "$new_pair")
  local new_email=$(split_email "$new_pair")

  echo "renaming '$old_name <$old_email>' to '$new_name <$new_email>'"

  git filter-branch --env-filter "
    if [ \"\$GIT_COMMITTER_NAME\" = \"${old_name}\" ] && [ \"\$GIT_COMMITTER_EMAIL\" = \"${old_email}\" ]
    then
        export GIT_COMMITTER_NAME=\"${new_name}\"
        export GIT_COMMITTER_EMAIL=\"${new_email}\"
    fi
    if [ \"\$GIT_AUTHOR_NAME\" = \"${old_name}\" ] && [ \"\$GIT_AUTHOR_EMAIL\" = \"${old_email}\" ]
    then
        export GIT_AUTHOR_NAME=\"${new_name}\"
        export GIT_AUTHOR_EMAIL=\"${new_email}\"
    fi
    " --force --tag-name-filter cat -- --branches --tags
}

incorrect_names | while read -r line; do
  rename $line
done
