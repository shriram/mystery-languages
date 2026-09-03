#lang racket
;; Regression tests: every program under tests/regressions/ must run
;; without any test failure or error, in whichever syntax it is written.
;; Each file says in a comment which bug it guards against.  If a file
;; <name>.expect exists, every line of it must also appear in the output
;; of <name>.rkt and of <name>.rhm; this is for bugs in what gets
;; printed, such as error messages.  When the two syntaxes legitimately
;; print differently, <name>.rkt.expect and <name>.rhm.expect take
;; precedence for their own file.

(require racket/runtime-path compiler/find-exe)

(define-runtime-path dir "regressions")
(define-runtime-path private-dir "../private/regressions")   ; optional, not in version control

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
(for* ([d (filter directory-exists? (list dir private-dir))]
       [p (sort (directory-list d #:build? #t) path<?)]
       #:when (or (path-has-extension? p #".rkt") (path-has-extension? p #".rhm")))
  (define-values (ok? output) (run-file p))
  (define expect-file
    (let ([own (path-add-extension p #".expect")])   ; <name>.rhm.expect
      (if (file-exists? own) own (path-replace-extension p #".expect"))))
  (define missing
    (if (file-exists? expect-file)
        (for/list ([line (file->lines expect-file)]
                   #:unless (string-contains? output line))
          line)
        '()))
  (cond
    [(and ok? (not (regexp-match? #rx"FAILURE|ERROR" output)) (null? missing))
     (printf "ok   ~a~n" p)]
    [else
     (set! failures (add1 failures))
     (eprintf "FAIL ~a~n" p)
     (for ([line missing]) (eprintf "  expected line not in output: ~a~n" line))
     (eprintf "~a~n" output)]))

(cond
  [(zero? failures) (printf "all regression tests passed~n")]
  [else (eprintf "~a regression file(s) failed~n" failures) (exit 1)])
