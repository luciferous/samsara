#!/bin/sh
curl --silent \
     --data-urlencode js_code@- \
     --data output_info=compiled_code \
     closure-compiler.appspot.com/compile
