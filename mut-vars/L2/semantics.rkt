#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction)

(provide #%datum #%top
         + - * /
         < <= > >=
         = <>
         ++
         not)
(provide (rename-out
          [my-begin begin]
          [my-if if]
          [my-and and]
          [my-or or]
          [my-app #%app]
          [my-set! set!]))
(provide defvar
         deffun)

(define-syntax-rule (my-begin any ...) (begin (observe any) ...))
(define-syntax-rule (my-if any ...) (if (observe any) ...))
(define-syntax-rule (my-and any ...) (and (observe any) ...))
(define-syntax-rule (my-or any ...) (or (observe any) ...))

(define-syntax-rule (my-app fun arg ...)
  (let ([f (observe fun)])
    (if (ud-proc? f)
        (f (as-box arg) ...)
        (f (observe arg) ...))))

(define-syntax (as-box stx)
  (syntax-parse stx
    [(_ x:id)
     #'x]
    [(_ e)
     #'(box e)]))

(define-syntax (my-set! stx)
  (syntax-parse stx
    [(_ var:id rhs:expr)
     #'(set-box! var (observe rhs))]))

(define-syntax (defvar stx)
  (syntax-parse stx
    [(_ var:id rhs:expr)
     #'(define var (box (observe rhs)))]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fun:id arg:id ...) . body)
     #'(defvar fun
         (ud-proc
           (lambda (arg ...)
             (observe (let () . body)))))]))
