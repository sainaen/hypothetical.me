.PHONY: all clean build run run_pub

all: build

clean:
	@rm -rf public

build: clean
	HUGO_MODE=prod hugo -v

run: clean
	hugo serve -v

run_pub: clean
	sudo ~/.local/bin/hugo serve -v \
		--port 80 \
		--bind '0.0.0.0' \
		--baseURL 'hme.lan'

