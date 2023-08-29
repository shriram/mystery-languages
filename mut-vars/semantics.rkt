#lang racket

(require mystery-languages/make-semantics)

(provide (rename-out [mod-begin #%module-begin]
                     [ti        #%top-interaction]))

(define-values (namespaces lang-print-names)
  (make-namespaces-and-lang-print-names (list 'mystery-languages/mut-vars/L1/semantics
                                              'mystery-languages/mut-vars/L2/semantics
                                              'mystery-languages/mut-vars/L3/semantics)))

(define-syntax (multi-runner stx)
  (syntax-case stx (TEST)
    [(_ (TEST e r ...))
     #`(test-output 'e (list #'r ...) namespaces)]
    [(_ e)
     #`(show-output 'e namespaces lang-print-names)]))

(define-syntax mod-begin
  (λ (stx)
    (syntax-case stx ()
      [(_ b ...)
       #'(#%printing-module-begin (multi-runner b) ...)])))

(define-syntax ti
  (λ (stx)
    (syntax-case stx ()
      ([_ . e]
       #'(#%top-interaction . (multi-runner e))))))
