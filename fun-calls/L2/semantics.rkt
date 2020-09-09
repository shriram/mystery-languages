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
     (if (member (syntax->datum #'f) (unbox locally-defined-functions))
         #'(let ([v (unbox top-level-continuation)])
             (if v
                 (v (f a ...))
                 (f a ...)))  ;; THIS DOESN'T LOOK QUITE RIGHT!
         #'(if (unbox top-level-continuation)
               (f a ...)
               (let ([v (let/cc k
                          (set-box! top-level-continuation k)
                          (f a ...))])
                 (set-box! top-level-continuation #f) ;; restore top-level!
                 v)))]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     (begin
       (set-box! locally-defined-functions
                 (cons (syntax->datum #'fname) (unbox locally-defined-functions)))
       #'(define (fname arg ...) body ...))]))

(define top-level-continuation (box #f))

(define-for-syntax locally-defined-functions (box '()))
