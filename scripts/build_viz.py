#!/usr/bin/env python3
"""
scripts/build_viz.py — Stdlib-only Leaflet viewer builder

Writes a single-file HTML viewer into <KIT_DIR>/viz/overview.html
Modes:
- default: loads GeoJSON via fetch("../derived/osm_*.geojson")
- --embed: embeds GeoJSON inline (file:// compatible)
"""

import argparse
import os
import json
from datetime import datetime, timezone

HTML_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>City Demo Kit — Overview</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
  <style>
    body {{
      margin: 0;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;
    }}
    #map {{
      height: 100vh;
      width: 100vw;
    }}
    .panel {{
      position: absolute;
      top: 12px;
      left: 12px;
      z-index: 1000;
      background: rgba(255,255,255,0.95);
      padding: 10px 12px;
      border-radius: 10px;
      box-shadow: 0 6px 20px rgba(0,0,0,0.12);
      max-width: 340px;
    }}
    .panel h1 {{
      font-size: 14px;
      margin: 0 0 6px 0;
    }}
    .panel .meta {{
      font-size: 12px;
      color: #444;
      margin-bottom: 8px;
    }}
    .panel label {{
      display: block;
      font-size: 13px;
      margin: 6px 0;
    }}
    .legend {{
      font-size: 12px;
      margin-top: 8px;
      color: #333;
    }}
    .swatch {{
      display:inline-block;
      width:10px;
      height:10px;
      margin-right:6px;
      border-radius:2px;
      vertical-align:middle;
    }}
    .warn {{
      font-size: 12px;
      color: #a00;
      margin-top: 8px;
      white-space: pre-wrap;
    }}
    a {{
      color: #0a58ca;
      text-decoration: none;
    }}
  </style>
</head>
<body>
  <div id="map"></div>
  <div class="panel">
    <h1>City Demo Kit — Overview</h1>
    <div class="meta">
      run_id: <code>{run_id}</code><br/>
      generated: {generated_at}<br/>
      viewer mode: <code>{viewer_mode}</code>
    </div>
    <label><input type="checkbox" id="toggleBaseline" checked> Baseline (OSM)</label>
    <label><input type="checkbox" id="toggleModified" checked> Modified (delta applied)</label>
    <label><input type="checkbox" id="toggleOverlays" checked> Overlays (geofence/curb zones)</label>
    <div class="legend">
      <div><span class="swatch" style="background:#666"></span> baseline ways</div>
      <div><span class="swatch" style="background:#0a58ca"></span> modified ways</div>
      <div><span class="swatch" style="background:#f59e0b"></span> curb_zone overlay</div>
      <div><span class="swatch" style="background:#16a34a"></span> geofence overlay</div>
      <div style="margin-top:6px;color:#666">
        Speed limits (if present) are shown as thicker lines on modified layer.
      </div>
    </div>
    <div id="warn" class="warn" style="display:none;"></div>
  </div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin="" ></script>
  <script>
    // Marker strings used by inspect tooling:
    // __BASELINE_GEOJSON, __MODIFIED_GEOJSON, __VIEWER_MODE
    const VIEWER_MODE = "{viewer_mode}";
    const BASELINE_URL = "../derived/osm_baseline.geojson";
    const MODIFIED_URL = "../derived/osm_modified.geojson";

    // Embedded data (present when VIEWER_MODE === "embedded")
    window.__BASELINE_GEOJSON = {baseline_embedded};
    window.__MODIFIED_GEOJSON = {modified_embedded};

    const map = L.map("map", {{ zoomControl: true }});

    L.tileLayer("https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png", {{
      maxZoom: 20,
      attribution: '&copy; OpenStreetMap contributors'
    }}).addTo(map);

    const warnEl = document.getElementById("warn");

    function warn(msg) {{
      warnEl.style.display = "block";
      warnEl.textContent = msg;
    }}

    function styleBaseline(feature) {{
      return {{ color: "#666", weight: 2, opacity: 0.9 }};
    }}

    function styleModified(feature) {{
      const p = feature.properties || {{}};
      const hasSpeed = (p.maxspeed_kph !== undefined && p.maxspeed_kph !== null);
      return {{ color: "#0a58ca", weight: hasSpeed ? 5 : 3, opacity: 0.9 }};
    }}

    function styleOverlay(feature) {{
      const p = feature.properties || {{}};
      const ft = p.feature_type || "";
      if (ft === "curb_zone") {{
        return {{ color: "#f59e0b", weight: 2, fillColor: "#f59e0b", fillOpacity: 0.25 }};
      }}
      if (ft === "geofence") {{
        return {{ color: "#16a34a", weight: 2, fillColor: "#16a34a", fillOpacity: 0.12 }};
      }}
      return {{ color: "#999", weight: 2, fillOpacity: 0.1 }};
    }}

    function onEachFeature(feature, layer) {{
      const p = feature.properties || {{}};
      const lines = [];
      if (p.osm_id !== undefined) lines.push(`osm_id: ${{p.osm_id}}`);
      if (p.highway) lines.push(`highway: ${{p.highway}}`);
      if (p.maxspeed_kph !== undefined) lines.push(`maxspeed_kph: ${{p.maxspeed_kph}}`);
      if (p.feature_type) lines.push(`feature_type: ${{p.feature_type}}`);
      if (p.zone_type) lines.push(`zone_type: ${{p.zone_type}}`);
      if (p.allowed_hours) lines.push(`allowed_hours: ${{p.allowed_hours}}`);
      if (p.hours) lines.push(`hours: ${{p.hours}}`);
      if (lines.length) layer.bindPopup(lines.join("<br/>"));
    }}

    let baselineLayer = null;
    let modifiedLayer = null;
    let overlayLayer = null;

    async function loadGeoJSON(url, styleFn) {{
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`Failed to load ${{url}} (${{resp.status}})`);
      const data = await resp.json();
      return L.geoJSON(data, {{ style: styleFn, onEachFeature }});
    }}

    function loadEmbedded(data, styleFn) {{
      return L.geoJSON(data, {{ style: styleFn, onEachFeature }});
    }}

    function fitToLayers(layers) {{
      const group = L.featureGroup(layers.filter(Boolean));
      if (group.getLayers().length) {{
        map.fitBounds(group.getBounds().pad(0.08));
      }} else {{
        map.setView([52.5200, 13.4050], 16);
      }}
    }}

    function splitOverlaysFromModified(layer) {{
      const overlays = [];
      const main = [];
      layer.eachLayer(l => {{
        const f = l.feature || {{}};
        const p = f.properties || {{}};
        if (p.feature_type) overlays.push(f);
        else main.push(f);
      }});
      return {{ overlays, main }};
    }}

    async function init() {{
      try {{
        if (VIEWER_MODE === "embedded") {{
          if (window.__BASELINE_GEOJSON) {{
            baselineLayer = loadEmbedded(window.__BASELINE_GEOJSON, styleBaseline).addTo(map);
          }} else {{
            warn("Baseline not embedded.");
          }}

          if (window.__MODIFIED_GEOJSON) {{
            const tmp = loadEmbedded(window.__MODIFIED_GEOJSON, styleModified);
            const parts = splitOverlaysFromModified(tmp);
            if (parts.main.length) {{
              modifiedLayer = L.geoJSON({{type:"FeatureCollection", features: parts.main}}, {{
                style: styleModified,
                onEachFeature
              }}).addTo(map);
            }}
            if (parts.overlays.length) {{
              overlayLayer = L.geoJSON({{type:"FeatureCollection", features: parts.overlays}}, {{
                style: styleOverlay,
                onEachFeature
              }}).addTo(map);
            }}
          }} else {{
            warn("Modified not embedded.");
          }}
        }} else {{
          // fetch mode (older behavior)
          try {{
            baselineLayer = await loadGeoJSON(BASELINE_URL, styleBaseline);
            baselineLayer.addTo(map);
          }} catch (e) {{
            warn(`Baseline not available: ${{e.message}}`);
          }}

          try {{
            let tmp = await loadGeoJSON(MODIFIED_URL, styleModified);
            const parts = splitOverlaysFromModified(tmp);
            if (parts.main.length) {{
              modifiedLayer = L.geoJSON({{type:"FeatureCollection", features: parts.main}}, {{
                style: styleModified,
                onEachFeature
              }}).addTo(map);
            }}
            if (parts.overlays.length) {{
              overlayLayer = L.geoJSON({{type:"FeatureCollection", features: parts.overlays}}, {{
                style: styleOverlay,
                onEachFeature
              }}).addTo(map);
            }}
          }} catch (e) {{
            warn(`Modified not available: ${{e.message}}`);
          }}
        }}
      }} catch (e) {{
        warn(`Viewer init error: ${{e.message}}`);
      }}

      fitToLayers([baselineLayer, modifiedLayer, overlayLayer]);

      // Toggles
      const tb = document.getElementById("toggleBaseline");
      const tm = document.getElementById("toggleModified");
      const to = document.getElementById("toggleOverlays");

      tb.addEventListener("change", () => {{
        if (!baselineLayer) return;
        if (tb.checked) baselineLayer.addTo(map);
        else map.removeLayer(baselineLayer);
      }});

      tm.addEventListener("change", () => {{
        if (!modifiedLayer) return;
        if (tm.checked) modifiedLayer.addTo(map);
        else map.removeLayer(modifiedLayer);
      }});

      to.addEventListener("change", () => {{
        if (!overlayLayer) return;
        if (to.checked) overlayLayer.addTo(map);
        else map.removeLayer(overlayLayer);
      }});
    }}

    init();
  </script>
</body>
</html>"""


def _read_geojson_if_exists(path: str):
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    ap = argparse.ArgumentParser(description="Build Leaflet viewer for demo kit")
    ap.add_argument("--kit", required=True, help="Path to city_demo_kit directory (inside artifacts/run_id)")
    ap.add_argument("--run-id", default="", help="Optional run_id for display")
    ap.add_argument("--embed", action="store_true", help="Embed GeoJSON inline (file:// compatible)")
    args = ap.parse_args()

    kit_dir = args.kit
    os.makedirs(os.path.join(kit_dir, "viz"), exist_ok=True)

    run_id = args.run_id.strip()

    # Try to pull run_id from scenario.json if not provided
    scenario_path = os.path.join(kit_dir, "scenario.json")
    if not run_id and os.path.exists(scenario_path):
        try:
            with open(scenario_path, "r", encoding="utf-8") as f:
                scenario = json.load(f)
                run_id = scenario.get("run_id", "")
        except Exception:
            run_id = ""

    if not run_id:
        run_id = "(unknown)"

    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    viewer_mode = "embedded" if args.embed else "fetch"
    baseline_embedded = "null"
    modified_embedded = "null"

    if args.embed:
        baseline_path = os.path.join(kit_dir, "derived", "osm_baseline.geojson")
        modified_path = os.path.join(kit_dir, "derived", "osm_modified.geojson")
        baseline = _read_geojson_if_exists(baseline_path)
        modified = _read_geojson_if_exists(modified_path)
        baseline_embedded = json.dumps(baseline) if baseline is not None else "null"
        modified_embedded = json.dumps(modified) if modified is not None else "null"

    html = HTML_TEMPLATE.format(
        run_id=run_id,
        generated_at=generated_at,
        viewer_mode=viewer_mode,
        baseline_embedded=baseline_embedded,
        modified_embedded=modified_embedded,
    )

    out_path = os.path.join(kit_dir, "viz", "overview.html")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html)

    print(f"✅ build_viz: wrote viewer to {out_path} (mode={viewer_mode})")


if __name__ == "__main__":
    main()
