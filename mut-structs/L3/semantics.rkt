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

(provide [rename-out (deep-copy-app #%app)])

(define (deep-copy-obj o)
  (if (an-object? o)
      (an-object (make-hasheq
                  (hash-map (an-object-ht o)
                            (λ (k v)
                              (cons k (deep-copy-obj v))))))
      o))

(define-syntax (deep-copy-app e)
  (syntax-case e ()
    [(_ f a ...)
     #'(f (deep-copy-obj a) ...)]))
