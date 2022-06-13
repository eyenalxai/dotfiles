" How to disable random quotes header?
let g:startify_custom_header = []


" If you see numbers where they don't belong like in the help menus or other
" vim plugins be sure to add your plugins to the excludes list like so.
let g:numbers_exclude = ['unite', 'tagbar', 'startify', 'gundo', 'vimshell', 'w3m', 'nerdtree']

" For terminals that are capable of displaying true colors,
" the plugin will also use true colors, if the 'termguicolors' option is set.
set termguicolors

" To keep your Vim snappy,
" vim-gitgutter will suppress the signs when a file has more than 500 changes.
" As soon as the number of changes falls below the limit vim-gitgutter will show the signs again.
" You can configure the threshold with:
let g:gitgutter_max_signs = 500

" To turn on line number highlighting by default.
let g:gitgutter_highlight_linenrs = 1

" When you make a change to a file tracked by git,
" the diff markers should appear automatically.
" The delay is governed by vim's updatetime option;
" the default value is 4000, i.e. 4 seconds,
" but I suggest reducing it to around 100ms (add set updatetime=100 to your vimrc).
set updatetime=100

" Fly Mode will always force closed-pair jumping instead of inserting. only for ")", "}", "]"
" If jumps in mistake, could use AutoPairsBackInsert(Default Key: <M-b>) to jump back and insert closed pair.
" The most situation maybe want to insert single closed pair in the string, eg ")"
let g:AutoPairsFlyMode = 1

" Enable Supertab
let g:SuperTabDefaultCompletionType = "<c-n>"
