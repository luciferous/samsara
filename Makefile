build:
	coffee -c -o lib src

test:
	@NODE_PATH=src expresso
	node_modules/coffee-script/bin/coffee poormanstest.coffee

.PHONY: test build
