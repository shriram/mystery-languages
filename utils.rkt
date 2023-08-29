#lang racket

(provide show)

(define (show V . m)
  (unless (empty? m)
    (display m)
    (newline))
  (display V)
  (newline)
  V)

;; ----------

(provide box-unbox)

(define (box-unbox e)
  (box (unbox e)))

;; ---------- observable

(provide observe gen:observable)
(require racket/generic)

(define-generics observable
  (observe observable)
  #:defaults ([promise?
               (define (observe p)
                (force p))]
              [box?
               (define (observe b)
                (unbox b))]
              [any/c
               (define (observe v) v)]))

;; ---------- user-defined-function

(provide ud-proc ud-proc?)

(struct ud-proc (base)
    #:property prop:procedure
               (struct-field-index base))
