.PHONY: run build test

FLAGS=-debug -sanitize:address -lld

test:
	@odin test monkey -all-packages

build:
	@odin build monkey ${FLAGS} -vet -show-timings

run:
	@odin run monkey ${FLAGS}
