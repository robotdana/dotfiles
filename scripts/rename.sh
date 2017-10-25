#!/bin/sh

# source:
# https://gist.github.com/octocat/0831f3fbd83ac4d46451#gistcomment-2178506

OLD_NAME=$1
CORRECT_NAME=$(git config user.name)
CORRECT_EMAIL=$(git config user.email)
shift 1
echo "re-writing history of '${OLD_NAME}' to '${CORRECT_NAME}' (${CORRECT_EMAIL})"
git filter-branch --env-filter "
  if [ \"\$GIT_COMMITTER_NAME\" = \"${OLD_NAME}\" ]
  then
      export GIT_COMMITTER_NAME=\"${CORRECT_NAME}\"
      export GIT_COMMITTER_EMAIL=\"${CORRECT_EMAIL}\"
  fi
  if [ \"\$GIT_AUTHOR_NAME\" = \"${OLD_NAME}\" ]
  then
      export GIT_AUTHOR_NAME=\"${CORRECT_NAME}\"
      export GIT_AUTHOR_EMAIL=\"${CORRECT_EMAIL}\"
  fi
  " $@ -f --tag-name-filter cat -- --branches --tags
