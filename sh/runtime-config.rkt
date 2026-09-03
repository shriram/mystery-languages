#lang racket/base
;; Installed by the `configure-runtime` submodule of every
;; `#lang mystery-languages/sh-<family>` module, so that a REPL (DrRacket's
;; interactions window, `racket -i`) reads Shrubbery rather than
;; S-expressions.  The interaction reader is the one Rhombus uses.

(require shrubbery/parse)

(current-read-interaction
 (lambda (src in)
   (when (terminal-port? in)
     (flush-output (current-output-port)))
   (define-values (line col pos) (port-next-location in))
   (define stx
     (parse-all in #:source src #:mode 'interactive #:start-column (or col 0)))
   ;; `(multi)` means only whitespace was read: treat as end of input
   (if (and (syntax? stx)
            (let ([v (syntax-e stx)])
              (and (pair? v)
                   (eq? 'multi (syntax-e (car v)))
                   (null? (if (syntax? (cdr v)) (syntax-e (cdr v)) (cdr v))))))
       eof
       stx)))
