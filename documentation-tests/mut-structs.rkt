#lang mystery-languages/mut-structs

    (defvar o (object [a 43] [b "hello"]))
    (oset o a 17)
    (TEST (oget o a) 17 17 17)
