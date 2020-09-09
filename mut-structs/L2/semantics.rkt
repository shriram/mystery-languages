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
         if and or not
         deffun)

(provide object oget oset)

(provide [rename-out (shallow-copy-app #%app)])

(define-syntax (shallow-copy-app e)
  (syntax-case e ()
    [(_ f a ...)
     #'(f (if (an-object? a)
              (an-object (hash-copy (an-object-ht a)))
              a)
          ...)]))
