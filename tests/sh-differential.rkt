#lang racket
;; Differential test of the shrubbery front-end against the parenthetical
;; syntax.  For each pair corpus/<name>.rkt and corpus/<name>.rhm:
;;
;;  1. translation: the datums the shrubbery translator produces must be
;;     `equal?` to what Racket's reader reads from the .rkt file.  Same
;;     datums into the same evaluators is the whole argument that the
;;     semantics are unchanged.
;;  2. output: running both files under `racket` must print the same
;;     per-language results and the same test failures (the echoed
;;     program text and failure locations are excluded, since those
;;     differ by design).
;;
;; The corpus lives in private/corpus, which is excluded from version
;; control: each pair states how the variants differ, which is what the
;; assignments ask students to discover.  A public tests/corpus is used
;; too if one exists.

(require shrubbery/parse
         mystery-languages/sh/translate
         racket/runtime-path
         compiler/find-exe)

(define-runtime-path corpus-dir "corpus")
(define-runtime-path private-dir "../private/corpus")

(define (family-of rkt)
  (define line (call-with-input-file rkt read-line))
  (match line
    [(regexp #rx"^#lang mystery-languages/([a-z-]+)" (list _ f)) (string->symbol f)]
    [_ (error 'sh-differential "no #lang mystery-languages/<family> line in ~a" rkt)]))

(define (racket-forms rkt)
  (call-with-input-file rkt
    (lambda (in)
      (read-line in)
      (port-count-lines! in)
      (let loop ()
        (define d (read in))
        (if (eof-object? d) '() (cons d (loop)))))))

(define (shrubbery-forms rhm family)
  (call-with-input-file rhm
    (lambda (in)
      (read-line in)
      (port-count-lines! in)
      (for/list ([g (cdr (syntax->list (parse-all in #:source rhm)))])
        (define-values (kind datum expecteds e-group) (translate-top g family))
        (if (eq? kind 'test)
            `(TEST ,datum ,@(map syntax->datum expecteds))
            datum)))))

;; Lines that carry results: per-language answers and rackunit failure
;; details other than the location.
(define (result-lines output)
  (for/list ([l (string-split output "\n")]
             #:when (regexp-match? #rx"^(L[0-9]+: |FAILURE|name:|actual:|expected:|message:|params:)" l))
    l))

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
(define (report! fmt . args)
  (set! failures (add1 failures))
  (apply eprintf fmt args)
  (newline (current-error-port)))

(define (check-pair rkt rhm)
  (define family (family-of rkt))
  (define expected (racket-forms rkt))
  (define actual
    (with-handlers ([exn:fail? (lambda (e)
                                 (report! "~a: translation raised: ~a" rhm (exn-message e))
                                 #f)])
      (shrubbery-forms rhm family)))
  (when actual
    (cond
      [(equal? expected actual) (printf "ok   translation  ~a~n" rhm)]
      [else
       (define n (for/first ([e expected] [a actual] [i (in-naturals)] #:unless (equal? e a)) i))
       (cond
         [n (report! "~a: form ~a differs~n  racket:    ~s~n  shrubbery: ~s" rhm n (list-ref expected n) (list-ref actual n))]
         [else (report! "~a: ~a forms vs ~a forms" rhm (length expected) (length actual))])])
    (define-values (ok-rkt? raw-rkt) (run-file rkt))
    (define-values (ok-rhm? raw-rhm) (run-file rhm))
    (define out-rkt (result-lines raw-rkt))
    (define out-rhm (result-lines raw-rhm))
    (cond
      [(equal? out-rkt out-rhm) (printf "ok   output       ~a~n" rhm)]
      [else
       (report! "~a: outputs differ~n--- racket~n~a~n--- shrubbery~n~a" rhm
                (string-join out-rkt "\n") (string-join out-rhm "\n"))])))

(define (check-dir dir)
  (for ([rkt (sort (for/list ([p (directory-list dir #:build? #t)]
                              #:when (path-has-extension? p #".rkt"))
                     p)
                   path<?)])
    (define rhm (path-replace-extension rkt #".rhm"))
    (if (file-exists? rhm)
        (check-pair rkt rhm)
        (report! "~a: no matching .rhm" rkt))))

(define dirs (filter directory-exists? (list corpus-dir private-dir)))
(when (null? dirs)
  (eprintf "no corpus: neither ~a nor ~a exists~n" corpus-dir private-dir)
  (exit 1))
(for ([dir dirs])
  (printf "--- ~a~n" dir)
  (check-dir dir))

(cond
  [(zero? failures) (printf "all differential checks passed~n")]
  [else (eprintf "~a failure(s)~n" failures) (exit 1)])
