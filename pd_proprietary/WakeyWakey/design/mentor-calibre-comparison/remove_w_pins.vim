" prevent recursive macros from running forever
set nowrapscan

" macro a finds a cell with an extra w pin, eg: w_94_21#
let @a='/.subckt.*w_.*#
" macro x deletes the extra pin from the .subckt declaration
let @x='$diWx0'
" macro b copies the cell name into buffer i
let @b='W"iye'

" macro c finds an instance where the extra pin must be removed
let @c='/i$
" macro d deletes the extra pin
let @d='?\S\+\S
" macro e composes macro c and d and applies them recursively through the file
let @e='@c@d@e'

" macro f deletes the extra pins from one cell type
let @f='gg@a@x@b@e'

" apply f a sufficient number of times
norm @f
norm @f
norm @f
norm @f
norm @f

norm @f
norm @f
norm @f
norm @f
norm @f

x