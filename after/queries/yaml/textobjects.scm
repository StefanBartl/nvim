;; extends

; Indentation is the structure in YAML, so every mapping and sequence level is
; a level to climb out of.
(block_mapping) @block.outer
(block_sequence) @block.outer
(flow_mapping) @block.outer
(flow_sequence) @block.outer
