# DESIGN.md — AT Recovery RPG (Discreet Build: `ATP Pomodoro`)

> **Design Philosophy:** *"Obsidian Sanctuary × Sovereign Ember"* — Calm, nocturnal, high-craft mastery. Never clinical, never preachy, never generic purple-on-black AI slop. Every visual element is engineered to lower cortisol during urges, reward consistency with tactile satisfaction, and feel like a $10/month flagship app—100% free and open-source.

---

## 1. Visual Inspiration Synthesis (What Makes Top Quit-Porn Apps Work)

This design system intentionally merges the highest-retention visual patterns from top recovery apps while giving AT Recovery RPG its own unmistakable dark-RPG identity:

1. **From QUITTR:**
   - **Cosmic Obsidian Canvas:** Deep midnight-obsidian depth (`#090B10` → `#0D0F14`) with subtle radial ambient glow behind the hero centerpiece so the app feels calming late at night (when urges peak).
   - **Living 3D Centerpiece Orb:** A fluid, breathing shader-gradient sphere floating above the streak counter. Instead of being static, our orb **evolves across 7 RPG stages** (from a dim Ash Spark on Day 0 to a blazing Sovereign Emerald-Gold Nebula at Day 90).
   - **High-Contrast Recovery Arc & Instant Panic CTA:** A glowing circular brain-rewiring ring (`0% → 100%` over 90 days) paired with an unmistakable crimson-amber **Panic Button** anchored within thumb reach.
2. **From I Am Sober:**
   - **Cascading Time-Unit Bars:** Four stacked horizontal progress pills (`Days`, `Hours / 24`, `Minutes / 60`, `Seconds / 60`) that visibly fill in real time—giving micro-dopamine proof that every single minute counts.
   - **Milestone Shield Cards:** Tactile metallic rank badges (`24h`, `3d`, `7d`, `14d`, `30d`, `60d`, `90d`) with clean progress indicators.
3. **From Brainbuddy & Fortify:**
   - **Daily Pledge & Trigger Analytics:** Frictionless 1-tap morning pledge + structured urge/relapse trigger logging rendered as time-of-day heatmaps and emotion breakdowns.
4. **Dark Fantasy RPG Architecture (Zero-Shame):**
   - **Zero-Shame RPG Progression:** XP, Gold, Ranks (`Novice → Seeker → Sentinel → Vanguard → Warden → Sovereign → Titan`), a **Living Citadel Castle Builder**, **7-Chapter 90-Day Journey Map**, **On-Guard Guardian Spirit**, **3D Foil Milestone Cards**, **Skill Tree**, and **RPG Armory**. Relapses never inflict punitive HP damage—they trigger a calm **Post-Mortem Quest** that awards *Wisdom XP* for logging the trigger honestly.

---

## 2. Color System & Semantic Tokens

All surfaces follow a strict **3-elevation Obsidian hierarchy** with WCAG AA+ (`>= 4.5:1`) text contrast.

| Token | Hex | Usage |
| :--- | :--- | :--- |
| `--bg-void` | `#090B10` | App scaffold background, full-screen Panic Mode backdrop |
| `--bg-obsidian` | `#0D0F14` | Primary card & navigation rail surface |
| `--bg-elevated` | `#151922` | Modals, elevated glass cards, input fields |
| `--border-subtle` | `rgba(255, 255, 255, 0.08)` | 1px crisp card hairlines (no heavy drop shadows) |
| `--accent-emerald` | `#10B981` | Primary brand energy, active streak glow, clean check-ins |
| `--accent-emerald-glow` | `#34D399` | Active progress arcs, orb highlights, rank-up sparks |
| `--accent-gold` | `#F59E0B` | RPG Ranks, Gold Coins, Milestone Shields, 30d/90d mastery |
| `--accent-cyan` | `#06B6D4` | Breathing guide pulse, Focus/Meditation accents, sync indicator |
| `--accent-crimson` | `#EF4444` | **Reserved exclusively** for the Panic Button & high-urge alerts |
| `--text-primary` | `#F8FAFC` | Primary headlines, live streak numerals |
| `--text-secondary` | `#94A3B8` | Subtitles, metadata, timestamps |
| `--text-muted` | `#64748B` | Captions, disabled states |

### Glassmorphism Spec
- Fill: `#151922` at `72%` opacity + `BackdropFilter(sigmaX: 16, sigmaY: 16)`.
- Border: `1px solid rgba(255, 255, 255, 0.08)` with a subtle top-edge highlight `rgba(255, 255, 255, 0.14)`.

---

## 3. Typography & Numeric Precision

- **Display / Headlines:** `Plus Jakarta Sans` (Bold `700` / ExtraBold `800`, tight tracking `-0.03em`).
- **Body / UI:** `Inter` (Regular `400`, Medium `500`, SemiBold `600`).
- **Live Counters, Timers & Stats:** `JetBrains Mono` with `FontFeature.tabularFigures()` enabled **everywhere** so live ticking seconds never jitter horizontally.

| Role | Size (Mobile / Desktop) | Weight | Tracking |
| :--- | :--- | :--- | :--- |
| Hero Streak Days | `48px` / `60px` | 800 | `-0.04em` |
| Live H:M:S Sub-counter | `16px` / `18px` (Mono) | 600 | `+0.04em` |
| Screen Title | `24px` / `28px` | 700 | `-0.02em` |
| Card Title | `16px` / `17px` | 600 | `-0.01em` |
| Body Copy | `14px` / `15px` | 400 | `0` |
| Micro Label / Pill | `11px` / `12px` | 600 | `+0.06em` (UPPERCASE) |

---

## 4. Layout & Adaptive Architecture (Android + Windows Desktop + iOS/Web Ready)

Use a single responsive shell that adapts cleanly across screen widths:

- **Mobile (`< 720px` — Android / iOS):**
  - Floating bottom glass navigation bar (5 tabs: **Sanctuary**, **Quests**, **Journal**, **Analytics**, **Profile/Sync**).
  - Persistent high-priority **Panic Button** pill anchored directly above the bottom nav (or accessible via a 1-tap SOS FAB).
  - Safe-area padding (`SafeArea`), `16px` horizontal gutters, `20px` card border-radius.
- **Desktop & Tablet (`>= 720px` — Windows / Web):**
  - Left collapsible **Obsidian Navigation Rail** (`240px` expanded / `76px` compact) with persistent **Panic Override** button pinned at the bottom of the rail.
  - **2-Column / 3-Column Bento Grid** on the Sanctuary Dashboard:
    - Left Hero Column: Living 3D Orb + Live Streak Counter + Cascading Time Bars + Quick Actions (`Pledge`, `Breathe`, `Sync`).
    - Right Column: Evolving RPG Companion Card + 90-Day Brain Rewiring Ring + Active Daily Quests + Recent Trigger Insight.
  - Custom frameless Windows title bar using `window_manager` with minimal window controls and discreet title (`ATP Pomodoro` when Discreet Mode is active).

---

## 5. Signature Screens & Micro-Interactions

### 5.1 Sanctuary Home (Dashboard)
1. **Top Status Strip:** Current Rank Pill (`🛡️ Vanguard · Lvl 12`), XP/Gold mini-counter, Sync Cloud Badge (green dot = synced), and 1-tap **Discreet Mask Toggle** (instantly swaps UI to a clean Pomodoro Focus Timer screen if someone looks over your shoulder).
2. **Hero Centerpiece:**
   - **Living Shader Orb** (`mesh` / `flutter_mesh_gradients` animated at 60fps) that gently breathes (`4s` sine cycle) and shifts palette by Milestone Stage.
   - **Bold Day Counter** (`14 DAYS`) + pill badge (`06h 42m 19s`).
   - **I Am Sober-Style Cascading Time Bars** (toggleable view or tucked neatly below the orb): Emerald (Days) → Cyan (Hours) → Indigo (Minutes) → Gold (Seconds).
3. **Quick Action Row:** 3 glass circular icon buttons — **Daily Pledge** (checkmark), **Breathe** (lungs/wind), **Log Urge** (shield/pen).
4. **90-Day Rewiring Ring:** Thick animated radial progress arc (`fl_chart` or custom `CustomPainter` with sweep gradient) showing percentage toward 90-day neural reset.
5. **Evolving Sanctuary Companion Card:** Visual stage artwork (rendered via layered vector/shader art or CustomPainter) evolving at **Days 1, 3, 7, 14, 30, 60, and 90** (Ember Seed → Sprouting Warden → Crystal Sapling → Flame Guardian → Astral Tree → Sovereign Phoenix → Celestial Titan).

### 5.2 Instant Panic Button (Full-Screen Urge Override)
- Triggered in `< 150ms` with a tactile haptic pulse (`HapticFeedback.heavyImpact()`).
- **Zero distractions, zero navigation bars.** Dark void backdrop (`#090B10`) with a glowing cyan-emerald **4-7-8 Breathing Orb** (4s Inhale expand → 7s Hold shimmer → 8s Exhale contract).
- **3 Instant Action Cards** below the orb:
  1. **Physical Reset:** Randomized 60-second challenge (*"Drop and do 20 pushups"*, *"Splash ice-cold water on your face"*, *"Walk outside for 3 minutes"*).
  2. **Why I Started:** Displays the user's own personal reason/pledge in large display typography.
  3. **Urge Survived (+50 XP):** Marks the urge defeated, triggers subtle emerald confetti (`flutter_confetti`), logs the victory to the Trigger Journal, and rewards XP/Gold.

### 5.3 RPG Quests, Hero Armory & Discreet Focus
- Clean Daily Check-in, Focus Quests (with optional built-in Pomodoro timer that also powers Discreet Mode), Daily Loot Chests, and Trigger Shield Checklists.
- **Hero Sheet, Skill Tree & Trophy Vault:** 4 RPG attributes (`Willpower`, `Focus`, `Vitality`, `Wisdom`), skill tree perks, orb/aura armory, and 9 collectible 3D-tilt foil milestone cards (`24h` to `365d`).
- **Free Encrypted Cross-Device Sync:** Private GitHub Gist PBKDF2 + AES-256-GCM sync with 1-tap QR code pairing, optional Supabase free-tier RLS Postgres sync, and offline encrypted `.atp` backup files.

### 5.4 Trigger & Relapse Journal + Analytics
- **Fast 10-Second Urge/Relapse Log:** Slider for Urge Intensity (`1–10`), multi-select Trigger Chips (`Boredom`, `Late Night`, `Stress`, `Social Media`, `Loneliness`, `Fatigue`), and optional private note.
- **Analytics Charts (`fl_chart`):**
  - Time-of-Day Danger Heatmap (24-hour bar/area chart showing peak vulnerability windows).
  - Trigger Breakdown Donut Chart.
  - 90-Day GitHub-Style Clean Consistency Heatmap Grid.

---

## 6. Motion, Haptics & Anti-Slop Rules

- **Spring Physics & Easing:** Use `Curves.easeOutCubic` (`220ms–320ms`) for sheets/cards and gentle `4000ms` ambient loops for the Orb. Never use bouncy cartoonish overshoots on serious recovery controls.
- **Staggered Entrance:** Dashboard cards enter with `flutter_animate` (`fadeIn(duration: 280.ms)` + `slideY(begin: 0.04, end: 0)` staggered by `45ms`).
- **Haptic Language:** Light tick on tab switch, medium pulse on Daily Pledge, double-pulse on Rank Up, heavy steady rhythm during 4-7-8 breathing transitions.
- **Strict Anti-Slop Checklist:**
  - NO generic white Material cards or default purple Material 3 themes.
  - NO Lorem Ipsum, fake placeholder stats, or unimplemented "Coming Soon" dead buttons.
  - NO cluttered walls of text—use visual hierarchy, chips, and breathing room (`16px–24px` padding).
  - NO layout overflow on narrow phones (`360×800`) OR wide desktop windows (`1440×900`).

---

## 7. v3.0 Flagship Architecture Addendum — "The Eclipse Chronicle"

1. **Responsive 5-Tab Mobile Shell + Desktop Navigation Rail:**
   - Mobile Bottom Glass Bar (`< 720px`): **Citadel** (`/sanctuary`), **Chronicle** (`/journey`), **Spellbook** (`/quests`), **Hero** (`/hero`), **Codex** (`/profile`) + persistent crimson **Mirage Ambush** SOS CTA (`/panic`).
   - Desktop Navigation Rail (`>= 720px`): Same core routes plus direct **Journal** (`/journal`) link.
2. **Evidence-Based Mechanics Mapped Directly to Dark-RPG Systems:**
   - **System 1 (Mirror of Truth Prologue & Auto-Config Engine):** 8-card diagnostic intake + 3-second hold-to-seal gesture + 3.5s calibration generating a personalized `DiagnosticBlueprint`, `CounterSpell` starter deck, daily vows, and 90-day projected horizon.
   - **System 2 (2D Flame Citadel & HALT Vulnerability Radar):** Layered Flame parallax Citadel evolving across 8 tiers (`0..7`), HALT radar (`Hungry`, `Angry`, `Lonely`, `Tired`) with one-tap micro-restoration quests, and Sovereign Stability Ratio.
   - **System 3 (Mirage Ambush 2D Boss Arena):** Embedded Flame Arena (`flame_camera_tools` screen shake, Hades trailing HP bar, projectile strikes, spark particles, SFX) pairing ACT Cognitive Defusion, 4-7-8 Breath-Wave Surge, and Forged `IF -> THEN` Counter-Spells (`-50 CRIT`).
   - **System 4 (Spellbook):** Gollwitzer Implementation Intentions (`CounterSpell`, Ranks `I–V`), Daily Vows, Tribute Chest, Trigger Shield, and Deep Focus `ATP Pomodoro`.
   - **System 5 (Roguelite Anti-Wipe Pact — Fallen Run Campfire):** Zero-wipe slips preserve Citadel tiers, Chronicle Acts, Counter-Spell ranks, Stats, Skill Tree perks, and Foil Relics while restarting only the active arc timer and awarding `+20 WIS XP`.
   - **System 6 (Predictive Recovery Telemetry):** 6-panel Codex analytics (`Live Risk Forecast Gauge`, `24h Circadian Curve`, `7×4 Weekly Heatmap`, `Intensity Decay & Focus Correlation`, `Trigger Donut`, `90-Day Consistency Grid`).

---

## 8. v4.0 Visual Overhaul Addendum — Full-Bleed Illustrated 2D Indie RPG

1. **Painted 2D Indie RPG Asset Pack (`assets/art/`):** Replaced geometric wireframe shapes for castles, knights, bosses, chests, relic crests, and world maps with 9 painterly dark-fantasy PNGs (`citadel_tier_1..4.png`, `guardian_knight.png`, `mirage_boss.png`, `loot_chest.png`, `relic_emblem.png`, `realm_map_bg.png`).
2. **Signature RPG Primitives (`lib/core/theme/rpg_widgets.dart`) + `Cinzel` Typography:** Unified twilight-obsidian gradients (`#0C1020` -> `#141A30`), `OrnateRpgFrame` diamond filigree corners, `RpgBevelButton`, `HadesProgressBar`, `VitalityOrbButton`, `flame` sky starlight, and `particles_flutter` drifting embers.
3. **Full-Bleed Viewport World (`World` Tab) & Sleek 5-Tab Shell (`World`, `Journey`, `Spells`, `Hero`, `Stats`):** Replaces crowded card boxes with open starry Citadel world vistas, clickable `+5 G` Ember Wisps, foreground Guardian knight with *Hades* dialogue, and slide-up Campfire Vitality & Forge drawers (`schemaVersion: 4`).
