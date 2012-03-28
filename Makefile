build:
	coffee -c -o lib src

test:
	@NODE_PATH=src coffee ./test/test.coffee

.PHONY: test build
