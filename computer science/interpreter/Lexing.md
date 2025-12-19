
## Lexical Analysis

* In order for us to work with source code we need to turn it into a more accessible form. As easy as plain text is to work with in our editor.
	![[Pasted image 20251217153349.png]]
* The first transformation, from source code to tokens, is called “lexical analysis”, or “lexing” for short. Tokens itself are small, easily categorizable data structures that are then fed to the parser, which
does the second transformation and turns the tokens into an “Abstract Syntax Tree”.

Lexer input:
```
"let x = 5 + 5;"
```

Lexer output / Tokens:
```go
[
LET,
IDENTIFIER("x"),
EQUAL_SIGN,
INTEGER(5),
PLUS_SIGN,
INTEGER(5),
SEMICOLON
]
```
* also have the concrete values they represent attached: 5 (not "5"!) in the case of INTEGER and "x" in the case of IDENTIFIER.*
* A thing to note about this example: whitespace characters don’t show up as tokens.


## Defining tokens

Token data structure:
```go
package token

type TokenType string

type Token struct {
	Type TokenType
	Literal string 
}
```

* We’ll also make life simpler here by using string as the type for our source code. Again: in a production environment it makes sense to attach filenames and line numbers to tokens, to better track down lexing and parsing errors. So it would be better to initialize the lexer with an `io.Reader` and the filename.