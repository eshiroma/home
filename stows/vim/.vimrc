" Check for a corp-specific config.
" Source first to allow it to source from other default base configs.
" while prioritizing my minimal specific configs here.
if filereadable(expand("~/.vimrc_corp"))
"  source ~/.vimrc_corp
endif

set number
colorscheme desert
syntax on
filetype plugin on

set tabstop=2 expandtab

