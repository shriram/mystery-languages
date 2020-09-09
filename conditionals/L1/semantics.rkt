#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide + - * /
         < <= > >=
         = <>
         defvar)

(provide [rename-out (strict-if if) (strict-and and) (strict-or or) (strict-not not)])

(define-syntax strict-if
  (syntax-rules ()
    [(_ C T E)
     (let ([C-val C])
       (if (boolean? C-val)
           (if C-val T E)
           (error 'if "condition must be a boolean: ~a" C-val)))]))

(define-syntax strict-and
  (syntax-rules ()
    [(_) #true]
    [(_ e0 e1 ...)
     (let ([e0-val e0])
       (if (boolean? e0-val)
           (if e0-val
               (strict-and e1 ...)
               #false)
           (error 'and "condition must be a boolean: ~a" e0-val)))]))

(define-syntax strict-or
  (syntax-rules ()
    [(_) #false]
    [(_ e0 e1 ...)
     (let ([e0-val e0])
       (if (boolean? e0-val)
           (if e0-val
               #true
               (tf-or e1 ...))
           (error 'or "condition must be a boolean: ~a" e0-val)))]))

(define (strict-not v)
  (if (boolean? v)
      (not v)
      (error 'not "argument must be a boolean: ~a" v)))
