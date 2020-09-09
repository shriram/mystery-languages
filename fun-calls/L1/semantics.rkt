#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top)

(provide + - * /
         < <= > >=
         = <>
         defvar
         ++
         if and or not)

(provide deffun)

(provide #%app)

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     #'(define (fname arg ...) body ...)]))
