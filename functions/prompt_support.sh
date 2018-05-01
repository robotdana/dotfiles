# source ./git_support.sh

function title() {
  printf "\\033]0;%s\\007" "${*:-Terminal}"
}
