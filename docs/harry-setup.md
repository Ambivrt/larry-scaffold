# Harry Setup — Audio, Speech and Music

Harry is Larry's audio agent. Text-to-speech via Gemini TTS, music generation via Venice, SFX via Venice, mixing via FFmpeg.

---

## Quick Start

```bash
# Dry run — show segments without generating
python 03-projects/harry/harry-tts.py "path/to/file.md" --dry

# Generate TTS
python 03-projects/harry/harry-tts.py "path/to/file.md"

# With speed override
python 03-projects/harry/harry-tts.py "file.md" --speed 0.9

# With voice override (all segments same voice)
python 03-projects/harry/harry-tts.py "file.md" --voice Erinome
```

---

## Architecture

```
User → Larry → harry-tts.py "file.md"
  → parse_voice_markup() → segment per ::voice[name]
  → Gemini TTS API (Vertex AI, GCP project: {{GCP_PROJECT}})
  → PCM data (24kHz, 16-bit, mono) per segment
  → concat_wav_segments() → combined WAV
  → FFmpeg: atempo (speed adjustment) + libmp3lame → MP3 192kbps
  → Saved to {{AUDIO_PATH}}/01-tts/{file.stem}.mp3
  → log_cost() → cost-log.csv
```

---

## Voice Markup

Harry reads markdown files with `::voice[name]` markup:

```markdown
::voice[narrator]
The narrator describes the scene.

::voice[main]
The main character speaks.

::voice[female]
The female character responds.
```

Text without markup is treated as narrator voice.
Frontmatter and markdown headers (`#`) are removed automatically.

---

## Voice Library (Gemini TTS)

Define your own voice map in `harry-tts.py`. Example configuration:

```python
VOICE_MAP = {
    # Male voices
    "main":       "Iapetus",    # Deep, intimate
    "other_male": "Enceladus",  # Dark, calm
    "alt_male":   "Sadaltager", # Calm, low

    # Female voices
    "female":     "Erinome",    # Soft, warm — narrator favorite
    "young_f":    "Zephyr",     # Light, youthful
    "alt_female": "Aoede",      # Warm

    # Narrator
    "narrator":   "Erinome",    # Soft, warm
    "berattare":  "Erinome",
}

DEFAULT_VOICE = "Iapetus"
DEFAULT_SPEED = 0.95
```

**Recommendation:** Test all available Gemini TTS voices and pick 3-5 that work well for your use case.

---

## TTS Model Configuration

```python
TTS_MODEL = "gemini-2.5-flash-preview-tts"
GCP_PROJECT = "{{GCP_PROJECT}}"
GCP_LOCATION = "us-central1"
```

Authentication: `google-auth` Application Default Credentials (Vertex AI).

**Setup:**
```bash
gcloud auth application-default login
gcloud config set project {{GCP_PROJECT}}
```

---

## FFmpeg

Install FFmpeg and set the path in `harry-tts.py`:

```python
ffmpeg = "ffmpeg"  # or full path, e.g. "/usr/bin/ffmpeg"
```

Used for:
- Speed adjustment (`atempo`)
- WAV → MP3 conversion (libmp3lame, 192kbps)
- Mixing: panning, reverb (aecho), volume levels

---

## File Structure

```
{{AUDIO_PATH}}/
├── 01-tts/       ← Text-to-speech output
├── music/        ← Generated music (Venice MiniMax/ACE-Step)
├── sfx/          ← Sound effects (Venice MMAudio v2)
└── .trash/       ← Trash (30-day retention)
```

---

## Music (Venice)

| Type | Model | Cost | Control |
|------|-------|------|---------|
| Music | MiniMax v2 | ~$0.03/gen | Style, tempo, instruments |
| Music | ACE-Step | ~$0.04/gen | Advanced composition |
| SFX | MMAudio v2 | ~$0.01/gen | Environmental sounds, short duration |

---

## TTS Style Guidelines

- Minimal prosody tweaking — write like a radio drama script, not prose
- Natural pause cues through sentence structure
- Each `::voice[name]` block = one segment = one API call → concatenated
- Keep segments reasonably short for natural-sounding output

---

## Backup

| Layer | Source | Destination | Frequency |
|-------|--------|-------------|-----------|
| NAS | `{{AUDIO_PATH}}/` | `{{NAS_PATH}}/audio` | Every 6h (robocopy /MIR) |

---

## Cost Logging

```python
log_cost(file_stem, TTS_MODEL, "audio", privacy_level, "harry",
         total_chars, "characters", 0.0)
```

Gemini TTS Vertex AI is free/token-based — `cost_usd` logged as 0.0.

---

## Status

- [x] Gemini TTS (harry-tts.py) — live
- [x] Venice music/SFX — available via Playwright
- [x] FFmpeg mixing — live
- [ ] STT (speech-to-text) — not implemented
- [ ] Automatic Suno integration — planned
