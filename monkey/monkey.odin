package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "lexer"

lex_debug :: proc(str: string) {
	lex := lexer.new_lexer(str)

	for {
		tok := lexer.next_token(&lex)
		tok_str := lexer.token_to_string(tok)
		defer delete(tok_str)

		fmt.println(tok_str)

		#partial switch t in tok {
		case lexer.Eof:
			return
		}
	}
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	for {
		fmt.print(">> ")

		// FIXME: >1024 character input
		buffer: [1024]byte
		n, err := os.read(os.stdin, buffer[:])
		if err != nil {
			fmt.eprintln("read error", err)
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
