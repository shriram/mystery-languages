#lang racket

(provide ML-error? ML-error-ex ML-okay? ML-okay-val)

(struct ML-error (ex)  #:transparent)
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
    (ML-okay (eval expr n))))

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
  (with-handlers ([exn? (λ (ex)
                          (print-exn ex))])
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
                    [(ML-error? r) ((error-display-handler) (exn-message (ML-error-ex r)) (ML-error-ex r))]
                    [else (error 'multi-runner "shouldn't have gotten here: ~a" r)]))
                results lang-print-names)))
  (newline)
  (flush-output))

(define (test-output e result-exprs namespaces)
  (let ([indices (range 0 (length result-exprs))])
    (display "••••• TESTING ") (write e) (displayln " (blank if all tests pass)")
    (flush-output)
    (define results (run-multiple e namespaces))
    (for-each (λ (r idx)
                (let ([res (list-ref results idx)])
                  (match r
                    ['failure      (check-pred ML-error? res)]
                    ['void         (check-pred (λ (v) (void? (ML-okay-val v))) res)]
                    [(list 'not w) (check-pred (λ (v) (and (ML-okay? v) (not (equal? w (ML-okay-val v))))) res)]
                    [(cons 'not _) (error 'TEST "not takes only one value in ~a" r)] 
                    [else          (check-equal? (ML-okay-val res) r)])))
              result-exprs indices)
    (newline)))
