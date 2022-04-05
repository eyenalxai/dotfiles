" Start page
Plug 'mhinz/vim-startify'

" Line numbers
Plug 'myusuf3/numbers.vim'

" Easy comments
Plug 'tpope/vim-commentary'

" Highlight colors
Plug 'lilydjwg/colorizer'

" Git
Plug 'airblade/vim-gitgutter'

" Syntax
Plug 'scrooloose/syntastic'

" Highlight brackers
Plug 'frazrepo/vim-rainbow'

" Deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

" Make tab key adequate
Plug 'ervandew/supertab'

