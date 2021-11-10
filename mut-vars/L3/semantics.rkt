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

(provide begin set!)

(provide (rename-out [app-by-copy-result #%app]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     #'(define fname
         (record-local-function
          (lambda (arg ...)
            (let ([answer ((thunk body ...))]) ;; the thunk allows internal definitions
              (values answer
                      (list arg ...))))))]))

(define-syntax (app-by-copy-result stx)
  (syntax-case stx ()
    [(_ f a ...)
     #`(if (is-local-function? f)
           (let-values ([(answer updated-vars)
                         (f a ...)])
             #,@(let ([a--- (syntax->list #'(a ...))])
                  (map (λ (v idx)
                         (if (identifier? v)
                             #`(set! #,v (list-ref updated-vars #,idx))
                             #'void))  ;; void because we don't want to repeat any effectful expressions!
                       a---
                       (range 0 (length a---))))
             answer)
           (f a ...))]))

