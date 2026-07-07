# Assistant

A personal productivity app for Android (Flutter, iOS-ready) that unifies task management, note-taking, and scheduling into a single local-first app.

Every item — task or note — can carry any combination of attachments: voice memos, images, documents, and videos. Images are automatically processed with on-device OCR, with an optional AI-generated description.

## Highlights

- **Unified item model** — tasks and notes share one underlying `Item` type with the same attachment system; a note can be promoted to a task with one tap.
- **Kanban task board** — drag-and-drop priority lanes (High/Medium/Low), sorted by due date.
- **Rich attachments** — voice memo recording/playback, camera/gallery images, documents, and video, all attachable to any task or note.
- **OCR + AI descriptions** — on-device text recognition (ML Kit) always available; optional GPT-4o Vision description when an API key is configured.
- **Calendar integration** — month view with color-coded tasks and Google Calendar events; push tasks to GCal.
- **Local-first** — SQLite (Drift) is the source of truth; the app is fully usable offline, with optional Firebase sync when online.

## Stack

Flutter (Dart) · Drift (SQLite) · Riverpod · GoRouter · Firebase (Firestore + Storage) · Google Calendar API · ML Kit Text Recognition

See [`docs/superpowers/specs/2026-05-17-android-assistant-app-design.md`](docs/superpowers/specs/2026-05-17-android-assistant-app-design.md) for the full design spec.

## Status

> **Note:** This project is currently not finished.
