#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(define (inexact-value d)
  (if (number? d)
      (exact->inexact d)
      d))

(define-syntax-rule (my-#%app fun arg ...)
  (#%app (#%app inexact-value fun) (#%app inexact-value arg) ...))

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
