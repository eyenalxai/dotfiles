" Install plugins
call plug#begin('~/.config/nvim/plugged')
source ~/.config/nvim/plugins.vim
call plug#end()


" Load configs for plugins
source ~/.config/nvim/plugins-config.vim

" Use terminal colors
set notermguicolors

" Better case-sensitivity when searching
set ignorecase
set smartcase

" Begin search from top of file when nothing is found anymore
set wrapscan

" Wrap
set wrap

" Filetypes
filetype indent on
filetype on
filetype plugin on
filetype plugin indent on

" Remember more commands and search history
set history=1000

" No backup or swap file, live dangerously
set nobackup
set noswapfile

" Preserve horizontal whitespace when wrapping
set breakindent

" Keep three lines between the cursor and the edge of the screen
set scrolloff=5

" Undo settings
set undodir=~/.config/nvim/undodir
set undofile
set undolevels=10000
set undoreload=100000

" Keep command line clean
set noshowmode
set noshowcmd

" Always slow statusline
set laststatus=2

" Highlight search and search while typing
set hlsearch
set incsearch
set cpoptions+=x

" Allow copying of more than 50 lines to other applications
set viminfo='20,<1000

" Disable terminal ctrl-z
nnoremap <C-z> <Esc>

" Map paste, yank and delete to named register so the content will not be overwritten
nnoremap x "_x
vnoremap x "_x

" System wide clipboard
set clipboard=unnamedplus

" Move a line of text using ALT+[jk]
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

" Spaces & Tabs
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing 
set shiftwidth=4    " number of spaces to use for autoindent
set expandtab       " tabs are space
set autoindent
set copyindent      " copy indent from the previous line

" Remove all trailing whitespace by pressing C-S
nnoremap <C-S> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>

" Highlight characters past column 80
augroup vimrc_autocmds
    autocmd!
    autocmd FileType ruby,python,javascript,c,cpp highlight Excess ctermbg=DarkGrey guibg=#c12a0f
    autocmd FileType ruby,python,javascript,c,cpp match Excess /\%120v.*/
    autocmd FileType ruby,python,javascript,c,cpp set nowrap
augroup END

" Clear highlighting on escape in normal mode
nnoremap <esc> :noh<return><esc>
nnoremap <esc>^[ <esc>^[
