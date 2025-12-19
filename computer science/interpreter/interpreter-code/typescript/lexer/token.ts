// ILLEGAL => we don't know about that token...
// EOF => end of file

export enum TokenType {
    Illegal = "ILLEGAL",
    Eof = "EOF",
    // Identifiers + literals
    Indent = "IDENT",
    Int = "INT",
    // Operators
    Assign = "=",
    Plus = "+",
    // Delimiters
    Comma = ",",
    Semicolon = ";",
    // Delimiters
    LParen = "(",
    RParen = ")",
    LBrace = "{",
    RBrace = "}",
    // Keywords
    Function = "FUNCTION",
    Let = "LET",
}

export type Token = {
    type: TokenType;
    literal: string;
};
