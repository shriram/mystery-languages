#lang racket/base
;; The shared machinery behind every `#lang mystery-languages/sh-<family>`:
;; translate each top-level group and hand the datum to the same runner
;; (`make-semantics.rkt`) and the same variant namespaces as the
;; parenthetical language of that family.  See sh/langs.rkt for the
;; list of families.

(require (for-syntax racket/base racket/list racket/string shrubbery/print "translate.rkt")
         mystery-languages/make-semantics
         "unparse.rkt")

(provide define-sh-language)

(begin-for-syntax
  (define (groups-of stx)
    (define e (syntax-e stx))
    (define head (and (pair? e) (syntax-e (car e))))
    (case head
      [(multi top) (cdr (syntax->list stx))]
      [(group) (list stx)]
      [else (raise-syntax-error 'mystery "expected shrubbery groups" stx)]))

  (define (run-form g family ns lpn)
    (define-values (kind datum expecteds e-group) (translate-top g family))
    (define (source stx)
      (datum->syntax #'test-output (string-trim (shrubbery-syntax->string stx) #:left? #f)))
    (case kind
      [(test)
       #`(parameterize ([current-error-message rewrite-exn] [error-print-width 1000])
           (test-output '#,(datum->syntax #f datum)
                        (list #,@(for/list ([e expecteds]) #`(quote-syntax #,e)))
                        #,ns
                        #:source #,(source e-group)))]
      [(show)
       #`(parameterize ([current-error-message rewrite-exn] [error-print-width 1000])
           (show-output '#,(datum->syntax #f datum) #,ns #,lpn #:source #,(source g)))]))

  (define ((make-module-begin family ns lpn) stx)
    (syntax-case stx ()
      [(_ body)
       #`(#%module-begin
          (module configure-runtime racket/base
            (require mystery-languages/sh/runtime-config))
          #,@(for/list ([g (groups-of #'body)]) (run-form g family ns lpn)))]))

  (define ((make-top-interaction family ns lpn) stx)
    (syntax-case stx ()
      [(_ . body)
       #`(begin #,@(for/list ([g (groups-of #'body)]) (run-form g family ns lpn)))])))

;; (define-sh-language <family> <module-path>): the module must provide
;; `namespaces` and `lang-print-names`, as every <family>/semantics.rkt does.
(define-syntax (define-sh-language stx)
  (syntax-case stx ()
    [(_ family semantics-module)
     #'(begin
         (require (rename-in semantics-module
                             [namespaces family-namespaces]
                             [lang-print-names family-lang-print-names]))
         (define namespaces family-namespaces)
         (define lang-print-names family-lang-print-names)
         (provide (rename-out [mod-begin #%module-begin]
                              [ti #%top-interaction]))
         (define-syntax mod-begin (make-module-begin 'family #'namespaces #'lang-print-names))
         (define-syntax ti (make-top-interaction 'family #'namespaces #'lang-print-names)))]))
