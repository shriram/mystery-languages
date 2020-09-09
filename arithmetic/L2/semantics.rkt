#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide [rename-out (plus  +)
                     (minus -)
                     (mult  *)
                     (div   /)]
         < <= > >=
         and or not
         = <>
         defvar)

(define (arith-maker op)
  (λ ns
    (apply op
           (map (λ (n)
                  (if (exact? n) (exact->inexact n) n))
                ns))))

(define plus  (arith-maker +))
(define minus (arith-maker -))
(define mult  (arith-maker *))
(define div   (arith-maker /))
