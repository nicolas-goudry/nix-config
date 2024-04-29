# Original: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/common-aliases

# ls aliases for eza
alias l='ls -1'
alias ll='ls -l'
alias la='ls -la'
alias lsa='ls -la'
alias ldot='ls -ld .*'

# Quick access to the .zshrc file
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

# Grep
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

# Command line head / tail shortcuts
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g P="2>&1| pygmentize -l pytb"
alias t='tail -f'

# Find
(( $+commands[fd] )) || alias fd='find . -type d -name'
alias ff='find . -type f -name'

# Misc
alias h='history'
alias p='ps -f'
alias sortnr='sort -n -r'

# Confirm
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
