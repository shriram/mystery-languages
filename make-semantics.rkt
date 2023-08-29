#lang racket
(require (only-in racket/struct make-constructor-style-printer))
(require (only-in mystery-languages/utils observe))
(require mystery-languages/common)
(provide ML-error? ML-error-ex ML-okay? ML-okay-val)

(struct ML-error (ex)  #:transparent
  #:property prop:custom-print-quotable 'never
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'ML-error)
      (lambda (obj) (list (exn-message (ML-error-ex obj))))))])
(struct ML-okay  (val) #:transparent)

(require racket/pretty)
(pretty-print-size-hook
  (lambda (v display? the-port)
    (if (procedure? v)
        (string-length "#<procedure>")
        #f)))
(pretty-print-print-hook
  (lambda (v display? the-port)
    (display "#<procedure>" the-port)))

(port-write-handler (current-output-port) (lambda (v port) (pretty-write v port #:newline? #f)))
(port-display-handler (current-output-port) (lambda (v port) (pretty-display v port #:newline? #f)))
(port-print-handler (current-output-port) (lambda (v port) (pretty-print v port #:newline? #f)))

(require rackunit)

(provide make-namespaces-and-lang-print-names show-output test-output)

(define (make-namespaces-and-lang-print-names language-specs)

  (define lpns
    (foldr (λ (e past)
             (cons (string-append "L" (number->string e) ": ")
                   past))
           empty
           (range 1 (add1 (length language-specs)))))

  (define nss (map (λ (_) (make-base-empty-namespace)) language-specs))

  (for-each (λ (ls ns)
              (parameterize ([current-namespace ns])
                (namespace-require ls)))
            language-specs nss)

  (values nss lpns))

(define (run/okay-or-error expr n)
  (with-handlers ([exn? (λ (ex) (ML-error ex))])
    (ML-okay (observe (eval expr n)))))

(define (run-multiple e ns)
  (map (λ (n) (run/okay-or-error e n)) ns))

(define (test-multiple e ns cs)
  (map (λ (n c)
         (c (thunk (observe (eval e n)))))
       ns cs))

(define (show-output e namespaces lang-print-names)
  (writeln e)
  (let ([results (run-multiple e namespaces)])
    (unless (andmap (λ (r)
                      (and (ML-okay? r) (void? (ML-okay-val r))))
                    results)
      (for-each (λ (r lpn)
                  (display lpn)
                  (flush-output)
                  (cond
                    [(ML-okay? r)  (writeln (ML-okay-val r))]
                    [(ML-error? r)
                     (let ([the-exn (ML-error-ex r)])
                       ((error-display-handler) (exn-message the-exn) #f))]
                    [else (error 'multi-runner "shouldn't have gotten here: ~a" r)]))
                results lang-print-names)))
  (newline)
  (flush-output))

(define (test-output e expecteds namespaces)
  (display "••••• TESTING ") (write e) (displayln " (blank if all tests pass)")
  (flush-output)
  (unless (= (length namespaces) (length expecteds))
    (error 'TEST "number of results ~a does not match number of result terms ~a"
           (length namespaces)
           (length expecteds)))
  (test-multiple e namespaces (map checker-of-expected expecteds))
  (newline))

(define ((checker-of-expected expected) do)
  (define (make-checker neg? expected)
    (match expected
      [`(not ,expected)
       (make-checker (not neg?) expected)]
      [(or 'failure 'error)
       (if neg?
           (check-not-exn do)
           (check-exn any/c do))]
      [(or 'void 'void?)
       (if neg?
           (check-not-equal? (do) (void))
           (check-equal? (do) (void)))]
      [(or 'procedure 'procedure?)
       (if neg?
           (check-pred (not/c procedure?) (do) "expecting a non-procedure")
           (check-pred procedure? (do) "expecting a procedure"))]
      [(or 'number 'number?)
       (if neg?
           (check-pred (not/c number?) (do) "expecting a non-number")
           (check-pred number? (do) "expecting a number"))]
      [(or 'boolean 'boolean?)
       (if neg?
           (check-pred (not/c boolean?) (do) "expecting a non-boolean")
           (check-pred boolean? (do) "expecting a boolean"))]
      [(or 'string 'string?)
       (if neg?
           (check-pred (not/c string?) (do) "expecting a non-string")
           (check-pred string? (do) "expecting a string"))]
      [(or 'object 'object?)
       (if neg?
           (check-pred (not/c an-object?) (do) "expecting a non-object")
           (check-pred an-object? (do) "expecting an object"))]
      [val
       #:when ((or/c number? string? boolean? char?) val)
       (if neg?
           (check-not-equal? (do) val)
           (check-equal? (do) val))]
      [other
       (fail (format "~a is not a valid way to specify the result. Please check the documentation" other))]))
  (with-check-info*
      (list
       (make-check-location
        (list
         (syntax-source expected)
         (syntax-line expected)
         (syntax-column expected)
         (syntax-position expected)
         (syntax-span expected))))
    (thunk
     (make-checker #f (syntax->datum expected)))))
