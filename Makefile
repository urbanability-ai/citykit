SHELL := /usr/bin/env bash
RUN_ID ?= $(shell date -u +"%Y-%m-%dT%H%M%SZ")
ART_DIR := artifacts/$(RUN_ID)

.PHONY: help demo smoke inspect clean

help:
	@echo "Targets:"
	@echo " make demo RUN_ID=... # build a city demo kit zip into artifacts/<run_id>/"
	@echo " make smoke # quick sanity checks"
	@echo " make inspect # inspect the latest demo kit"
	@echo " make clean # remove artifacts"

smoke:
	@command -v python3 >/dev/null || (echo "Missing python3" && exit 1)
	@command -v zip >/dev/null || (echo "Missing zip (apt-get install zip)" && exit 1)
	@echo "OK: python3 + zip present"
	@echo "Optional: ffmpeg for placeholder mp4"

demo:
	@mkdir -p "$(ART_DIR)"
	@RUN_ID="$(RUN_ID)" ./scripts/demo.sh

inspect:
	@./scripts/inspect_latest.sh

clean:
	rm -rf artifacts/*
