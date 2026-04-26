# Barry Setup — Image Generation and Visual Memory

Barry is Larry's image agent. Generates images via Venice Chat (Playwright), sorts and indexes visual material.

---

## Quick Start

```bash
# Generate image (default: Chroma, 1:1, 2x upscale)
python 03-projects/barry/barry.py "description of image"

# Quick draft (no upscale)
python 03-projects/barry/barry.py "description" --upscale 0

# Max quality
python 03-projects/barry/barry.py "description" --upscale 4

# Sort inbox
python 03-projects/barry/barry-sort.py

# Via skill
/barry-generate
```

---

## Architecture

```
User → Larry → barry.py (CLI wrapper)
  → Playwright opens Venice Chat (browser, persistent profile)
  → Prompt optimized and sent in Venice UI
  → Image generated (Chroma model, free tier)
  → Visual QA (Playwright snapshot → vision review)
    ↳ If QA fail: auto-regenerate without asking
  → Download to {{ASSETS_PATH}}/00-inbox/
  → Post-process: move, metadata, upscale
  → Backup to NAS
```

---

## File Structure

```
{{ASSETS_PATH}}/
├── venice/                 ← AI-generated images (Venice Chat)
│   ├── nsfw/               ← Privacy 3-4
│   │   ├── solo-f/
│   │   ├── solo-m/
│   │   ├── couple-mf/
│   │   ├── couple-mm/
│   │   ├── couple-ff/
│   │   ├── group-mf/
│   │   ├── toys/
│   │   └── other/
│   └── sfw/                ← Privacy 2
│       ├── portrait/
│       ├── landscape/
│       └── concept/
├── import/                 ← Imported images (photos, downloads)
│   └── [same category tree]
├── 00-inbox/               ← Drop zone — unsorted images
├── .counter                ← Global counter (next available number)
└── .trash/                 ← Trash (30-day retention)
```

Vault index (metadata notes): `03-projects/barry/visual-index/` — never image files in vault.

---

## Naming Convention

```
barry-NNNNN.{ext}
```

- 5-digit global counter: `00001`–`99999`
- Never a collision — one number per image in the entire system
- Counter stored in `{{ASSETS_PATH}}/.counter`
- Extension preserved (.png for generated, .jpg/.jpeg for imports)
- Folder determines category — not filename

---

## Model

**Default: Chroma** (free, Venice Chat UI)

- Adherence: **always 3** — never change this
- No anonymous models (cost credits, avoid)
- Venice Chat UI via Playwright — never direct API

---

## Upscale

| Flag | Behavior |
|------|---------|
| `--upscale 0` | No upscale (quick/draft/test) |
| `--upscale 2` | Default |
| `--upscale 4` | Max quality (poster/print) |

**Rule:** Upscale ONLY if user explicitly requests it. No automatic upscale.

Filename suffix: `-2x` or `-4x`. Original (1x) deleted after upscale.

Engine: Venice UI upscale (free for Pro) via Playwright. API upscale only if explicitly requested (costs credits). Settings: creativity 0.20, replication 0.70.

---

## QA Flow

1. Image generated in Venice Chat
2. Playwright takes snapshot
3. Visual review: fingers, anatomy, composition
4. On fail: auto-regenerate immediately without asking
5. On pass: proceed with download and post-processing

---

## Venice Chat Settings

Always verify BEFORE generating:
- Variants: per request
- Aspect ratio: per request (default 1:1)
- Adherence: **3** (never change)
- Model: Chroma (default)

---

## ComfyUI / SDXL — Local Generation Alternative

ComfyUI with SDXL checkpoints provides local GPU-based image generation. Complements Venice/Chroma -- does not replace it. Main advantage: reference-based generation (IP-Adapter, FaceID) and pose control (ControlNet) that cloud services cannot offer.

### When to Use ComfyUI vs Venice

| | SDXL (ComfyUI, local) | Chroma (Venice, cloud) |
|---|---|---|
| Architecture | SDXL 1.0 (6.6B params) | FLUX-based (8.9B params) |
| Prompt style | Tags + natural language, mixed | Natural language only |
| Negative prompt | Yes, important | No |
| Prompt adherence | Good, but Chroma better on complex scenes | Superior |
| Anatomical quality | Good with right checkpoint, needs more guidance | Better out-of-box |
| Speed | 30-60s local (8GB VRAM) | 10-15s (cloud) |
| Cost | Free (local GPU) | Free (Venice tier) |
| IP-Adapter / FaceID | Yes | No |
| ControlNet (pose) | Yes | No |
| Ecosystem | Thousands of checkpoints and LoRAs | Single model |

**Rule of thumb:** Chroma for free-form text-to-image. SDXL for reference-based generation (IP-Adapter, FaceID), pose control (ControlNet), and when community checkpoints provide a quality edge.

### Installation

1. Clone ComfyUI into the local repo directory:
   ```bash
   cd {{GIT_REPO_PATH}}
   git clone https://github.com/comfyanonymous/ComfyUI.git
   cd ComfyUI
   pip install -r requirements.txt
   ```

2. Download SDXL base model:
   - `sd_xl_base_1.0_0.9vae.safetensors` into `models/checkpoints/`
   - Or use community SDXL checkpoints (e.g., RealVisXL Lightning, Juggernaut XL)

3. Install custom nodes (as needed):
   - **ComfyUI-Manager** -- node browser and installer
   - **IP-Adapter Plus** -- reference-based generation
   - **FaceID** -- face consistency across a series (requires InsightFace)
   - **ControlNet** -- pose, depth, canny edge control

4. Launch:
   ```bash
   python main.py --lowvram
   ```
   Opens at `http://127.0.0.1:8188` by default.

### File Paths

```
{{GIT_REPO_PATH}}/ComfyUI/
  models/
    checkpoints/     -- SDXL base + community checkpoints (.safetensors)
    loras/           -- LoRA files (.safetensors)
    controlnet/      -- ControlNet models
    ipadapter/       -- IP-Adapter models
    insightface/     -- FaceID models (InsightFace)
  input/             -- Reference images for IP-Adapter / FaceID
  output/            -- Generated images (move to Barry inbox after QA)
```

### VRAM Requirements

| GPU VRAM | Default Resolution | Flag | Notes |
|----------|-------------------|------|-------|
| 6 GB | 768x768 | `--lowvram` | Functional but slow, no refiner |
| 8 GB | 768x768 (safe), 1024x1024 (possible) | `--lowvram` | RTX 2080 sweet spot |
| 12 GB | 1024x1024 | (none needed) | Comfortable, refiner enabled |
| 16 GB+ | 1024x1024 | (none needed) | Full pipeline, multiple LoRAs |

With 8 GB VRAM: use `--lowvram` flag. Keep LoRA count at 3 or fewer. Refiner is optional -- skip it for faster iterations.

### Sampler Settings

| Parameter | Value | Notes |
|-----------|-------|-------|
| **CFG** | 5-7 | 5-6 for photorealism, 7 for illustration. Never above 9 |
| **Steps** | 25-35 | 25 standard, 30-35 for detail (portraits, skin) |
| **Sampler** | DPM++ 2M Karras | Balanced quality. Alt: Euler a (fast), DPM++ SDE (portrait) |
| **Scheduler** | Karras | Best with DPM++ samplers |
| **Seed** | -1 (random) | Fixed seed for reproduction |

### Resolution Guide

SDXL is trained on 1024x1024. Only use these aspect ratios:

| Format | Resolution | Use Case |
|--------|-----------|----------|
| Square | 1024x1024 | Standard |
| Portrait | 832x1216 | Portraits, close-ups |
| Portrait alt | 896x1152 | Narrower portrait |
| Landscape | 1216x832 | Wide scenes |
| Landscape alt | 1152x896 | Action shots |
| Ultra-wide | 1536x640 | Panoramas |

On 8 GB VRAM, default to 768x768 with `--lowvram`. 1024x1024 is possible but slower.

### Prompt Style (SDXL-Specific)

SDXL understands both tag-based and natural language prompts. Mixing works best.

**Structure:** Subject first (most important), then details, environment, mood, style, camera.

```
A 30 year old woman with curly brown hair, blue dress, standing in a sunlit garden,
warm afternoon light, candid amateur photo, shot on Canon EOS R5, 85mm f/1.4
```

**Negative prompt baseline:**
```
low quality, blurry, pixelated, distorted, extra limbs, watermark, text, deformed hands, bad anatomy
```

Keep negative prompts short -- 1-2 lines maximum. Overspecification hurts quality.

**Weight syntax:** `(term:weight)` -- safe range 0.8-1.4, max 3-4 weighted terms per prompt.

### Refiner (Optional)

The SDXL refiner improves faces, skin texture, shadows, and edges. Recommended for portraits, skip for fast iterations.

| Parameter | Value |
|-----------|-------|
| Switch point | 0.75 (75% of steps) |
| Step split | 15 base + 10 refiner |
| Sampler | DPM++ 2M Karras |

### Community Checkpoints

Base SDXL 1.0 works but community checkpoints provide better results for specific styles.

| Checkpoint | Strength |
|-----------|----------|
| **RealVisXL V5.0 Lightning** | Sharp photorealism, fast (6-8 steps) |
| **Juggernaut XL** | All-round photorealism |
| **CyberRealistic XL** | Editorial, clean photographic sharpness |

All stored in `models/checkpoints/`. Download from CivitAI or HuggingFace.

### LoRA Usage

Community LoRAs provide fine-tuned control over style, character consistency, and pose.

- Use only SDXL-compatible LoRAs (SD 1.5 LoRAs will not work)
- Store in `models/loras/`
- Maximum 3 LoRAs simultaneously for stability

| Type | Weight Range |
|------|-------------|
| Character / face | 0.6-0.9 |
| Style | 0.4-0.7 |
| Clothing / object | 0.3-0.6 |

### IP-Adapter and FaceID (Reference-Based Generation)

The key capability ComfyUI adds that Venice cannot provide.

**IP-Adapter Plus:**
- Upload a reference image to generate new images preserving style, composition, or character appearance
- Best for: style transfer, character consistency, visual moodboards
- No training required -- works at inference time

**FaceID PlusV2:**
- Maintains consistent face identity across an image series
- Requires InsightFace (pip install insightface, needs C++ build tools)
- Enables generating multiple images with the same face without training a LoRA

### Upscale Strategy (Local)

| Method | Setting | Use Case |
|--------|---------|----------|
| HighRes Fix | Denoise 0.35-0.45, 1.5-2x, 15-20 steps | Standard |
| ESRGAN 4x-UltraSharp | External post-process | Premium quality |
| img2img refine | Low denoise (0.3) after upscale | Maximum detail |

### Integration with Barry Pipeline

Generated images from ComfyUI go through the same Barry pipeline:
1. Generate in ComfyUI (output lands in `ComfyUI/output/`)
2. Move to `{{ASSETS_PATH}}/00-inbox/`
3. Run `barry-sort.py` for vision analysis and categorization
4. Counter assignment, metadata, and NAS backup as usual

ComfyUI is NOT launched at session init. Open only when a task requires local generation (IP-Adapter, FaceID, ControlNet, or specific checkpoint).

---

## Scripts

| Script | Function |
|--------|---------|
| `barry.py` | CLI wrapper, delegates to barry-playwright.py and barry-upscale.py |
| `barry-playwright.py` | Playwright automation: Venice Chat UI → image |
| `barry-sort.py` | Vision analysis + sorting of inbox images |
| `barry-upscale.py` | Real-ESRGAN upscaling (local GPU) |
| `barry_counter.py` | Counter management |

---

## Image Categories

Allowed categories: `solo-f`, `solo-m`, `couple-mf`, `couple-mm`, `couple-ff`, `group-mf`, `group-mmm`, `group-fff`, `toys`, `portrait`, `landscape`, `concept`, `other`

Folders created on demand — no empty placeholder directories.

---

## Backup

| Layer | Source | Destination | Frequency |
|-------|--------|-------------|-----------|
| NAS | `{{ASSETS_PATH}}/` | `{{NAS_PATH}}/assets` | Every 6h (robocopy /MIR) |

Excludes: `.trash/`, `*.tmp`

---

## Privacy

NSFW images: privacy 3-4. Image files never in vault or on GitHub. Metadata notes (visual-index/) sync via Git but contain no image files.

NEVER link NSFW visual-index notes from public (L1-2) nodes.

---

## Prompt Dedup

Barry includes a prompt-hash deduplication system (`scripts/barry_dedup.py`) that prevents re-generating identical or near-identical prompts.

```bash
# Build cache from audit log
python barry_dedup.py --build

# Check a prompt
python barry_dedup.py "a fluffy cat on a sofa"
```

When integrated into the generation pipeline, Barry checks the cache before generating and prompts for confirmation if a similar prompt was used within the last 30 days. After successful generation, the prompt is registered automatically.

The cache uses SHA-256 of a normalised prompt (lowered, whitespace-collapsed, stop-words stripped) stored in `_private/image-prompt-hashes.json`.
