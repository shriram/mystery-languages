#lang racket

(require [for-syntax syntax/parse] mystery-languages/utils mystery-languages/common)
(require [for-syntax racket])

(provide #%module-begin #%top-interaction
         #%datum #%top #%app)

(provide ++ string=? [rename-out (permissive-string-ref string-ref)])

(define (++ . ws)
  (if (empty? ws)
      ""
      (if (empty? (rest ws))
          (first ws)
          (string-append (first ws)
                         " "
                         (apply ++ (rest ws))))))

(define (permissive-string-ref s n)
  (cond
    [(string=? s "") ""]
    [(> n (string-length s)) ""]
    [else (string-ref s n)]))
