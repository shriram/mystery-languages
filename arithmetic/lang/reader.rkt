#lang s-exp syntax/module-reader

mystery-languages/arithmetic/semantics

#:wrapper1 (lambda (t)
             (parameterize ([read-decimal-as-inexact #false])
               (t)))
#:language-info '#(exact-decimal/lang/language-info get-language-info #false)
