This is the repository for Mystery Languages. Mystery languages are based on the paper
[Teaching Programming Languages by Experimental and Adversarial Thinking](https://cs.brown.edu/~sk/Publications/Papers/Published/pkf-teach-pl-exp-adv-think/).

# Setup

## Installation

Install this package using the Racket package manager:

* **Option 1:** from DrRacket, go to File | Install Package, and enter the URL
(If DrRacket says `missing dependencies`, click Show Details |
Dependencies Mode | Auto)

  `https://github.com/shriram/mystery-languages.git`
  
* **Option 2:** at the command line (your OS terminal, _not_ in DrRacket), run

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

There are three parts: the two syntaxes, testing, and the languages.

This documentation can be a little overwhelming initially. That's
because it documents an entire *family of families* of languages. As you get
closer to the end, you'll probably be grateful to have all the
documentation on one page…but it does mean it can be a little
intimidating at first. Don't worry!

## Two syntaxes

Every language comes in two syntaxes with the *same* semantics: a
parenthetical one, `#lang mystery-languages/<name>`, and a Shrubbery
one (the notation of Rhombus and Shplait),
`#lang mystery-languages/sh-<name>`. The Shrubbery front-end is a
translation to the parenthetical form; the translated program is then
run by exactly the same language implementations, so anything you learn
about a language in one syntax holds in the other. Use whichever you
are comfortable with.

The correspondence, for every construct in this document:

| Parenthetical | Shrubbery | Notes |
|---|---|---|
| `;; comment` | `// comment` | |
| `#\| comment \|#` | `/* comment */` | |
| `#t` `#f` (or `#true` `#false`) | `#true` `#false` | |
| `1` `1.3` `"hi"` | `1` `1.3` `"hi"` | |
| `(defvar x 3)` | `def x = 3` | |
| `(deffun (f x y) body)` | `fun f(x, y): body` | the body may span several indented lines |
| `(+ 1 2)` `(- 1 2)` `(* 1 2)` `(/ 1 2)` | `1 + 2` `1 - 2` `1 * 2` `1 / 2` | usual precedence; `1 + 2 + 3` is `(+ 1 2 3)`, `(1 + 2) + 3` is `(+ (+ 1 2) 3)` |
| `(- x)` | `-x` | |
| `(< 1 2)` `(<= 1 2)` `(> 1 2)` `(>= 1 2)` | `1 < 2` `1 <= 2` `1 > 2` `1 >= 2` | `1 < 2 < 3` is `(< 1 2 3)`; different comparisons cannot be chained |
| `(= 1 2)` `(<> 1 2)` | `1 == 2` `1 != 2` | |
| `(++ "a" "b")` | `"a" ++ "b"` | |
| `(if c t e)` | `if c \| t \| e` | or on three lines, with the `\|` lines indented to match |
| `(and a b)` `(or a b)` `(not a)` | `a && b` `a \|\| b` `!a` | |
| `(begin e1 e2 e3)` | `block:` followed by one expression per line | or `block: e1; e2; e3` on one line |
| `(set! v 4)` | `v := 4` | |
| `(object [a 43] [b "hello"])` | `{a: 43, b: "hello"}` | |
| `(object ["a" 1])` | `{"a": 1}` | a bare name before `:` is the field's name; a string is also allowed |
| `(oget o a)` | `o.a` | |
| `(oget o "a")` | `o["a"]` | brackets hold an expression that computes the name |
| `(oset o a 17)` | `o.a := 17` | |
| `(f)` `(g 5)` | `f()` `g(5)` | |
| `(lambda (x) body)` | `fun (x): body` | |
| `(let ([x 1]) body)` | `let x = 1: body` | one binding at a time |
| `empty` `(list 1 2)` `(cons 1 empty)` | `[]` `[1, 2]` `cons(1, [])` | |
| `(string=? a b)` `(string-ref s i)` | `a == b` `string_ref(s, i)` | |
| `#\b` (a character) | `Char"b"` | |
| `(TEST e 9 9 9)` | `check: e ~is [9, 9, 9]` | see [Testing](#testing) |

Running a program echoes each form as you wrote it, followed by each
language's answer. In the parenthetical syntax:

```
#lang mystery-languages/arithmetic

(+ 1 (* 2 3))
```

prints

```
(+ 1 (* 2 3))
L1: 7
L2: 7
L3: 7
```

and in the Shrubbery syntax:

```
#lang mystery-languages/sh-arithmetic

1 + 2 * 3
```

prints

```
1 + 2 * 3
L1: 7
L2: 7
L3: 7
```

## Testing

In all of these languages, you can just write and run expressions as
usual, or you can write tests to either express what you expect or
record what you saw. Testing is a little funny because all these
languages produce many values, not one! Therefore, the mystery
language package provides a new testing form, called `TEST` in one
syntax and `check` in the other:

| Parenthetical | Shrubbery |
|---|---|
| `(TEST <expr> <constant:expected> …)` | `check: <expr> ~is [<constant:expected>, …]` |

Thus you might write

| Parenthetical | Shrubbery |
|---|---|
| `(TEST (+ 4 5) 9 9 9)` | `check: 4 + 5 ~is [9, 9, 9]` |

(assuming there were three language variants). This means you expect
each of the three languages to produce `9`.

Each expected answer must be a *constant*: a number, a string, a
boolean, or one of the special words below. It cannot be an
expression. If you write

| Parenthetical | Shrubbery |
|---|---|
| `(TEST (+ 4 5) 9 9 (+ 5 4))` | `check: 4 + 5 ~is [9, 9, 5 + 4]` |

the third position is an error ("not a valid way to specify the
result"), not a test that expects `9`.


Sometimes, a test intentionally ends in an error (as a way of showing
that one language errors while another does not). Instead of forcing
you to write a complex error condition, you can just write `failure`
in that position. Similarly, sometimes it's useful to say that a value
is *not* some other value, again to emphasize difference. You can then
say `(not <constant>)` in the parenthetical syntax and `!<constant>`
in Shrubbery. For instance:

| Parenthetical | Shrubbery |
|---|---|
| `(TEST (/ 1 0) failure failure failure)` | `check: 1 / 0 ~is [failure, failure, failure]` |

says that dividing by zero will lead to an error in all the languages;

| Parenthetical | Shrubbery |
|---|---|
| `(TEST (+ 1 2) 3 3 (not 2))` | `check: 1 + 2 ~is [3, 3, !2]` |

says that `1 + 2` does *not* evaluate to `2` in the third
language.

> This is a rather unsurprising and perhaps odd use of `not`, but
> there are times when writing the exact answer is hard, and all we
> want to emphasize is that it is not some *other* exact,
> easy-to-write answer.

Besides `failure`, the words `void`, `procedure`, `number`, `boolean`
and `string` may stand in the expected position to say only
what *kind* of value is produced.

Some languages produce exact fractions, so a fraction such as `1/2` is
also accepted as an expected answer, in both syntaxes. In Shrubbery
this is the one place where `1/2` is read as the number one-half; in
an expression, `1/2` is the division of `1` by `2`.

In the Shrubbery syntax, `~is` may also go on the line after the
expression, which is convenient when the expression is a multi-line
`if` or `block`:

    check:
      if #true
      | 1
      | 2
      ~is [1, 1, 1]

Running a test prints a header line naming the expression under test,
and then any failures, or nothing more if all languages agreed with
you:

| Parenthetical | Shrubbery |
|---|---|
| `••••• TESTING (+ 4 5) (blank if all tests pass)` | `••••• TESTING 4 + 5 (blank if all tests pass)` |

## The Languages

Below is the documentation of all the mystery languages. Most
languages build on top of other languages; the notation
`[arithmetic +]` means “all the features of `arithmetic`; in
addition…”. `strings` is provided only for demonstration purposes.
Every construct is shown in both syntaxes, parenthetical on the left
and Shrubbery on the right; in prose, `parenthetical` | `Shrubbery`
uses the same order.

All languages have basic constants: numbers (like `0`, `1.3`), strings
(like `""`, `"hi"`), booleans (`#t` or `#true`, and `#f` or
`#false`; in Shrubbery only `#true` and `#false`).

Adding `1` and `2` looks like this:

| Parenthetical | Shrubbery |
|---|---|
| `(+ 1 2)` | `1 + 2` |

In the parenthetical syntax, *all* operations are written in prefix
form. Because the parentheses disambiguate, most operations can take
any number of parameters; the Shrubbery syntax writes the same thing
as a chain:

| Parenthetical | Shrubbery |
|---|---|
| `(+ 1 2 3)` | `1 + 2 + 3` |
| `(+ 1)` | (no equivalent) |
| `(+)` | (no equivalent) |

In Shrubbery, operators are infix with the usual precedence, and
parentheses group. Because this is common to all languages, we do not
explicate it below. We only introduce syntax when it is not an
expression.

### `strings`

| Parenthetical | Shrubbery |
|---|---|
| `++` `string=?` `string-ref` | `++` `==` `string_ref` |

`++` appends strings. `string=?` | `==` compares them for equality.
`string-ref` | `string_ref` refers to part of a string.

### `arithmetic`

| Parenthetical | Shrubbery |
|---|---|
| `+` `-` `*` `/` | `+` `-` `*` `/` |
| `<` `<=` `>` `>=` | `<` `<=` `>` `>=` |
| `=` `<>` | `==` `!=` |
| `defvar` | `def` |

Most of these operations are self-explanatory. `<>` | `!=` is
not-equal. `defvar` | `def` defines variables:

| Parenthetical | Shrubbery |
|---|---|
| `(defvar <var:name> <expr:value>)` | `def <var:name> = <expr:value>` |

For instance:

| Parenthetical | Shrubbery |
|---|---|
| `(defvar x 3)` | `def x = 3` |
| `(TEST x 3 3 3)` | `check: x ~is [3, 3, 3]` |

### `conditionals`

| Parenthetical | Shrubbery |
|---|---|
| `[arithmetic +]` | `[arithmetic +]` |
| `if` `and` `or` `not` | `if` `&&` `\|\|` `!` |

The `if` takes three parts:

| Parenthetical | Shrubbery |
|---|---|
| `(if <expr:conditional> <expr:then-part> <expr:else-part>)` | `if <expr:conditional> \| <expr:then-part> \| <expr:else-part>` |

For instance:

| Parenthetical | Shrubbery |
|---|---|
| `(TEST (if #t 1 2) 1 1 1)` | `check: if #true \| 1 \| 2 ~is [1, 1, 1]` |

### `fun-calls`

| Parenthetical | Shrubbery |
|---|---|
| `[conditionals +]` | `[conditionals +]` |
| `deffun` | `fun` |

`deffun` | `fun` defines functions:

| Parenthetical | Shrubbery |
|---|---|
| `(deffun (<var:fun-name> <var:param-name> …) <expr:body>)` | `fun <var:fun-name>(<var:param-name>, …): <expr:body>` |

The notation `…` above means “zero or more of”. Thus the following are
all legal function definitions:

| Parenthetical | Shrubbery |
|---|---|
| `(deffun (f) 3)` | `fun f(): 3` |
| `(deffun (g x) (+ x x))` | `fun g(x): x + x` |
| `(deffun (h x y z) (++ x y z))` | `fun h(x, y, z): x ++ y ++ z` |
| `(TEST (f) 3 3 3)` | `check: f() ~is [3, 3, 3]` |
| `(TEST (g 5) 10 10 10)` | `check: g(5) ~is [10, 10, 10]` |
| `(TEST (h "a" "b" "c") "abc" "abc" "abc")` | `check: h("a", "b", "c") ~is ["abc", "abc", "abc"]` |

### `scope`

| Parenthetical | Shrubbery |
|---|---|
| `[fun-calls +]` | `[fun-calls +]` |
| `lambda` `λ` `let` | `fun` (anonymous) `let` |
| `empty` `list` `cons` | `[]` `[…]` `cons` |
| `map` `filter` | `map` `filter` |

`lambda` | `fun` creates an anonymous function, `let` binds a name for
the extent of a body, and the rest build and process lists. Their
syntaxes are as follows:

| Parenthetical | Shrubbery |
|---|---|
| `(lambda (<var:param-name> …) <expr:body>)` | `fun (<var:param-name>, …): <expr:body>` |
| `(let ([<var:name> <expr:value>]) <expr:body>)` | `let <var:name> = <expr:value>: <expr:body>` |
| `empty` | `[]` |
| `(list <expr> …)` | `[<expr>, …]` |

### `fields`

| Parenthetical | Shrubbery |
|---|---|
| `[fun-calls +]` | `[fun-calls +]` |
| `object` `oget` | `{…}` `.` |

`object` defines objects, and `oget` accesses their fields. Their
syntaxes are as follows:

| Parenthetical | Shrubbery |
|---|---|
| `(oget <expr:obj-valued> <name:field>)` | `<expr:obj-valued>.<name:field>` |
| `(object [<name:field> <expr:value>] ...)` | `{<name:field>: <expr:value>, ...}` |

where `name` can be either a variable-name or an expression. In
Shrubbery, a field given by an expression is written in brackets:
`<expr:obj-valued>[<expr:field>]` and `{[<expr:field>]: <expr:value>}`.
For instance,

| Parenthetical | Shrubbery |
|---|---|
| `(defvar o (object [a 43] [b "hello"]))` | `def o = {a: 43, b: "hello"}` |
| `(TEST (oget o a) 43 43 43)` | `check: o.a ~is [43, 43, 43]` |

### `mut-vars`

| Parenthetical | Shrubbery |
|---|---|
| `[fun-calls +]` | `[fun-calls +]` |
| `begin` | `block` |
| `set!` | `:=` |

`begin` | `block` allows a sequence of expressions:

| Parenthetical | Shrubbery |
|---|---|
| `(begin <expr> …)` | `block:` followed by one `<expr>` per line, indented |

`set!` | `:=` changes the value of a variable:

| Parenthetical | Shrubbery |
|---|---|
| `(defvar v 3)` | `def v = 3` |
| `(set! v 4)` | `v := 4` |
| `(TEST v 4 4 4)` | `check: v ~is [4, 4, 4]` |

### `mut-structs`

| Parenthetical | Shrubbery |
|---|---|
| `[fields +]` | `[fields +]` |
| `oset` | `:=` on a field |

`oset` changes the value of a field. Its syntax is:

| Parenthetical | Shrubbery |
|---|---|
| `(oset <expr:obj-valued> <name:field> <expr:new-value>)` | `<expr:obj-valued>.<name:field> := <expr:new-value>` |

For instance:

| Parenthetical | Shrubbery |
|---|---|
| `(defvar o (object [a 43] [b "hello"]))` | `def o = {a: 43, b: "hello"}` |
| `(oset o a 17)` | `o.a := 17` |
| `(TEST (oget o a) 17 17 17)` | `check: o.a ~is [17, 17, 17]` |

### `eval-order`

| Parenthetical | Shrubbery |
|---|---|
| `[mut-vars +]` | `[mut-vars +]` |

No new constructs! Just new behavior…
