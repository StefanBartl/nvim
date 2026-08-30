;; extends

; Python has no `block` node; its shipped `@block.outer` covers suites via
; other captures. These are the data structures.
(dictionary) @block.outer
(list) @block.outer
(set) @block.outer
(tuple) @block.outer
