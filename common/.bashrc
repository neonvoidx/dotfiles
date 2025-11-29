# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Path to the bash it configuration
BASH_IT="/home/neonvoid/.bash_it"

# location "$BASH_IT"/themes/
export BASH_IT_THEME='purity'
THEME_CHECK_SUDO='true'
SCM_CHECK=true
BASH_IT_COMMAND_DURATION=true
COMMAND_DURATION_MIN_SECONDS=1
SHORT_TERM_LINE=true
BASH_IT_AUTOMATIC_RELOAD_AFTER_CONFIG_CHANGE=1

source "${BASH_IT?}/bash_it.sh"

eval "$(zoxide init --cmd cd bash)"
