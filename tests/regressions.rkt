#lang racket
;; Regression tests: every program under tests/regressions/ must run
;; without any test failure or error, in whichever syntax it is written.
;; Each file says in a comment which bug it guards against.

(require racket/runtime-path compiler/find-exe)

(define-runtime-path dir "regressions")

(define (run-file path)
  ;; stderr merged into stdout at the OS level, so error lines land where
  ;; they were printed relative to the L<n>: lines (two pipes would
  ;; interleave nondeterministically)
  (define-values (proc out in err)
    (subprocess #f #f 'stdout (find-exe) (path->string path)))
  (close-output-port in)
  (define output (port->string out))
  (close-input-port out)
  (subprocess-wait proc)
  (values (zero? (subprocess-status proc)) output))

(define failures 0)
(for ([p (sort (directory-list dir #:build? #t) path<?)]
      #:when (or (path-has-extension? p #".rkt") (path-has-extension? p #".rhm")))
  (define-values (ok? output) (run-file p))
  (cond
    [(and ok? (not (regexp-match? #rx"FAILURE|ERROR" output)))
     (printf "ok   ~a~n" p)]
    [else
     (set! failures (add1 failures))
     (eprintf "FAIL ~a~n~a~n" p output)]))

(cond
  [(zero? failures) (printf "all regression tests passed~n")]
  [else (eprintf "~a regression file(s) failed~n" failures) (exit 1)])
