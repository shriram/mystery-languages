#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%top #%app
         (rename-out [exact-#%datum #%datum]))

(define (better-inexact->exact x)
  (if (number? x)
      (string->number
        (string-append "#e" (number->string x)))
      x))

(define-syntax-rule (exact-#%datum . d)
  (better-inexact->exact 'd))

(provide + - * /
         < <= > >=
         = <>
         ++
         defvar)
