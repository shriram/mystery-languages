#lang mystery-languages/fields

;; Looking up a missing field in L2 and L3 used to report
;; "fn-wrapped: undefined" instead of naming the field.
(defvar o (object [a 1]))
(oget o zz)
(TEST (oget o zz) failure failure failure)
