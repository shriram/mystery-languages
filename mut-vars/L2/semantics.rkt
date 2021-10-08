#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top)

(provide + - * /
         < <= > >=
         = <>
         defvar
         ++
         if and or not
         deffun)

(provide begin vset)

(provide (rename-out [app-by-ref #%app]))

(define-syntax (make-variable-protocol stx)
  (syntax-parse stx
    [(_ program-var-name:id corresponding-tmp-var-name:id)
     #'(define-syntax program-var-name
         (lambda (stx)
           (syntax-case stx (set-to do-not-unbox)
             [v                (identifier? #'v) #'(unbox corresponding-tmp-var-name)]
             [(v set-to w)     (identifier? #'v) #'(set-box! corresponding-tmp-var-name w)]
             [(v do-not-unbox) (identifier? #'v) #'corresponding-tmp-var-name]
             [(v . rest) (identifier? #'v) #'(app-by-ref (unbox corresponding-tmp-var-name) . rest)])))]))
     

(define-syntax (deffun stx)
  (syntax-parse stx
    [(_ (fname:id arg:id ...) body:expr ...+)
     (with-syntax ([(tmp ...) (generate-temporaries #'(arg ...))])
       #'(defvar fname
           (record-local-function
            (lambda (arg ...)
              (let ([tmp arg] ...)
                (make-variable-protocol arg tmp)
                ...
                (let () body ...))))))]))

(define-syntax (defvar stx)
  (syntax-parse stx
    [(_ var:id rhs:expr)
     (with-syntax ([(tmp) (generate-temporaries #'(var))])
       #'(begin
           (define tmp (box rhs))  ;; NOTE: this would break recursion if defvar were recursive
           (make-variable-protocol var tmp)))]))

(define-syntax (vset stx)
  (syntax-parse stx
    [(_ var:id val:expr)
     #'(var set-to val)]))

(define-syntax (pass-to-local-fun stx)
  (syntax-case stx ()
    [(_ var)
     (identifier? #'var)
     #'(var do-not-unbox)]
    [(_ e) #'(box e)]))  ;; make up a box for the receiver to mutate

(define-syntax (pass-to-import stx)
  (syntax-case stx ()
    [(_ var)
     (identifier? #'var)
     #'var]
    [(_ e) #'e]))

(define-syntax (app-by-ref stx)
  (syntax-case stx ()
    [(_ f a ...)
     #'(if (is-local-function? f)
           (f (pass-to-local-fun a) ...)
           (f (pass-to-import a) ...))]))
