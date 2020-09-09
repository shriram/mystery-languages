#lang mystery-languages/fun-calls

    (deffun (f) 3)
    (deffun (g x) (+ x x))
    (deffun (h x y z) (++ x y z))

    (TEST (f) 3 3 3)
    (TEST (g 5) 10 10 10)
    (TEST (h "a" "b" "c") "abc" "abc" "abc")
