all: build

build:
	cat dependencies.coffee | coffee -cs > bin/node-dependencies
