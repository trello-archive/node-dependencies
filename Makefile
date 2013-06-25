all: build

build:
	echo "#!/usr/bin/env node" > bin/node-dependencies
	cat dependencies.coffee | coffee -cs >> bin/node-dependencies
	chmod +x bin/node-dependencies
