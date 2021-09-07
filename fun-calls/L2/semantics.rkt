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

(provide [rename-out (goto-app #%app)])

(define-syntax (goto-app e)
  (syntax-case e ()
    [(_ f a ...)
     #'(if (unbox top-level-continuation)
           (#%app f a ...)
           (let ([v (let/cc k
                      (set-box! top-level-continuation k)
                      (#%app f a ...))])
             (set-box! top-level-continuation #f)
             v))]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     #'(define (fname arg ...)
         ((unbox top-level-continuation)
          (begin body ...)))]))

(define top-level-continuation (box #f))

(define-for-syntax locally-defined-functions (box '()))
