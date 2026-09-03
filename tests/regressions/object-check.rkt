#lang mystery-languages/fields

;; `object` as an expected value used to fail for every value, because
;; each language namespace had its own copy of the an-object struct type.
(TEST (object [a 1]) object object object)
(TEST 5 (not object) (not object) (not object))
