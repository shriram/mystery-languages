#lang mystery-languages/strings

(TEST (string=? "a" "a") #t #t #t)
(TEST (string=? "a" "b") #f #f #f)
(TEST (string-ref "abc" 1) #\b #\b #\b)
(TEST (string-ref "abc" 0) #\a #\a #\a)
(string-ref "hello" 0)
(TEST (string=? "" "") #t #t #t)
(TEST (string=? (string=? "a" "a") "a") failure failure failure)
(TEST "x" string string string)
