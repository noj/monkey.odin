package main

import "core:fmt"
import "core:bufio"
import "core:os"
import "core:strings"
import "lexer"

lex_debug :: proc(str: string) {
    lex := lexer.new_lexer(str)

    for {
        tok := lexer.next_token(&lex)
        fmt.println(lexer.to_string(tok))

        #partial switch t in tok {
        case lexer.Eof:
            return
        }
    }
}

main :: proc() {
    r: bufio.Reader

    for {
        fmt.print(">> ")

        buffer: [1024]byte
        n, err := os.read(os.stdin, buffer[:])
        if err != nil {
            fmt.println("read error", err)
            continue
        }

        // EOF
        if n == 0 {
            return
        }

        line := strings.trim_space(string(buffer[:n]))
        lex_debug(line)
    }
}
