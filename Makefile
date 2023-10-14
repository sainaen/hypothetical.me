.PHONY: all clean build run run_pub deploy diff

all: build

clean:
	@rm -rf public

build: clean
	HUGO_MODE=prod hugo --logLevel info --cleanDestinationDir

run: clean
	hugo server --logLevel info \
		--buildDrafts \
		--buildFuture

run_pub: clean
	sudo $(command -v hugo) server --logLevel info \
		--watch \
		--buildFuture \
		--buildDrafts \
		--port 80 \
		--bind '0.0.0.0' \
		--baseURL 'hme.lan'

deploy: build
	aws s3 sync \
		--profile static_sites \
		--size-only \
		public/ \
		s3://hypothetical.me/

diff: build
	aws s3 sync \
		--profile static_sites \
		--size-only \
		s3://hypothetical.me/ \
		production/
	diff --minimal --color=always --recursive production public || true
