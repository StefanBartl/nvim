;; extends

; Extends the shipped `@block.outer`, which in Lua is `(_ (block)) @block.outer`
; -- function bodies, if, for, while. A table constructor is not a `block`, so
; a deeply nested configuration table, which is exactly where "jump to the head
; of the enclosing structure" earns its keep, was out of reach.
;
; Deliberately the *same* capture rather than a new one: "the thing I am inside"
; is one idea, and one capture keeps the motion a single argument. The trade is
; that `@block.outer` here means slightly more than upstream documents -- if a
; later binding needs "executable block" strictly, split this into its own
; capture and pass both.
(table_constructor) @block.outer
