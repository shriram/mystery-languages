#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide + - * /
         < <= > >=
         = <>
         defvar)

(provide [rename-out (tf-if if) (tf-and and) (tf-or or) (tf-not not)])

(define (truthy? V) (not (falsy? V)))
(define (falsy? V)  (member V (list #false 0 "" "0")))

(define-syntax tf-if
  (syntax-rules ()
    [(_ C T E)
     (if (truthy? C) T E)]))

(define-syntax tf-and
  (syntax-rules ()
    [(_) #true]
    [(_ e0) (truthy? e0)]
    [(_ e0 e1 ...)
     (if (truthy? e0)
         (tf-and e1 ...)
         #false)]))

(define-syntax tf-or
  (syntax-rules ()
    [(_) #false]
    [(_ e0 e1 ...)
     (if (truthy? e0)
         #true
         (tf-or e1 ...))]))

(define (tf-not v)
  (if (truthy? v) #false #true))
