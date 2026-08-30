;; extends

; `{ … }` of a struct literal is not a `block`, and neither are array or tuple
; expressions.
(struct_expression) @block.outer
(array_expression) @block.outer
(tuple_expression) @block.outer
