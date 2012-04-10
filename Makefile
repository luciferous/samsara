GAEDIR=$(HOME)/lib/google_appengine/1.6.4

dist: dist/samsara.js dist/samsara.min.js

dist/samsara.js: lib
	mkdir -p dist
	node_modules/browserify/bin/cli.js lib/samsara.js -v -o dist/samsara.js

dist/samsara.min.js: dist/samsara.js
	mkdir -p dist
	bin/closure-compile.sh < dist/samsara.js > dist/samsara.min.js

lib: src/*
	node_modules/coffee-script/bin/coffee -c -o lib src
	touch lib

cdn: dist
	$(GAEDIR)/appcfg.py update .

test: lib
	@NODE_PATH=lib expresso
	node_modules/coffee-script/bin/coffee poormanstest.coffee

.PHONY: test
