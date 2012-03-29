build:
	coffee -c -o lib src

test:
	@NODE_PATH=src expresso

.PHONY: test build
