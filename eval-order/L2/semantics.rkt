#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(require [prefix-in lazy: lazy])

(provide [rename-out (lazy:#%module-begin #%module-begin) (lazy:#%top-interaction #%top-interaction)
                     (lazy:#%datum #%datum) (lazy:#%top #%top) (lazy:#%app #%app)

                     (lazy:+ +) (lazy:- -) (lazy:* *) (lazy:/ /)
                     (lazy:< <) (lazy:<= <=) (lazy:> >) (lazy:>= >=)
                     (lazy:= =);
                     (lazy:string-append ++)
                     (lazy:if if) (lazy:and and) (lazy:or or) (lazy:not not)])

(provide <> defvar deffun)

(provide [rename-out (lazy:begin begin)])
(provide set!)

(lazy:define (<> a b)
             (lazy:not (lazy:= a b)))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     #'(lazy:define (fname arg ...) body ...)]))

(define-syntax (defvar stx)
  (syntax-parse stx
    [(_ var:id rhs:expr)
     #'(lazy:define var rhs)]))

(define-syntax (set! stx)
  (syntax-parse stx
    [(_ var:id val:expr)
     #'(lazy:set! var val)]))
