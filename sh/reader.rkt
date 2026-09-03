#lang racket/base
;; Module language for the sh-<family>/lang/reader.rkt files.  Such a
;; file is `#lang s-exp mystery-languages/sh/reader` followed by the
;; family name; this expands to the syntax/module-reader definition of
;; a reader that parses Shrubbery and runs the family's submodule of
;; sh/langs.rkt.

(require (for-syntax racket/base)
         (prefix-in mr: syntax/module-reader)
         shrubbery/parse
         (only-in (submod shrubbery reader) get-info-proc))

(provide (rename-out [sh-reader-module-begin #%module-begin])
         parse-all get-info-proc)

(define-syntax (sh-reader-module-begin stx)
  (syntax-case stx ()
    [(_ family)
     #'(mr:#%module-begin
        (submod mystery-languages/sh/langs family)
        #:read (lambda (in) (list (syntax->datum (parse-all in))))
        #:read-syntax (lambda (src in) (list (parse-all in #:source src)))
        #:whole-body-readers? #t
        #:info (lambda (key default make-default)
                 (case key
                   [(documentation-language-family) "Mystery languages"]
                   [else (get-info-proc key default make-default)]))
        (require mystery-languages/sh/reader))]))
