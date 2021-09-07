#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(define (better-inexact->exact x)
  (if (number? x)
      (string->number
        (string-append "#e" (number->string x)))
      x))

(provide [rename-out (plus  +)
                     (minus -)
                     (mult  *)]
         < <= > >=
         and or not
         = <>
         defvar)

(provide [rename-out (int-div /)])

(define (int-div . ns)
  (let ([result (apply (arith-maker /) ns)])
    (if (andmap (and/c integer? exact?) ns)
        (floor result)
        result)))

(define (arith-maker op)
  (λ ns
    (apply op
           (map (λ (n)
                  (if (inexact? n) (better-inexact->exact n) n))
                ns))))

(define plus  (arith-maker +))
(define minus (arith-maker -))
(define mult  (arith-maker *))
