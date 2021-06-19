set nowrapscan
" Find a "set __coll_x" instance
let @a='/set.__coll_'
" delete the trailing characters and replace with backslash
let @b='$xxA \€ýa0'
" copy __coll_x into buf i
let @c='wve"iy0'

let @x='@a@b@c'

" search for __coll_x; first instance will be the "set __coll_x" line
let @d='/tion i0'
" delete append_to_collection and get_pins and add backslash
let @e='df{$xxA \€ýa0'
" find a line to modify and apply macro e, recurse
let @f='@kn0@e@f'

" end list with curly brace and bracket
let @g='o}]€ýa'
" apply g if no more appends
let @k=":if search('tion i') == 0exec 'norm @g'endif0"

let @h='@x@k@d@f'

norm @h
norm @h
norm @h
norm @h
norm @h

norm @h
norm @h
norm @h
norm @h
norm @h

x
