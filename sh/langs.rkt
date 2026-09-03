#lang racket/base
;; The one list of families that have a Shrubbery syntax.  Each entry
;; becomes a submodule `(submod mystery-languages/sh/langs <family>)`
;; whose variants are those of mystery-languages/<family>/semantics, so
;; the two syntaxes of a family cannot name different variant sets.
;; The `#lang mystery-languages/sh-<family>` reader for each lives in
;; sh-<family>/lang/reader.rkt and is two lines.

(require (for-syntax racket/base))

(define-syntax (define-sh-languages stx)
  (syntax-case stx ()
    [(_ family ...)
     (with-syntax ([(semantics-module ...)
                    (for/list ([f (syntax->list #'(family ...))])
                      (datum->syntax f (string->symbol
                                        (format "mystery-languages/~a/semantics" (syntax-e f)))))])
       #'(begin
           (module family racket/base
             (require mystery-languages/sh/semantics)
             (define-sh-language family semantics-module)
             (module configure-runtime racket/base
               (require mystery-languages/sh/runtime-config)))
           ...))]))

(define-sh-languages
  strings
  arithmetic
  conditionals
  fun-calls
  scope
  fields
  mut-vars
  mut-structs
  eval-order)
