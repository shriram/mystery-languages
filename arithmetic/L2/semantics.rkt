#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(define (inexact-value d)
  (if (number? d)
      (exact->inexact d)
      d))

(define (make-my +)
  (lambda args
    (if (andmap exact-integer? args)
        (apply + args)
        (apply + (map inexact-value args)))))
(define my+ (make-my +))
(define my- (make-my -))
(define my* (make-my *))

;; division is always in float point
(define (my/ . args)
  (apply / (map inexact-value args)))

(provide (rename-out [my+ +])
         (rename-out [my- -])
         (rename-out [my* *])
         (rename-out [my/ /])
         < <= > >=
         = <>
         ++
         defvar
         #%module-begin
         #%top-interaction
         #%top
         #%app
         #%datum)
