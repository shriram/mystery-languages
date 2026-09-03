#lang mystery-languages/fields

(defvar o (object [a 43] [b "hello"]))
(TEST (oget o a) 43 43 43)
(TEST (oget o b) "hello" "hello" "hello")
(TEST (oget o c) failure failure failure)
(TEST (oget (oget (object [a (object [b 1])]) a) b) 1 1 1)
(TEST (oget (oget (object [n (object [m 2])]) n) m) 2 2 2)
(deffun (getA o) (oget o a))
(TEST (getA o) 43 43 43)
(TEST (+ (oget o a) 1) 44 44 44)
(TEST (if (= (oget o a) 43) "yes" "no") "yes" "yes" "yes")
