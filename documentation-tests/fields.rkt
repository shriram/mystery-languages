#lang mystery-languages/fields

    (defvar o (object [a 43] [b "hello"]))
    (TEST (oget o a) 43 43 43)
