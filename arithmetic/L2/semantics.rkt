#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%top #%app
         [rename-out (float-datum #%datum)])

(provide [rename-out (plus  +)
                     (minus -)
                     (mult  *)
                     (div   /)]
         < <= > >=
         = <>
         ++
         defvar)

(define (arith-maker op)
  (λ ns
    (apply op
           (map (λ (n)
                  (if (exact? n) (exact->inexact n) n))
                ns))))

(define-syntax-rule (float-datum . n)
  (if (number? (#%datum . n))
      ((arith-maker (lambda (x) x)) (#%datum . n))
      (#%datum . n)))

(define plus  (arith-maker +))
(define minus (arith-maker -))
(define mult  (arith-maker *))
(define div   (arith-maker /))
