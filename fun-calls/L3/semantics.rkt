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

(provide [rename-out [cobol-app #%app]])

(struct deffun-fun (fun))

(define-syntax-rule (cobol-app f a ...)
  (let ([fv f])
    (if (deffun-fun? fv)
        ((deffun-fun-fun fv) (lambda () a) ...)
        (fv a ...))))

(define-syntax-rule (deffun (f a ...) body ...)
  (define f
    (let ([return-k #f])
      (deffun-fun
        (lambda (a ...)
          (define (run-body)
            (let ([a (a)] ...)
              body ...))
          (cond
            [return-k
             (return-k (run-body))]
            [else
             (let ([v (let/cc k
                        (set! return-k k)
                        (run-body))])
               (set! return-k #f)
               v)]))))))
