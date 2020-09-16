#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common racket/control)
(require [for-syntax racket])

(provide #%datum #%top)

(provide + - * /
         < <= > >=
         = <>
         defvar
         ++
         if and or not)

(provide deffun)

(provide [rename-out (cobol-app #%app)])

(define return-frames (box empty))

(define-syntax (wrap-module-begin e)
  (syntax-case e ()
    [(_ d-or-e ...)
     #'((reset-top-level d-or-e) ...)]))

(define-syntax (reset-top-level e)
  (syntax-case e ()
    [(deffun H B) e]
    [(defvar V B)
     #'(defvar V (reset-top-level e))]
    [b
     #'(begin (set! return-frames (box empty))
              b)]))

(define-syntax (cobol-app e)
  (syntax-case e ()
    [(_ f a ...)
     (with-syntax ([base-name (syntax->datum #'f)])
       (if (member (syntax->datum #'f) (unbox locally-defined-functions))
           #'(let ([return-point
                    (assoc 'base-name (unbox return-frames))])
               (if return-point
                   ((second return-point) (f a ...))
                   (begin0
                       (let/cc k
                         (set-box! return-frames
                                   (cons (list 'base-name k)
                                         (unbox return-frames)))
                         (f a ...))
                     (remove-frame 'base-name))))
           #'(f a ...)))]))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     (with-syntax ([base-name (syntax->datum #'fname)])
       (set-box! locally-defined-functions
                 (cons (syntax->datum #'fname) (unbox locally-defined-functions)))
       #'(define (fname arg ...) body ...))]))

(define (remove-frame fun-name)
  (set-box! return-frames
            (remove fun-name
                    (unbox return-frames)
                    (λ (n p)
                      (equal? n (first p))))))

(define-for-syntax locally-defined-functions (box '()))
