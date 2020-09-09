#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide + - *
         < <= > >=
         and or not
         = <>
         defvar)

(provide [rename-out (int-div /)])

(define (int-div . ns)
  (let ([result (apply / ns)])
    (if (andmap integer? ns)
        (floor result)
        result)))
