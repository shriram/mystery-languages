#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide + - * /
         < <= > >=
         = <>
         defvar
         ++
         if and or not
         deffun)

(provide object oget)

(define-syntax wrap-fn-term
  (syntax-rules ()
    [(_ fn)
     (if (symbol? 'fn)
         'fn
         fn)]))

(define-syntax (object stx)
  (syntax-parse stx
    [(_ (fn:expr rhs:expr) ...)
     #`(an-object
        (make-hash
         (list
          (cons (wrap-fn-term fn) rhs)
          ...)))]))

(define-syntax (oget stx)
  (syntax-parse stx
    [(_ o:expr fn:expr)
     #`(hash-ref (an-object-ht o)
                 (wrap-fn-term fn)
                 (λ ()
                   (error 'oget "field ~a not found" fn-wrapped)))]))
