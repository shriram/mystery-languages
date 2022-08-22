#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils)
(require [for-syntax racket])

(provide <> ++ begin defvar deffun)

(provide object oget oset an-object? an-object an-object-ht)

(provide set!)

;; ---------- basic

(define (<> a b) (not (= a b)))

(define ++ string-append)

(define-syntax begin
  (syntax-rules ()
    [(_) (void)]
    [(_ prepare ... result)
     (let* ([_ prepare] ...)
       result)]))

(define-syntax (defvar stx)
  (syntax-parse stx
    [(_ var:id rhs:expr)
     #'(define var rhs)]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     #'(define (fname arg ...) body ...)]))

;; ---------- objects

(struct an-object (ht))

(define-syntax (object stx)
  (syntax-parse stx
    [(_ (fn:id rhs:expr) ...)
     #'(an-object (make-hasheq (list (cons 'fn rhs) ...)))]))

(define-syntax (oget stx)
  (syntax-parse stx
    [(_ o:expr fn:id)
     #'(hash-ref (an-object-ht o)
                 'fn
                 (λ ()
                   (error 'oget "field ~a not found" 'fn)))]))

(define-syntax (oset stx)
  (syntax-parse stx
    [(_ o:expr fn:id v:expr)
     #'(hash-set! (an-object-ht o)
                  'fn
                  v)]))
