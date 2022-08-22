#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

;; We don't use `inexact->exact` because, for example,
;; `(inexact->exact 0.1)` is not `1/10` but `3602879701896397/36028797018963968`.

(define (my-inexact->exact n)
  (or (string->number
        (number->string n)
        ;; radix (default): 10-based numeral
        10
        ;; convert-mode (default): #f if the string is not a valid number representation
        'number-or-false
        ;; decimal-mode: required that all decimals are read as exact numbers
        'decimal-as-exact)
      ;; If the conversion fails, returns the number as it is.
      ;; This may happen when `n` is, for example, `+inf.0`
      n))

(define (exact-value d)
  (if (number? d)
      (my-inexact->exact d)
      d))

(define-syntax-rule (my-#%app fun arg ...)
  (#%app (#%app exact-value fun) (#%app exact-value arg) ...))

(provide + - * /
         < <= > >=
         = <>
         ++
         defvar
         #%module-begin
         #%top-interaction
         #%top
         (rename-out [my-#%app #%app])
         #%datum)
