# AT Recovery RPG — The Eclipse Chronicle v4.0 (Discreet Build: `ATP Pomodoro`)

An open-source, offline-first, **full-bleed illustrated 2D dark-fantasy recovery RPG** and deep-focus timer built with Flutter + Flame + `particles_flutter` for Android, Windows Desktop, Web, and iOS. Designed around the **Twilight Obsidian × Sovereign Ember** aesthetic (`DESIGN.md`): painted 2D indie RPG art (`Hades` × `Hollow Knight`), evidence-based clinical mechanics masked cleanly inside dark-RPG gameplay, roguelite zero-shame progression, and $0 end-to-end encrypted cross-device sync.

## Features (v4.0 — The Eclipse Chronicle Overhaul)

- **Museum-Grade 2D Indie RPG Art Pack (`assets/art/`):** 9 custom painted illustrations (`citadel_tier_1..4.png`, `guardian_knight.png`, `mirage_boss.png`, `loot_chest.png`, `relic_emblem.png`, `realm_map_bg.png`) paired with `Cinzel` display typography, `OrnateRpgFrame`, `RpgBevelButton`, `HadesProgressBar`, and circular `VitalityOrbButton`s.
- **Full-Bleed Interactive Moonlit Citadel World (`World`):** Opening the app reveals an atmospheric 2D moonlit Citadel evolving across 4 artwork stages (`Day 0` Campfire → `Day 60+` Celestial Titan Citadel) with breathing camera motion, `particles_flutter` drifting embers, clickable **`+5 Gold` Ember Wisps**, an interactive **Lantern Guardian Knight** with *Hades*-style wisdom speech bubbles, center-top floating `Cinzel` streak medallion, and a bottom 4-button **RPG Game Hotbar** (`Dawn Vow`, `Mirage Ambush`, `HALT Orbs` drawer, `Shield & Focus` forge drawer).
- **Turn-Based 2D Boss Arena (`Mirage Ambush`):** Painted **Guardian Knight** vs **Mirage Shadow Wraith** over dark ruined sanctuary art with projectile beam strikes, hit-flash & micro screen shake, trailing white-gold `HadesProgressBar`, glowing 4-7-8 Breath-Wave surfing, ACT Cognitive Defusion (`Name the Illusion`), Gollwitzer `IF -> THEN` Counter-Spells (`-50 CRIT`, leveling Ranks `I–V`), and a clickable **Obsidian Victory Loot Chest** (`+75 XP / +40 Gold`).
- **Playable 7-Act Story Map (`Journey`):** Vertical fantasy map over painted `realm_map_bg.png` with an animated Guardian frontier token, painted Relic Chests & Boss Gates, and illustrated vignette story modals featuring 2-option moral crossroads (`WIL` vs `WIS`).
- **Mirror of Truth 8-Question Auto-Setup Wizard (`PersonalRecoveryAlgorithm`):** Interactive intake → 3s Lantern Seal hold → calibration ring → personalized Guardian archetype, risk baseline (`0–100`), Counter-Spell starter deck, vows, and focus schedule.
- **Spellbook of Vows (`Spells`), 3D-Tilt Foil Vault (`Hero`), & Predictive Telemetry (`Stats`):**
  - Forge & practice `IF -> THEN` Counter-Spells + painted Tribute Chest + deep focus timer.
  - 4-Stat `fl_chart` Radar, 5-Perk Skill Tree, Gold Armory, and 9 `flutter_tilt` 3D-tilt Foil Crest Relics using `relic_emblem.png`.
  - 6-panel Predictive Behavioral Analytics (`Live Risk Forecast`, `24h Circadian Curve`, `7×4 Weekly Heatmap`, `Intensity Decay & Clean-Focus Correlation`, `Trigger Donut`, `90-Day Consistency Grid`), Roguelite Zero-Wipe **Fallen Run Campfire** (`+20 WIS XP`), Discreet Mask (`ATP Pomodoro`), PIN/Biometrics, and $0 PBKDF2 + AES-256-GCM Sync (GitHub Private Gist + 1-Tap QR Pairing, Optional Supabase, `.atp` files; `schemaVersion: 4`).

## Quick Start

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
flutter build windows --release
```

## Documentation & License

- UI tokens, typography, adaptive breakpoints, and craft rules live in [`DESIGN.md`](DESIGN.md).
- Database schema and Row-Level Security policies for optional Supabase sync live in [`supabase/schema.sql`](supabase/schema.sql).
- Released under the [MIT License](LICENSE).
