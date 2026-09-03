#lang racket/base
;; The inverse of translate.rkt: print an S-expression datum in the
;; Shrubbery syntax, and rename the Racket-level names that appear in
;; error messages.  Used only to rewrite error messages raised by the
;; language variants, which print the datum they were given; the text
;; produced is canonical (one line, standard spacing), not the
;; student's original spelling.

(require racket/match racket/string racket/list
         (only-in "translate.rkt" identifier-names))

(provide unparse            ; datum -> string
         construct-name)    ; symbol -> string or #f: the Shrubbery name of a construct

;; Shrubbery names for the constructs and built-in functions, for the
;; `who:` part of an error message and for "undefined" messages.
(define names
  (hash 'defvar "def" 'deffun "fun" 'lambda "fun" 'λ "fun"
        'begin "block" 'set! ":="
        'object "{...}" 'oget "field access" 'oset "field assignment"
        'list "[...]" 'empty "[]"
        'string-ref "string_ref" 'empty? "is_empty" 'procedure? "is_procedure"
        'string=? "==" '= "==" '<> "!=" 'and "&&" 'or "||" 'not "!"))

(define (construct-name s) (hash-ref names s #f))

;; Racket name -> Shrubbery name for the built-in functions (string-ref -> string_ref)
(define function-names
  (for/hash ([(sh rkt) (in-hash identifier-names)]) (values rkt sh)))
(define (identifier s) (symbol->string (hash-ref function-names s s)))

;; who: in a syntax error, e.g. "oget: expected identifier"
(define who-names
  (hash 'oget "field access" 'oset "field assignment" 'object "object literal"
        'deffun "fun" 'defvar "def" 'set! ":=" 'begin "block" 'lambda "fun"))

;; ---------- precedence, as in translate.rkt (higher binds tighter)

(define (prec op)
  (case op
    [(* /) 8] [(+ - ++) 7] [(< <= > >= = <> string=?) 5] [(and) 2] [(or) 1] [else #f]))

(define (op-name op)
  (case op [(=) "=="] [(<>) "!="] [(and) "&&"] [(or) "||"] [(string=?) "=="] [else (symbol->string op)]))

(define (unparse d) (up d 0))

(define (paren-if c s) (if c (string-append "(" s ")") s))

;; ctx: the minimum precedence the surrounding context requires;
;; 0 = anything, 9 = an operand of prefix minus / postfix operator
(define (up d ctx)
  (match d
    ['empty "[]"]
    [(? symbol?) (identifier d)]
    [(? boolean?) (if d "#true" "#false")]
    [(? string?) (format "~s" d)]
    [(? char?) (format "Char~s" (string d))]
    ;; a negative literal is one token, so it needs parentheses only as
    ;; the operand of prefix minus, where `--5` would be another operator
    [(? number?) (if (and (negative? d) (= ctx 9)) (format "(~a)" d) (number->string d))]
    ;; definitions
    [`(defvar ,x ,e) (format "def ~a = ~a" (up x 0) (up e 0))]
    [`(deffun (,f ,@ps) ,@body) (format "fun ~a(~a): ~a" (up f 0) (args ps) (bodies body))]
    [`(lambda (,@ps) ,@body) (paren-if (> ctx 0) (format "fun (~a): ~a" (args ps) (bodies body)))]
    [`(let ([,x ,e]) ,@body) (paren-if (> ctx 0) (format "let ~a = ~a: ~a" (up x 0) (up e 0) (bodies body)))]
    [`(begin ,@body) (paren-if (> ctx 0) (format "block: ~a" (bodies body)))]
    ;; the identity wrapper translate.rkt puts around a bare variable in a
    ;; computed field position, when it shows up on its own in a message
    [`(if #t ,(? symbol? k) ,k) (symbol->string k)]
    ;; an `if` inside a branch would swallow the remaining alternatives
    [`(if ,c ,t ,e) (paren-if (> ctx 0) (format "if ~a | ~a | ~a" (up c 1) (up t 1) (up e 1)))]
    ;; assignment
    [`(set! ,x ,e) (paren-if (> ctx 0) (format "~a := ~a" (up x 0) (up e 0)))]
    [`(oset ,o ,f ,e) (paren-if (> ctx 0) (format "~a := ~a" (field-access o f) (up e 0)))]
    ;; objects
    [`(object ,@fields)
     (format "{~a}" (string-join (for/list ([fl fields]) (object-field fl)) ", "))]
    [`(oget ,o ,f) (field-access o f)]
    ;; lists
    [`(list ,@es) (format "[~a]" (args es))]
    ;; prefix minus: `- 5` with a space, since `-5` is a literal
    [`(- ,(? (lambda (e) (and (number? e) (not (negative? e)))) e)) (format "- ~a" e)]
    [`(- ,e) (format "-~a" (up e 9))]
    ;; `!` is weaker than comparisons, so `!a == b` is (not (= a b));
    ;; parenthesising every compound operand is the simplest safe form
    [`(not ,e) (format "!~a" (if (and (pair? e) (eq? (car e) 'not)) (format "(~a)" (up e 0)) (up e 9)))]
    ;; binary operator chains: a chain is one n-ary form, so a left
    ;; operand that is the same operator, or any comparison under a
    ;; comparison, must be parenthesised to stay a separate form
    [`(,(? prec op) ,a ,b ,@more)
     (define p (prec op))
     (define left-ctx
       (if (and (pair? a) (prec (car a)) (or (eq? (car a) op) (= p (prec (car a)) 5)))
           (add1 p)
           p))
     (paren-if (> ctx p)
               (string-join (cons (up a left-ctx) (for/list ([e (cons b more)]) (up e (add1 p))))
                            (format " ~a " (op-name op))))]
    ;; application
    [`(,f ,@as) #:when (or (symbol? f) (pair? f))
     (format "~a(~a)" (up f 9) (args as))]
    [_ (format "~s" d)]))

(define (args es) (string-join (for/list ([e es]) (up e 0)) ", "))

;; bodies on one line, `;`-separated; a block form before the last
;; position would swallow the rest, so those get parentheses
(define (bodies body)
  (define n (length body))
  (string-join (for/list ([b body] [i (in-naturals 1)]) (up b (if (= i n) 0 1))) "; "))

;; a field position: bare symbol = literal name; the identity wrapper
;; that translate.rkt puts around a bare variable prints as the variable
(define (field-access o f)
  (define obj (up o 9))
  (match f
    [(? symbol?) (format "~a.~a" obj f)]
    [`(if #t ,(? symbol? k) ,k) (format "~a[~a]" obj k)]
    [_ (format "~a[~a]" obj (up f 0))]))

(define (object-field fl)
  (match fl
    [`(,(? symbol? k) ,v) (format "~a: ~a" k (up v 0))]
    [`((if #t ,(? symbol? k) ,k) ,v) (format "[~a]: ~a" k (up v 0))]
    [`(,k ,v) (format "~a: ~a" (up k 0) (up v 0))]))

;; ---------- error messages

(provide rewrite-exn who-names)

;; Rebuild the message of an exception raised by a variant so that any
;; datum it quotes is shown in Shrubbery.  Syntax errors get their
;; `at:`/`in:` lines regenerated from the exception's syntax objects;
;; unbound-variable errors for a construct the language lacks get the
;; construct's Shrubbery name.
(define (rewrite-exn ex)
  (define lines (regexp-split #rx"\n" (exn-message ex)))
  (string-join (cons (rename-who (car lines)) (map rewrite-datum-line (cdr lines))) "\n"))

;; "  at: (oget o \"a\")" -> "  at: o[\"a\"]".  Racket printed the datum with
;; `write`, so it can be read back; a line that does not read (for
;; instance one Racket abbreviated with `...`) is left alone.
(define (rewrite-datum-line line)
  (match (regexp-match #rx"^(  (?:at|in): )(.*)$" line)
    [(list _ prefix text)
     (define d (with-handlers ([exn:fail:read? (lambda (e) (void))])
                 (define in (open-input-string text))
                 (define v (read in))
                 (if (eof-object? (read in)) v (void))))
     (if (void? d) line (string-append prefix (unparse d)))]
    [_ line]))

;; "oget: field a not found" -> "field access: field a not found";
;; "begin: undefined; ..." -> "block: undefined; ..."
(define (rename-who msg)
  (define m (regexp-match #rx"^([^ :\n]+): (.*)$" msg))
  (cond
    [(not m) msg]
    [else
     (define who (string->symbol (cadr m)))
     (define rest (caddr m))
     (define new-who
       (if (regexp-match? #rx"^undefined" rest)
           (construct-name who)
           (hash-ref who-names who #f)))
     (if new-who (string-append new-who ": " rest) msg)]))
