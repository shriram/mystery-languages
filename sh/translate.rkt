#lang racket/base
;; Shrubbery front-end for the mystery languages: translate a parsed
;; shrubbery group into the S-expression datum that the parenthetical
;; syntax would have read.  This is the whole of the front-end's
;; semantics: the datum is evaluated by the unchanged L1/L2/... modules.
;;
;; Every family shares one grammar; the only family-specific point is the
;; meaning of `==` (see `binop-info`).

(require racket/match racket/list)

(provide translate-top      ; group family -> (values 'show datum #f #f)
                            ;               | (values 'test datum expected-stxs expr-group)
         translate-form)    ; group family -> datum (definitions and expressions; no `check`)

;; ---------- shrubbery syntax accessors

(define (kids s) (let ([e (syntax-e s)]) (and (pair? e) (cdr (syntax->list s)))))
(define (tag s)  (let ([e (syntax-e s)]) (and (pair? e) (syntax-e (car e)))))
(define (sym t)  (let ([e (syntax-e t)]) (and (symbol? e) e)))
(define (op-of t) (and (eq? (tag t) 'op) (syntax-e (car (kids t)))))
(define (lit? t) (let ([e (syntax-e t)]) (or (number? e) (string? e) (boolean? e))))
(define (block? t) (eq? (tag t) 'block))
(define (alts? t) (eq? (tag t) 'alts))
(define (parens? t) (eq? (tag t) 'parens))
(define (brackets? t) (eq? (tag t) 'brackets))
(define (braces? t) (eq? (tag t) 'braces))

(define (fail stx msg . args)
  (raise-syntax-error 'mystery (if (null? args) msg (apply format msg args)) stx))

;; A group has no srcloc of its own; point at its first term.
(define (loc g) (let ([k (kids g)]) (if (pair? k) (car k) g)))

;; ---------- names

;; Identifiers that differ between the two syntaxes.
(define identifier-names
  (hasheq 'string_ref   'string-ref
          'is_empty     'empty?
          'is_procedure 'procedure?))

(define (map-identifier s) (hash-ref identifier-names s s))

(define or-sym (string->symbol "||"))

;; operator -> (list racket-name precedence); higher binds tighter
(define (binop-info family o)
  (case o
    [(* /)      (list o 8)]
    [(+ -)      (list o 7)]
    [(++)       (list '++ 7)]
    [(< <= > >=) (list o 5)]
    [(==)       (list (if (eq? family 'strings) 'string=? '=) 5)]
    [(!=)       (list '<> 5)]
    [(&&)       (list 'and 2)]
    [else (if (eq? o or-sym) (list 'or 1) #f)]))

(define prefix-minus-prec 9)
(define prefix-not-prec 3)

;; ---------- top level

(define (translate-top g family)
  (define ts (kids g))
  (cond
    [(and (pair? ts) (eq? (sym (car ts)) 'check))
     (define-values (e expecteds e-group) (translate-check g family))
     (values 'test e expecteds e-group)]
    [else (values 'show (translate-form g family) #f #f)]))

;; check: <expr> ~is [<constant>, ...]
(define (translate-check g family)
  (define ts (kids g))
  (unless (and (= (length ts) 2) (block? (cadr ts)))
    (fail (car ts) "expected `check: <expression> ~is [<constant>, ...]`"))
  ;; Either one line, `<expr> ~is [...]`, or the expression on its own
  ;; line(s) followed by a line starting with `~is`.
  (define body (kids (cadr ts)))
  (define terms
    (match body
      [(list g) (kids g)]
      [(list g is-g) #:when (let ([k (kids is-g)]) (and (pair? k) (is? (car k))))
       (append (kids g) (kids is-g))]
      [_ (fail (car ts) "expected `check: <expression> ~is [<constant>, ...]`, with `~is` on the same line as the expression or on the line after it")]))
  (define-values (e-terms rest) (split-at-is terms))
  (when (null? e-terms) (fail (car ts) "expected an expression before `~is`"))
  (unless (and (= (length rest) 2) (brackets? (cadr rest)))
    (fail (if (pair? rest) (car rest) (car e-terms))
          "expected `~is [<constant>, ...]`, one constant per language"))
  (values (expr family e-terms)
          (for/list ([g (kids (cadr rest))]) (expected-value family g))
          ;; the expression's terms as a group of their own, so the runner
          ;; can echo just the expression under test
          (datum->syntax #f (cons (car (syntax-e (car body))) e-terms) (car body) (car body))))

;; Split a group's terms at `~is`.  When the expression ends in a block or
;; alternatives (`if c | 1 | 2 ~is [...]`, `let x = 5: f() ~is [...]`),
;; the shrubbery parser attaches `~is [...]` to the innermost trailing
;; group; it is hoisted back out from there.
(define (is? t) (eq? (syntax-e t) '#:is))

(define (split-at-is terms)
  (define-values (before rest) (splitf-at terms (lambda (t) (not (is? t)))))
  (cond
    [(pair? rest) (values before rest)]
    [(and (pair? terms) (or (block? (last terms)) (alts? (last terms))))
     (define-values (container tail) (hoist-is (last terms)))
     (values (append (drop-right terms 1) (list container)) tail)]
    [else (values terms '())]))

;; container (block or alts) -> (values container-without-tail tail)
(define (hoist-is c)
  (define parts (kids c))
  (cond
    [(null? parts) (values c '())]
    [else
     (define-values (new-last tail)
       (case (tag c)
         [(block) (hoist-is-group (last parts))]
         [(alts) (hoist-is (last parts))]))
     (values (datum->syntax c (cons (car (syntax-e c)) (append (drop-right parts 1) (list new-last))) c c)
             tail)]))

(define (hoist-is-group g)
  (define-values (before tail) (split-at-is (kids g)))
  (values (datum->syntax g (cons (car (syntax-e g)) before) g g) tail))

;; -> syntax whose datum is what make-semantics's checker sees, with the
;; srcloc of the term so failure reports point into the source.  Exact
;; rationals (1/2, -3/10) are constants here because L1 arithmetic
;; produces them; anything else is translated as an expression, and the
;; checker itself decides what counts as a constant, exactly as it does
;; for the parenthetical syntax.
(define (expected-value family g)
  (define ts (kids g))
  (define (mk datum) (datum->syntax #f datum (car ts)))
  (match ts
    [(list n slash d) #:when (and (eq? (op-of slash) '/) (exact-integer? (syntax-e n)) (exact-integer? (syntax-e d)))
     (mk (/ (syntax-e n) (syntax-e d)))]
    [(list m n slash d) #:when (and (eq? (op-of m) '-) (eq? (op-of slash) '/)
                                    (exact-integer? (syntax-e n)) (exact-integer? (syntax-e d)))
     (mk (- (/ (syntax-e n) (syntax-e d))))]
    [(list) (fail (loc g) "expected a constant")]
    [_ (mk (expr family ts))]))

(define (char-literal c s)
  (define str (syntax-e s))
  (unless (= (string-length str) 1) (fail s "Char needs a one-character string"))
  (string-ref str 0))

;; ---------- definitions and expressions

(define (translate-form g family)
  (define ts (kids g))
  (when (null? ts) (fail g "empty form"))
  (define head (sym (car ts)))
  (case head
    [(def)
     (match ts
       [(list _ x eq rhs ...)
        #:when (and (sym x) (eq? (op-of eq) '=) (pair? rhs))
        `(defvar ,(sym x) ,(expr family rhs))]
       [_ (fail (car ts) "expected `def <name> = <expression>`")])]
    [(fun)
     (match ts
       [(list _ f ps b) #:when (and (sym f) (parens? ps) (block? b))
        `(deffun (,(sym f) ,@(params ps)) ,@(body family b))]
       [(list _ ps b) #:when (and (parens? ps) (block? b))
        (expr family ts)]
       [_ (fail (car ts) "expected `fun <name>(<param>, ...): <body>`")])]
    [(check) (fail (car ts) "`check` is allowed only at the top level")]
    [else (expr family ts)]))

(define (params ps)
  (for/list ([g (kids ps)])
    (match (kids g)
      [(list p) #:when (sym p) (sym p)]
      [_ (fail (loc g) "expected a parameter name")])))

;; block -> list of datums, one per line
(define (body family b)
  (define gs (kids b))
  (when (null? gs) (fail b "empty block"))
  (for/list ([g gs]) (translate-form g family)))

;; block that must hold exactly one expression
(define (single family b what)
  (define gs (kids b))
  (unless (= (length gs) 1) (fail b "~a must be a single expression" what))
  (expr family (kids (car gs))))

;; ---------- expressions: a Pratt parser over the terms of a group

(define (expr family terms)
  (when (null? terms) (fail #f "expected an expression"))
  (define-values (e rest) (parse-expr family terms 0))
  (unless (null? rest)
    (fail (car rest) "unexpected term after an expression"))
  e)

(define (parse-expr family terms min-prec)
  (when (null? terms) (fail #f "expected an expression"))
  (define-values (lhs0 rest0) (parse-prefix family terms))
  ;; lhs-op: the operator that built `lhs` in this loop, so that
  ;; `a + b + c` becomes (+ a b c) as in the parenthetical syntax, while
  ;; `(a + b) + c` stays nested.
  (let loop ([lhs lhs0] [lhs-op #f] [lhs-prec #f] [rest rest0])
    (cond
      [(null? rest) (values lhs rest)]
      [else
       (define t (car rest))
       (define o (op-of t))
       (cond
         [(not o) (fail t "expected an operator")]
         [(eq? o ':=)
          (cond
            [(> min-prec 0) (values lhs rest)]
            [else
             (define-values (rhs rest2) (parse-expr family (after-op t (cdr rest)) 0))
             (values (assignment lhs rhs t) rest2)])]
         [(binop-info family o)
          => (lambda (info)
               (define rkt (car info))
               (define prec (cadr info))
               (cond
                 [(< prec min-prec) (values lhs rest)]
                 [else
                  (define-values (rhs rest2) (parse-expr family (after-op t (cdr rest)) (add1 prec)))
                  (cond
                    [(eq? lhs-op rkt) (loop (append lhs (list rhs)) rkt prec rest2)]
                    [(and lhs-prec (= lhs-prec prec 5))
                     (fail t "cannot mix different comparison operators in one chain")]
                    [else (loop (list rkt lhs rhs) rkt prec rest2)])]))]
         [else (fail t "unknown operator `~a`" o)])])))

(define (after-op t more)
  (when (null? more) (fail t "expected an expression after `~a`" (op-of t)))
  more)

(define (assignment lhs rhs t)
  (match lhs
    [(? symbol?) `(set! ,lhs ,rhs)]
    [(list 'oget o f) `(oset ,o ,f ,rhs)]
    [_ (fail t "the left side of `:=` must be a variable or a field")]))

(define (parse-prefix family terms)
  (define t (car terms))
  (define more (cdr terms))
  (case (op-of t)
    [(-)
     (when (null? more) (fail t "expected an expression after `-`"))
     (define-values (e rest) (parse-expr family more prefix-minus-prec))
     (values `(- ,e) rest)]
    [(!)
     (when (null? more) (fail t "expected an expression after `!`"))
     (define-values (e rest) (parse-expr family more prefix-not-prec))
     (values `(not ,e) rest)]
    [(#f)
     (define-values (e rest) (parse-primary family t more))
     (parse-postfix family e rest)]
    [else (fail t "operator `~a` needs a left operand" (op-of t))]))

(define (parse-primary family t more)
  (cond
    [(lit? t) (values (syntax-e t) more)]
    [(sym t)
     => (lambda (s)
          (case s
            [(if) (parse-if family t more)]
            [(fun) (parse-lambda family t more)]
            [(let) (parse-let family t more)]
            [(block)
             (unless (and (pair? more) (block? (car more)))
               (fail t "expected `block:` followed by a block"))
             (values `(begin ,@(body family (car more))) (cdr more))]
            [(Char)
             (unless (and (pair? more) (string? (syntax-e (car more))))
               (fail t "expected `Char\"<one character>\"`"))
             (values (char-literal t (car more)) (cdr more))]
            [else (values (map-identifier s) more)]))]
    [(parens? t)
     (match (kids t)
       [(list g) (values (expr family (kids g)) more)]
       [(list) (fail t "empty parentheses")]
       [_ (fail t "comma-separated terms are not an expression")])]
    [(brackets? t)
     (define es (for/list ([g (kids t)]) (expr family (kids g))))
     (values (if (null? es) 'empty `(list ,@es)) more)]
    [(braces? t)
     (values `(object ,@(for/list ([g (kids t)]) (object-field family g))) more)]
    [(keyword? (syntax-e t)) (fail t "unexpected keyword")]
    [else (fail t "unexpected term")]))

;; if <cond> | <then> | <else>
(define (parse-if family t more)
  (define-values (c-terms rest) (splitf-at more (lambda (x) (not (alts? x)))))
  (when (null? c-terms) (fail t "expected a condition after `if`"))
  (unless (pair? rest) (fail t "expected `| <then> | <else>` after the condition"))
  (define branches (kids (car rest)))
  (unless (= (length branches) 2)
    (fail (car rest) "`if` needs exactly two alternatives"))
  (values `(if ,(expr family c-terms)
               ,(single family (car branches) "the `then` branch")
               ,(single family (cadr branches) "the `else` branch"))
          (cdr rest)))

;; fun (<param>, ...): <body>
(define (parse-lambda family t more)
  (match more
    [(list ps b rest ...) #:when (and (parens? ps) (block? b))
     (values `(lambda ,(params ps) ,@(body family b)) rest)]
    [_ (fail t "expected `fun (<param>, ...): <body>` (a named `fun` goes at the top level)")]))

;; let <name> = <expr>: <body>
(define (parse-let family t more)
  (match more
    [(list x eq rhs ... b) #:when (and (sym x) (eq? (op-of eq) '=) (pair? rhs) (block? b))
     (values `(let ([,(sym x) ,(expr family rhs)]) ,@(body family b)) '())]
    [_ (fail t "expected `let <name> = <expression>: <body>`")]))

;; postfix: application `e(...)`, field access `e.name`, computed field `e[expr]`
(define (parse-postfix family e rest)
  (match rest
    [(list p more ...) #:when (parens? p)
     (parse-postfix family `(,e ,@(for/list ([g (kids p)]) (expr family (kids g)))) more)]
    [(list dot f more ...) #:when (and (eq? (op-of dot) '|.|) (sym f))
     (parse-postfix family `(oget ,e ,(sym f)) more)]
    [(list b more ...) #:when (brackets? b)
     (match (kids b)
       [(list g) (parse-postfix family `(oget ,e ,(field-expr family g)) more)]
       [_ (fail b "expected exactly one field expression in brackets")])]
    [_ (values e rest)]))

;; A field position holds an expression.  In the parenthetical syntax a
;; bare name there is the field's literal name; here the brackets say the
;; name is computed, so a bare variable is wrapped in an identity `if`,
;; which is an expression every field language evaluates.
(define (field-expr family g)
  (match (kids g)
    [(list t) #:when (sym t) `(if #t ,(map-identifier (sym t)) ,(map-identifier (sym t)))]
    [ts (expr family ts)]))

;; {name: e, [expr]: e, "str": e}
(define (object-field family g)
  (define ts (kids g))
  (unless (and (pair? ts) (block? (last ts)))
    (fail (loc g) "expected `<field>: <expression>`"))
  (define key-terms (drop-right ts 1))
  (define key
    (match key-terms
      [(list k) #:when (sym k) (sym k)]
      [(list b) #:when (brackets? b)
       (match (kids b)
         [(list kg) (field-expr family kg)]
         [_ (fail b "expected exactly one field expression in brackets")])]
      [(list) (fail (loc g) "expected a field name before `:`")]
      [_ (expr family key-terms)]))
  (list key (single family (last ts) "a field's value")))
