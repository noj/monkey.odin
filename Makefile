.PHONY: run build

FLAGS=-debug -sanitize:address

run:
	@odin run monkey ${FLAGS}

build:
	@odin build monkey ${FLAGS}
