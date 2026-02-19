# Reference Imagery

This folder is for local reference stills and videos used during development and testing.

## What Goes Here

- Test captures from cameras, dashcams, or phones
- Reference stills for annotation or comparison
- Temporary reference imagery (not committed to git)

## What Stays Out

Images and videos in this folder are **gitignored by default**. Do not commit actual image/video files.

Only commit:
- This README
- Metadata or notes about sources (in markdown)
- Lightweight reference lists

## Example Workflow

1. Capture a test video: `gopro_test_180419.mp4`
2. Save it here: `inputs/reference/gopro_test_180419.mp4`
3. Git ignores it automatically
4. Reference it in your scripts or docs (but it won't be in the repo)

---

_Keep the actual imagery local; git stays clean._
