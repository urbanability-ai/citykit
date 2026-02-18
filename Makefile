SHELL := /usr/bin/env bash

RUN_ID ?= $(shell date -u +"%Y-%m-%dT%H%M%SZ")
ART_DIR := artifacts/$(RUN_ID)

# Map mode:
# - stub (default): uses inputs/zone.geojson polygon as map.geojson
# - osm: fetches OSM highways within bbox via Overpass and writes LineString GeoJSON
MAP_MODE ?= stub
OVERPASS_ENDPOINT ?= https://overpass-api.de/api/interpreter

.PHONY: help demo smoke inspect clean

help:
	@echo "Targets:"
	@echo " make demo RUN_ID=... MAP_MODE=stub|osm"
	@echo " make inspect"
	@echo " make smoke"
	@echo " make clean"
	@echo ""
	@echo "Vars:"
	@echo " MAP_MODE=stub|osm"
	@echo " OVERPASS_ENDPOINT=$(OVERPASS_ENDPOINT)"

smoke:
	@command -v python3 >/dev/null || (echo "Missing python3" && exit 1)
	@echo "OK: python3 present"
	@echo "Optional: zip for packaging"
	@echo "Optional: ffmpeg for placeholder mp4"

demo:
	@mkdir -p "$(ART_DIR)"
	@RUN_ID="$(RUN_ID)" MAP_MODE="$(MAP_MODE)" OVERPASS_ENDPOINT="$(OVERPASS_ENDPOINT)" ./scripts/demo.sh

inspect:
	@./scripts/inspect_latest.sh

clean:
	rm -rf artifacts/*
