#lang racket
(require (only-in racket/struct make-constructor-style-printer))

(provide ML-error? ML-error-ex ML-okay? ML-okay-val)

(struct ML-error (ex)  #:transparent
    #:property prop:custom-print-quotable 'never
    #:methods gen:custom-write
    [(define write-proc
       (make-constructor-style-printer
        (lambda (obj) 'ML-error)
        (lambda (obj) (list (exn-message (ML-error-ex obj))))))])
(struct ML-okay  (val) #:transparent)

(require rackunit)

(provide make-namespaces-and-lang-print-names print-exn run-or-error-string run/okay-or-error run-multiple show-output test-output)

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
    (ML-okay (force (eval expr n)))))

(define (run-multiple e ns)
  (map (λ (n) (run/okay-or-error e n)) ns))

(define (print-exn ex)
  (parameterize ([error-print-context-length 0])
    ((error-display-handler)
     (if (exn? ex)
         (exn-message ex)
         (format "~a" ex))
     ex))
  (flush-output))

(define (run-or-error-string expr n)
  (with-handlers ([exn? (λ (ex) (print-exn ex))])
    (display (eval expr n))
    (flush-output)))

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
                       ((error-display-handler) (exn-message the-exn) the-exn))]
                    [else (error 'multi-runner "shouldn't have gotten here: ~a" r)]))
                results lang-print-names)))
  (newline)
  (flush-output))

(define (test-output e expecteds namespaces)
  (let ([indices (range 0 (length expecteds))])
    (display "••••• TESTING ") (write e) (displayln " (blank if all tests pass)")
    (flush-output)
    (define actuals (run-multiple e namespaces))
    (unless (= (length actuals) (length expecteds))
      (error 'TEST "number of results ~a does not match number of result terms ~a" (length actuals) (length expecteds)))
    (for ([actual actuals]
          [spec expecteds])
      (match spec
        [(or 'failure 'error)
         (check-pred ML-error? actual
                     (format "expected an error, received ~a" actual))]
        [`(not ,w)
         (check-pred
          (λ (v) (and (ML-okay? v) (not (equal? w (ML-okay-val v)))))
          actual
          (format "expected a value that is not ~a, recieved ~a" w actual))]
        [`(not ,@_)
         (error 'TEST "not takes only one value in ~a" spec)]
        ['void
         (check-equal? actual (ML-okay (void)))]
        [else
         (check-equal? actual (ML-okay spec))]))
    (newline)))
