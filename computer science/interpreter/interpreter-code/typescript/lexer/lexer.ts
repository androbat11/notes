// `position` and `readPosition`. Both will be used to access characters in input by
// using them as an index.
// Basically, position
//  and readPosition are pointers.

// ReadPosition => Always points to the next character
// Position => Points to the character and the readPosiiton is just the
// position where the character was read.
type Lexer = {
    input: string
    position: number
    readPosition: number
    character: string
}

// Not pretty sure if that's the right interchange btw languages
function createNewToken(input: string): Lexer {
    const lexer: Lexer = {
        input,
        position: 0,
        readPosition: 0,
        character: "",
    };
    readCharacter(lexer); // Read the first character to initialize properly
    return lexer;
}

function readCharacter(lexer: Lexer): void {
    const isSourceBiggerThanPosition = lexer.readPosition >= lexer.input.length;
    if (isSourceBiggerThanPosition){
        lexer.character = "";
    } else {
        // Remove <!> and find a way to validate it since,
        // not handling error.
        lexer.character = lexer.input[lexer.readPosition]!;
    }
    lexer.position = lexer.readPosition;
    lexer.readPosition += 1; // Move to the next character for future reads
}
