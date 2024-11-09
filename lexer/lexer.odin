package lexer

import "core:fmt"
import "core:strings"

Eof :: struct {}

Illegal :: struct {
    val: u8,
    loc: Loc,
}

SimpleVal :: enum u8 {
    ASSIGN = '=',
    BANG = '!',

    PLUS = '+',
    MINUS = '-',
    ASTERISK = '*',
    SLASH = '/',
    LT = '<',
    GT = '>',

    // Delimiters
    COMMA = ',',
    SEMICOLON = ';',
    COLON = ':',
    LPAREN = '(',
    RPAREN = ')',
    LBRACKET = '[',
    RBRACKET = ']',
    LBRACE = '{',
    RBRACE = '}',
}

Simple :: struct {
    val: SimpleVal
}

String :: struct {
    literal: string,
}

Int :: struct {
    literal: i64,
}

Eq :: struct {}

NotEq :: struct {}

Let :: struct {}

Ident :: struct {
    literal: string,
}

KeywordName :: enum u8 {
    Fun,
    Let,
    True,
    False,
    If,
    Else,
    Return,
}

Keyword :: struct {
    name: KeywordName
}

Token :: union {
    Simple,

    // Complex tokens
    Eq,
    NotEq,
    String,
    Int,
    Ident,
    Keyword,

    Illegal,
    Eof,
}

Loc :: struct {
    line: int,
    col: int
}

Lexer :: struct {
    input: string,
    pos: int,
    read_pos: int,
    ch: u8,

    // For error reporting:
    loc: Loc,
}

new_lexer :: proc(text: string) -> Lexer {
    lexer := Lexer {
        input = text,
        pos = 0,
        read_pos = 0,
        ch = 0,
        loc = {
            line = 1,
            col = 1,
        }
    }

    read_char(&lexer)
    return lexer
}

@(private)
read_char :: proc(lex: ^Lexer) {
    if lex.read_pos >= len(lex.input) {
        lex.ch = 0
    } else {
        lex.ch = lex.input[lex.read_pos]
    }

    lex.pos = lex.read_pos
    lex.read_pos += 1
}

@(private)
peek_char :: proc(lex: ^Lexer) -> u8 {
    if lex.read_pos >= len(lex.input) {
        return 0
    } else {
        return lex.input[lex.read_pos]
    }
}

@(private)
skip_whitespace :: proc(lex: ^Lexer) {
    for {
        switch lex.ch {
        case ' ':
            lex.loc.col += 1
            fallthrough

        case '\t':
            lex.loc.col += 1
            fallthrough

        case '\n':
            fallthrough

        case '\r':
            lex.loc.col = 1
            lex.loc.line += 1

            read_char(lex)

        case:
            return
        }
    }
}

is_digit :: proc(ch: u8) -> bool {
    return '0' <= ch && ch <= '9'
}

is_letter :: proc(ch: u8) -> bool {
    return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

read_number :: proc(lex: ^Lexer) -> i64 {
    pos := lex.pos

    lit: i64
    for is_digit(lex.ch) {
        lit = 10 * lit + i64(lex.ch - u8('0'))
        read_char(lex)
    }

    return lit
}

next_token :: proc(lex: ^Lexer) -> Token {
    skip_whitespace(lex)

    tok: Token
    switch lex.ch {
    case '"':
        tok = String{
            literal = read_string(lex)
        }

    case '=':
        if peek_char(lex) == '=' {
            read_char(lex)
            tok = Eq {}
        } else {
            tok = Simple { val = SimpleVal.ASSIGN }
        }

    case '!':
        if peek_char(lex) == '=' {
            read_char(lex)
            tok = NotEq {}
        } else {
            tok = Simple { val = SimpleVal.BANG }
        }

    case '(':
        tok = Simple { val = SimpleVal.LPAREN }
    case ')':
        tok = Simple { val = SimpleVal.RPAREN }
    case '[':
        tok = Simple { val = SimpleVal.LBRACKET }
    case ']':
        tok = Simple { val = SimpleVal.RBRACKET }
    case '{':
        tok = Simple { val = SimpleVal.LBRACE }
    case '}':
        tok = Simple { val = SimpleVal.RBRACE }

    case ':':
        tok = Simple { val = SimpleVal.COLON }
    case '/':
        tok = Simple { val = SimpleVal.SLASH }
    case '*':
        tok = Simple { val = SimpleVal.ASTERISK }
    case '<':
        tok = Simple { val = SimpleVal.LT }
    case '>':
        tok = Simple { val = SimpleVal.GT }
    case ';':
        tok = Simple { val = SimpleVal.SEMICOLON }
    case ',':
        tok = Simple { val = SimpleVal.COMMA }
    case '+':
        tok = Simple { val = SimpleVal.PLUS }
    case '-':
        tok = Simple { val = SimpleVal.MINUS }

    case 0:
        tok = Eof {}

    case:
        if is_letter(lex.ch) {
            lit := read_identifier(lex)
            switch lit {
            case "fn":
                return Keyword { name = KeywordName.Fun }
            case "let":
                return Keyword { name = KeywordName.Let }
            case "true":
                return Keyword { name = KeywordName.True }
            case "false":
                return Keyword { name = KeywordName.False }
            case "if":
                return Keyword { name = KeywordName.If }
            case "else":
                return Keyword { name = KeywordName.Else }
            case "return":
                return Keyword { name = KeywordName.Return }
            case:
                tok = Ident { literal = lit }
            }
        } else if is_digit(lex.ch) {
            lit := read_number(lex)
            return Int { literal = lit }
        } else {
            tok = Illegal { val = lex.ch, loc = lex.loc }
        }
    }

    read_char(lex)

    return tok
}

read_identifier :: proc(lex: ^Lexer) -> string {
    buf: strings.Builder

    pos := lex.pos
    for is_letter(lex.ch) {
        strings.write_byte(&buf, lex.ch)
        read_char(lex)
    }

    return strings.to_string(buf)
}

read_string :: proc(lex: ^Lexer) -> string {
    buf: strings.Builder

    pos := lex.pos + 1
    for {
        read_char(lex)

        if lex.ch == '"' || lex.ch == 0 {
            break
        }

        strings.write_byte(&buf, lex.ch)
    }

    return strings.to_string(buf)
}

// Overloaded in to_string
@(private)
token_to_string :: proc(tok: Token) -> string {
    buf: strings.Builder

    switch t in tok {
    case Simple:
        fmt.sbprintf(&buf, "`%c`", u8(t.val))

    case String:
        fmt.sbprintf(&buf, "str \"%s\"", t.literal)

    case Int:
        fmt.sbprintf(&buf, "int \"%d\"", t.literal)

    case Eq:
        return "eq"

    case NotEq:
        return "eq"

    case Keyword:
        return to_string(t)

    case Ident:
        fmt.sbprintf(&buf, "ident \"%s\"", t.literal)

    case Illegal:
        fmt.sbprintf(&buf, "%d:%d: illegal \"%c\"", t.loc.line, t.loc.col, t.val)

    case Eof:
        return "eof"
    }

    return strings.to_string(buf)
}

@(private)
keyword_to_string :: proc(k: Keyword) -> string {
    switch k.name {
    case KeywordName.Fun:
        return "fun"

    case KeywordName.Let:
        return "let"

    case KeywordName.True:
        return "true"

    case KeywordName.False:
        return "false"

    case KeywordName.If:
        return "if"

    case KeywordName.Else:
        return "else"

    case KeywordName.Return:
        return "return"
    }

    return "unknown keyword"
}

// to_string overload
to_string :: proc{token_to_string, keyword_to_string}
