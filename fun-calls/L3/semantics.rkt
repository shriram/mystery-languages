#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common racket/control)
(require [for-syntax racket])

(provide #%datum #%top)

(provide defvar
         if and or not)

(provide deffun)

(provide [rename-out [lazy-app #%app]])
(provide
 [rename-out
  [lazy-+ +]
  [lazy-- -]
  [lazy-* *]
  [lazy-/ /]
  [lazy-< <]
  [lazy-<= <=]
  [lazy-> >]
  [lazy->= >=]
  [lazy-= =]
  [lazy-<> <>]
  [lazy-++ ++]
  ])

(define (make-lazy op)
  (lambda args
    (apply op (map (lambda (thunk) (thunk)) args))))

(define lazy-+ (make-lazy +))
(define lazy-- (make-lazy -))
(define lazy-* (make-lazy *))
(define lazy-/ (make-lazy /))
(define lazy-< (make-lazy <))
(define lazy-<= (make-lazy <=))
(define lazy-> (make-lazy >))
(define lazy->= (make-lazy >=))
(define lazy-= (make-lazy =))
(define lazy-<> (make-lazy <>))
(define lazy-++ (make-lazy ++))

(define-syntax-rule (lazy-app f a ...)
  (f (lambda () a) ...))

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (f:id a:id ...) body:expr)
     #'(define f
         (let ([return-k #f])
           (lambda (a ...)
             (define (run)
               (let ([a (a)] ...)
                 body))
             (cond
               [return-k
               (return-k (run))]
               [else
               (let/cc k
                 (dynamic-wind
                   (lambda () (set! return-k k))
                   (lambda () (run))
                   (lambda () (set! return-k #f))))]))))]))
