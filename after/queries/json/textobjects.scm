;; extends

; JSON's shipped textobjects query is one line, for comments -- there are no
; blocks in JSON at all, so without this the motion does nothing here.
(object) @block.outer
(array) @block.outer
