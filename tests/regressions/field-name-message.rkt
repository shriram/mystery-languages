#lang mystery-languages/fields

;; L2 rejects a computed field name that is not a string.  The message
;; used to quote the expression; it is the value that was rejected.
(defvar o (object [a 1]))
(oget o (+ 1 1))
(object [(* 2 3) "six"])
