SHELL := /usr/bin/env bash

RUN_ID ?= $(shell date -u +"%Y-%m-%dT%H%M%SZ")
ART_DIR := artifacts/$(RUN_ID)

# Map mode:
# - stub (default): uses inputs/zone.geojson polygon as map.geojson
# - osm: fetches OSM highways within bbox via Overpass and writes LineString GeoJSON
MAP_MODE ?= stub
OVERPASS_ENDPOINT ?= https://overpass-api.de/api/interpreter

.PHONY: help demo smoke inspect compare clean

help:
	@echo "Targets:"
	@echo " make demo RUN_ID=... MAP_MODE=stub|osm"
	@echo " make inspect (inspect latest artifact)"
	@echo " make compare (stub vs osm summary)"
	@echo " make smoke (sanity check)"
	@echo " make clean"
	@echo ""
	@echo "Vars:"
	@echo " MAP_MODE=stub|osm"
	@echo " OVERPASS_ENDPOINT=$(OVERPASS_ENDPOINT)"

smoke:
	@command -v python3 >/dev/null || (echo "Missing python3" && exit 1)
	@echo "OK: python3 present"
	@if command -v zip >/dev/null; then echo "OK: zip present (optional)"; else echo "NOTE: zip missing — Python zipfile fallback will be used"; fi
	@echo "Optional: ffmpeg for placeholder mp4"
	@echo "Optional: internet access when MAP_MODE=osm"

demo:
	@mkdir -p "$(ART_DIR)"
	@RUN_ID="$(RUN_ID)" MAP_MODE="$(MAP_MODE)" OVERPASS_ENDPOINT="$(OVERPASS_ENDPOINT)" ./scripts/demo.sh

inspect:
	@./scripts/inspect_latest.sh

compare:
	@./scripts/compare.sh

clean:
	rm -rf artifacts/*
