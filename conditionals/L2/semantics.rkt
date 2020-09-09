#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide + - * /
         < <= > >=
         = <>
         defvar)

(provide and or not)

(provide [rename-out (lispy-if if)])

(define-syntax lispy-if
  (syntax-rules ()
    [(_ C T E)
     (if C T E)]))
