package lexer

import (
	"testing"
	"/lexer/token"	
)

func TestTextToken(t *testing.T){
	input := `=+(){},;`

	tests := []struct {
		expectedType Token.TokenType
		expectedLiteral string
	} {
		{token.ASSIGN, "="},
		{token.PLUS, "+"},
		{token.LPAREN, "("},
		{token.RPAREN, ")"},
		{token.LBRACE, "{"},
		{token.RBRACE, "}"},
		{token.COMMA, ","},
		{token.SEMICOLON, ";"},
		{token.EOF, ""},
	}
	
	l := New(input)
	}

	for i, tt := range tests {
		tok := l.NextToken()

		if tok.Type !
	}

}