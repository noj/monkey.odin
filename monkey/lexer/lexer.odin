package lexer

import "core:fmt"
import "core:strings"

// Location in source
Loc :: struct {
	line: int,
	col:  int,
}

// Token structs
Eof :: struct {}

Illegal :: struct {
	val: byte,
	loc: Loc,
}


Simple :: struct {
	val: enum u8 {
		ASSIGN    = '=',
		BANG      = '!',
		PLUS      = '+',
		MINUS     = '-',
		ASTERISK  = '*',
		SLASH     = '/',
		LT        = '<',
		GT        = '>',

		// Delimiters
		COMMA     = ',',
		SEMICOLON = ';',
		COLON     = ':',
		LPAREN    = '(',
		RPAREN    = ')',
		LBRACKET  = '[',
		RBRACKET  = ']',
		LBRACE    = '{',
		RBRACE    = '}',
	},
	loc: Loc,
}

String :: struct {
	literal: []byte,
	loc:     Loc,
}

Int :: struct {
	literal: i64,
	loc:     Loc,
}

Eq :: struct {
	loc: Loc,
}

NotEq :: struct {
	loc: Loc,
}

Let :: struct {
	log: Loc,
}

Ident :: struct {
	literal: []byte,
	loc:     Loc,
}


Keyword :: struct {
	name: enum u8 {
		Fun,
		Let,
		True,
		False,
		If,
		Else,
		Return,
	},
	loc:  Loc,
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

// Lexer
Lexer :: struct {
	input:    string,
	pos:      int,
	read_pos: int,
	ch:       u8,
	loc:      Loc,
}

new_lexer :: proc(text: string) -> Lexer {
	lexer := Lexer {
		input = text,
		pos = 0,
		read_pos = 0,
		ch = 0,
		loc = {line = 1, col = 1},
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
		lex.loc.col += 1
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
			read_char(lex)

		case '\t':
			read_char(lex)

		case '\n':
			fallthrough
		case '\r':
			read_char(lex)

			// Reset location:
			lex.loc.col = 1
			lex.loc.line += 1

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
	lit: i64
	for is_digit(lex.ch) {
		lit = 10 * lit + i64(lex.ch - u8('0'))
		read_char(lex)
	}

	return lit
}

next_token :: proc(lex: ^Lexer) -> Token {
	skip_whitespace(lex)

	loc := lex.loc

	tok: Token
	switch lex.ch {
	case '"':
		tok = String {
			literal = read_string(lex),
			loc     = loc,
		}

	case '=':
		if peek_char(lex) == '=' {
			read_char(lex)
			tok = Eq {
				loc = loc,
			}
		} else {
			tok = Simple {
				val = .ASSIGN,
				loc = loc,
			}
		}

	case '!':
		if peek_char(lex) == '=' {
			read_char(lex)
			tok = NotEq {
				loc = loc,
			}
		} else {
			tok = Simple {
				val = .BANG,
				loc = loc,
			}
		}

	case '(':
		tok = Simple {
			val = .LPAREN,
			loc = loc,
		}
	case ')':
		tok = Simple {
			val = .RPAREN,
			loc = loc,
		}
	case '[':
		tok = Simple {
			val = .LBRACKET,
			loc = loc,
		}
	case ']':
		tok = Simple {
			val = .RBRACKET,
			loc = loc,
		}
	case '{':
		tok = Simple {
			val = .LBRACE,
			loc = loc,
		}
	case '}':
		tok = Simple {
			val = .RBRACE,
			loc = loc,
		}

	case ':':
		tok = Simple {
			val = .COLON,
			loc = loc,
		}
	case '/':
		tok = Simple {
			val = .SLASH,
			loc = loc,
		}
	case '*':
		tok = Simple {
			val = .ASTERISK,
			loc = loc,
		}
	case '<':
		tok = Simple {
			val = .LT,
			loc = loc,
		}
	case '>':
		tok = Simple {
			val = .GT,
			loc = loc,
		}
	case ';':
		tok = Simple {
			val = .SEMICOLON,
			loc = loc,
		}
	case ',':
		tok = Simple {
			val = .COMMA,
			loc = loc,
		}
	case '+':
		tok = Simple {
			val = .PLUS,
			loc = loc,
		}
	case '-':
		tok = Simple {
			val = .MINUS,
			loc = loc,
		}

	case 0:
		tok = Eof{}

	case:
		if is_letter(lex.ch) {
			lit := read_identifier(lex)
			switch string(lit) {
			case "fn":
				return Keyword{name = .Fun, loc = loc}
			case "let":
				return Keyword{name = .Let, loc = loc}
			case "true":
				return Keyword{name = .True, loc = loc}
			case "false":
				return Keyword{name = .False, loc = loc}
			case "if":
				return Keyword{name = .If, loc = loc}
			case "else":
				return Keyword{name = .Else, loc = loc}
			case "return":
				return Keyword{name = .Return, loc = loc}
			case:
				tok = Ident {
					literal = lit,
					loc     = loc,
				}
			}
		} else if is_digit(lex.ch) {
			lit := read_number(lex)
			return Int{literal = lit, loc = loc}
		} else {
			tok = Illegal {
				val = lex.ch,
				loc = loc,
			}
		}
	}

	read_char(lex)

	return tok
}

read_identifier :: proc(lex: ^Lexer) -> []byte {
	pos := lex.pos
	for is_letter(lex.ch) {
		read_char(lex)
	}

	return transmute([]byte)lex.input[pos:lex.pos]
}

read_string :: proc(lex: ^Lexer) -> []byte {
	pos := lex.pos + 1

	for {
		read_char(lex)

		if lex.ch == '"' || lex.ch == 0 {
			break
		}
	}

	return transmute([]byte)lex.input[pos:lex.pos]
}

token_to_string :: proc(tok: Token) -> string {
	buf: strings.Builder

	switch t in tok {
	case Simple:
		fmt.sbprintf(&buf, "%d:%d: `%c`", t.loc.line, t.loc.col, u8(t.val))

	case String:
		fmt.sbprintf(&buf, "%d:%d: str \"%s\"", t.loc.line, t.loc.col, t.literal)

	case Int:
		fmt.sbprintf(&buf, "%d:%d: int \"%d\"", t.loc.line, t.loc.col, t.literal)

	case Eq:
		fmt.sbprintf(&buf, "%d:%d: eq", t.loc.line, t.loc.col)

	case NotEq:
		fmt.sbprintf(&buf, "%d:%d: noteq", t.loc.line, t.loc.col)

	case Keyword:
		fmt.sbprintf(&buf, "%d:%d: %s", t.loc.line, t.loc.col, to_string(t))

	case Ident:
		fmt.sbprintf(&buf, "%d:%d: ident \"%s\"", t.loc.line, t.loc.col, t.literal)

	case Illegal:
		fmt.sbprintf(&buf, "%d:%d: illegal \"%c\"", t.loc.line, t.loc.col, t.val)

	case Eof:
		fmt.sbprintf(&buf, "eof")
	}

	return strings.to_string(buf)
}

@(private)
keyword_to_string :: proc(k: Keyword) -> string {
	switch k.name {
	case .Fun:
		return "fun"

	case .Let:
		return "let"

	case .True:
		return "true"

	case .False:
		return "false"

	case .If:
		return "if"

	case .Else:
		return "else"

	case .Return:
		return "return"
	}

	return "unknown keyword"
}

// to_string overload
to_string :: proc {
	token_to_string,
	keyword_to_string,
}
