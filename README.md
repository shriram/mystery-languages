This is the repository for Mystery Languages. Mystery languages are based on the paper
[Teaching Programming Languages by Experimental and Adversarial Thinking](https://cs.brown.edu/~sk/Publications/Papers/Published/pkf-teach-pl-exp-adv-think/).

# Setup

## Installation

Install this package using the Racket packet manager:

* From DrRacket, go to File | Install Package, and enter the URL
(If DrRacket says `missing dependencies`, click Show Details |
Dependencies Mode | Auto)

  `https://github.com/shriram/mystery-languages.git`
  

* At the command line, run

  `raco pkg install https://github.com/shriram/mystery-languages.git`

  Make sure your paths are set correctly so that you're installing the
  package for the right version!

## Checking

To make sure your install succeeded, in DrRacket (or the command line,
if you know what you're doing), run the following:

```
#lang mystery-languages/strings

3
```

You should see output like
```
3
L1: 3
L2: 3
L3: 3
```
This means everything is alright!

## Learn More

You should probably watch
[this video](https://youtu.be/EogblZ1Rdpo)
before you continue; everything below will make much more sense.

-----

# Documentation

There are two parts: testing, and the languages.

This documentation can be a little overwhelming initially. That's
because it documents an entire *family* of languages. As you get
closer to the end, you'll probably be grateful to have all the
documentation on one page…but it does mean it can be a little
intimidating at first. Don't worry!

## Testing

In all of these languages, you can just write and run expressions as
usual, or you can write tests to either express what you expect or
record what you saw. Testing is a little funny because all these
languages produce many values, not one! Therefore, the mystery
language package provides a new testing form, `TEST`:

    (TEST <expr> <constant:expected> …)

Thus you might write

    (TEST (+ 4 5) 9 9 9)

(assuming there were three language variants). This means you expect
each of the three languages to produce `9`.

One subtlety. If instead of the above you write

    (TEST (+ 4 5) 9 9 (+ 5 4))

that means you don't expect the third language to produce `9`, but
rather the symbolic expression `(+ 5 4)`. That's what it means for
each of the expected answers to be a *constant*.

> In case you're wondering why… Imagine that you write an
> expression. This expression needs to be evaluated. In which language
> would it be evaluated? The whole point is that the languages might
> differ, so there could be multiple outcomes. To avoid confusion,
> this package assumes you will do all your *computation* inside the
> expression, and check only for constants in testing.

Sometimes, a test intentionally ends in an error (as a way of showing
that one language errors while another does not). Instead of forcing
you to write a complex error condition, you can just write `failure`
in that position. Similarly, sometimes it's useful to say that a value
is *not* some other value, again to emphasize difference. You can then
say `(not <constant>)`. For instance:

    (TEST (/ 1 0) failure failure failure)

says that `(/ 1 0)` will lead to an error in all the languages;

    (TEST (+ 1 2) 3 3 (not 2))

says that `(+ 1 2)` does *not* evaluate to `2` in the third
language.

> This is a rather unsurprising and perhaps odd use of `not`, but
> there are times when writing the exact answer is hard, and all we
> want to emphasize is that it is not some *other* exact,
> easy-to-write answer.

## The Languages

Below is the documentation of all the mystery languages. Most
languages build on top of other languages; the notation
`[arithmetic +]` means “all the features of `arithmetic`; in
addition…”. `strings` is provided only for demonstration purposes.

All languages have basic constants: numbers (like `0`, `1.3`), strings
(like `""`, `"hi"`), booleans (`#t` or `#true`, and `#f` or
`#false`).

*All* languages use prefix-parenthetical syntax. Thus we add `1` and
`2` as follows:

    (+ 1 2)    ;; produces 3

Because the parentheses disambiguate, most operations can take any
number of parameters, such as:

    (+ 1 2 3)  ;; produces 6
	(+ 1)      ;; produces 1
	(+)        ;; produces 0

Because this is common to all languages, we do not explicate this
syntax below. Because there are no infix operators, there are no other
rules for function operations. We only introduce syntax when it is not
an expression.

### `strings`

    ++ string=?

`++` appends strings. `string=?` compares them for equality.

### `arithmetic`

    + - * /
    < <= > >=
    and or not
    = <>
	defvar

Most of these operations are self-explanatory. `<>` is
not-equal. `defvar` defines variables:

    (defvar <var:name> <expr:value>)

For instance:

	(defvar x 3)
	(TEST x 3 3 3)

### `conditionals`

    [arithmetic +]
    if and or not

The `if` takes three parts:

    (if <expr:conditional> <expr:then-part> <expr:else-part>)

For instance:

    (TEST (if #t 1 2) 1 1 1)

### `fun-calls`

    [conditionals +]
    deffun
    ++

`deffun` defines functions:

    (deffun (<var:fun-name> <var:param-name> …) <expr:body>)

The notation `…` above means “zero or more of”. Thus the following are
all legal function definitions:

    (deffun (f) 3)
    (deffun (g x) (+ x x))
    (deffun (h x y z) (++ x y z))

    (TEST (f) 3 3 3)
    (TEST (g 5) 10 10 10)
    (TEST (h "a" "b" "c") "abc" "abc" "abc")

### `fields`

    [fun-calls +]
    object oget

`object` defines objects, and `oget` accesses their fields. Their
syntaxes are as follows:

    (oget <expr:obj-valued> <name:field>)
    (object [<name:field> <expr:value>] ...)

where `name` can be either a variable-name or an expression. For
instance,

    (defvar o (object [a 43] [b "hello"]))
	(TEST (oget o a) 43 43 43)

### `mut-vars`

    [fun-calls +]
    begin
    vset

`begin` allows a sequence of expressions:

    (begin <expr> …)

`vset` changes the value of a variable:

	(defvar v 3)
	(vset v 4)
	(TEST v 4 4 4)

### `mut-structs`

    [fields +]
    oset

`oset` changes the value of a field. Its syntax is:

    (oset <expr:obj-valued> <name:field> <expr:new-value>)

For instance:

    (defvar o (object [a 43] [b "hello"]))
	(oset o a 17)
	(TEST (oget o a) 17 17 17)

### `eval-order`

    [mut-vars]

No new constructs! Just new behavior…

