#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(define (process-numbers d)
  (if (number? d)
      (if (exact-integer? d)
          d
          (exact->inexact d))
      d))

(define-syntax-rule (my-#%app fun arg ...)
  (#%app (#%app process-numbers fun) (#%app process-numbers arg) ...))

(define (quotient-or-/ . ns)
  (if (and (pair? ns) (andmap exact-integer? ns))
      (foldl (lambda (n so-far)
               (quotient so-far n))
             (first ns)
             (rest ns))
      (apply / ns)))

(provide + - * (rename-out [quotient-or-/ /])
         < <= > >=
         = <>
         ++
         defvar
         #%module-begin
         #%top-interaction
         #%top
         (rename-out [my-#%app #%app])
         #%datum)
