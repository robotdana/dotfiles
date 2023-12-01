# echo "required less_support"
# Have less display colours
# from: https://wiki.archlinux.org/index.php/Color_output_in_console#man
export LESS_TERMCAP_mb=$C_BLUE         # begin bold
export LESS_TERMCAP_md=$C_GREEN        # begin blink
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$C_AQUA         # begin underline
export LESS_TERMCAP_me=$C_RESET        # reset bold/blink
export LESS_TERMCAP_se=$C_RESET        # reset reverse video
export LESS_TERMCAP_ue=$C_RESET        # reset underline
