#lang racket

(provide show record-local-function is-local-function?)

(define (show V . m)
  (unless (empty? m)
    (display m)
    (newline))
  (display V)
  (newline)
  V)

(define-values (record-local-function is-local-function?)
  (let ([locally-defined-functions (box '())])
    (values (lambda (fun-val)
              (set-box! locally-defined-functions (cons fun-val (unbox locally-defined-functions)))
              fun-val)
            (lambda (fun-val)
              (memq fun-val (unbox locally-defined-functions))))))

