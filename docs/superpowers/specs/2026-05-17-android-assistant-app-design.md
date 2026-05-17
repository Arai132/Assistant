# Android Assistant App — Design Spec

**Date:** 2026-05-17  
**Stack:** Flutter (Dart), Android-first (iOS-ready)  
**Status:** Approved for implementation planning

---

## Overview

A personal productivity app for Android that unifies task management, note-taking, and scheduling into a single local-first app. The core idea: every item (task or note) can have any combination of attachments — voice memos, images, documents, and videos. Images are automatically processed via OCR and optional AI description.

---

## Architecture

### Approach: Unified "Item" Model

All content is an `Item` with a type. Tasks and notes share the same attachment system, avoiding duplicated logic. A note can be promoted to a task with one tap; a task always has an optional note body.

### Navigation

Bottom navigation bar with 4 tabs + a central FAB:

| Tab | Purpose |
|-----|---------|
| Tasks | Kanban priority board + task detail |
| Notes | Note list + image/voice capture |
| Calendar | Month view + day detail (GCal integrated) |
| Settings | Sync, API keys, Google Calendar auth |

**FAB (center, always visible):** Expands to quick-capture menu — New Task, New Note, Snap Image, Record Voice, Upload File.

---

## Data Model

### Core Entities

```
Item
  id: UUID
  title: String
  body: String (markdown)
  type: enum(task, note, both)
  created_at: DateTime
  updated_at: DateTime

Task (extends Item)
  priority: enum(high, medium, low)
  due_date: DateTime?
  status: enum(todo, in_progress, done)
  calendar_event_id: String?     // linked GCal event

Attachment (belongs to any Item)
  id: UUID
  item_id: UUID
  type: enum(voice_memo, image, document, video)
  local_path: String
  cloud_url: String?
  ocr_text: String?              // populated by ML Kit
  ai_description: String?        // populated by cloud AI
  created_at: DateTime
```

**Local storage:** SQLite via [Drift](https://drift.simonbinder.eu/) (Flutter type-safe ORM).  
**File storage:** App private directory (`getApplicationDocumentsDirectory()`). Attachments referenced by path, never embedded in the DB.

---

## Screens

### 1. Tasks Screen — Kanban Priority Board

Three horizontal lanes: **High / Medium / Low**. Each lane is a scrollable column of task cards. Drag a card to a different lane to change its priority. Within a lane, cards are ordered by due date.

Task card shows: title, due date, attachment badge icons (🎤 📎 🖼️ 🎬), completion checkbox.

Long-press a card to enter reorder mode within a lane.

### 2. Task Detail Screen

Opens when a task card is tapped. Contains:

- **Title** (editable inline)
- **Priority badge** (tappable to change)
- **Due date + status** (tappable)
- **Notes section** — rich text body (markdown)
- **Voice memos section** — waveform player per memo, record button at bottom
- **Attachments section** — grid of attached files (doc, image, video); tap to open, long-press to delete
- **Linked Calendar Event** — shown if task is linked to a GCal event
- **Bottom bar** — Mark Complete, Delete

### 3. Notes Screen

List of all notes, sorted by updated_at. Each row shows: thumbnail (image notes) or type icon, title, body preview, attachment badges, timestamp.

Search bar at top filters by title and body text (including OCR-extracted text).

### 4. Note Detail Screen

- **Title** (editable)
- **Body** — markdown editor
- **Attachments** — same attachment system as Task Detail
- **"Make this a task" button** — promotes note to a task, preserving all attachments

### 5. Image Capture Flow

Triggered from FAB → "Snap Image" or from any attachment section's "+" button.

1. Camera or gallery picker
2. ML Kit Text Recognition runs on-device (instant, offline)
3. If text detected: OCR result shown as note body draft
4. If API key configured: "Describe with AI" button sends image to OpenAI GPT-4o Vision; result shown as subtitle
5. User can edit title, body, and description before saving
6. Saved as a Note (or directly as a Task attachment if opened from task detail)

### 6. Calendar Screen

- **Month grid** — compact, dots below dates indicate items: blue = GCal event, red/yellow/teal = task by priority
- **Day detail panel** (below grid) — scrollable list of that day's GCal events and tasks due, color-coded by source
- **Tap a task** → opens Task Detail; tap a GCal event → opens event in Google Calendar app

### 7. Settings Screen

- Cloud sync toggle (Firebase)
- Google Calendar: Connect / Disconnect (OAuth2)
- AI API key input (stored in Android Keystore, not in app storage)
- Storage usage
- Export data (JSON)

---

## Attachment System

All attachment types work identically on both Tasks and Notes.

| Type | Capture | Playback |
|------|---------|----------|
| Voice memo | In-app recorder (flutter_sound) | In-app waveform player |
| Image | Camera / gallery | Full-screen viewer; OCR + AI on creation |
| Document | File picker (pdf, txt, docx) | Open with system viewer |
| Video | File picker / camera | Thumbnail + system player |

Max attachment size: 100MB per file (enforced at pick time with user-facing error).

---

## AI & OCR

### On-Device OCR (always available)
- Library: `google_mlkit_text_recognition`
- Runs synchronously during image import
- Result stored as `Attachment.ocr_text`
- No internet, no cost, no API key required

### Cloud AI Description (optional)
- Provider: OpenAI GPT-4o Vision (v1; Gemini support deferred to v2)
- Called only on explicit user tap of "Describe with AI" button
- API key stored in Android Keystore via `flutter_secure_storage`
- If no key configured: button hidden entirely; app shows only OCR results
- Failure (network error, API error): shows inline toast "Description unavailable, using OCR only"

---

## Sync Strategy

### Local-First
All reads and writes go to local SQLite first. The app is fully functional with no internet connection.

### Cloud Sync (Firebase)
- **Firestore** for structured data (items, tasks, attachment metadata)
- **Firebase Storage** for attachment files
- Sync trigger: on reconnect + on app foreground
- Conflict resolution: last-write-wins on scalar fields; attachments are append-only (never deleted remotely without explicit user action)
- Pending sync shown as a small badge on affected items

### Google Calendar Sync
- **Auth:** OAuth2 via `google_sign_in` + `googleapis` packages
- **Pull:** GCal events fetched on calendar open and cached locally for 15 minutes
- **Push:** When a task has a due date and user taps "Add to Calendar", creates a GCal event and stores the event ID on the task
- GCal events are read-only in this app — edits happen in Google Calendar

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Attachment upload fails | Queued silently, retried on next sync; "pending sync" badge shown |
| OCR fails (blurry image) | Inline message: "Couldn't extract text — image saved as attachment" |
| AI description fails | Toast: "Description unavailable"; OCR result used if available |
| No AI API key | "Describe with AI" button hidden; no error shown |
| GCal auth expired | Non-blocking banner: "Reconnect Google Calendar" |
| File too large (>100MB) | Picker error dialog before import |
| Offline | App fully functional; sync badge on items with pending changes |

---

## Testing Plan

| Layer | What |
|-------|------|
| Unit | Data model CRUD, sync conflict resolution logic, OCR text parsing |
| Widget | Kanban drag-and-drop, task detail form validation, attachment grid |
| Integration | Image → OCR → note creation end-to-end; voice memo record → playback |
| Manual | Google Calendar OAuth flow, Firebase sync across two devices |

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `drift` | SQLite ORM |
| `firebase_core` + `cloud_firestore` + `firebase_storage` | Cloud sync |
| `google_sign_in` + `googleapis` | Google Calendar |
| `google_mlkit_text_recognition` | On-device OCR |
| `flutter_secure_storage` | API key storage |
| `flutter_sound` | Voice recording + playback |
| `file_picker` | Document + video import |
| `image_picker` | Camera + gallery |
| `drag_and_drop_lists` | Kanban drag between lanes |
| `http` / `dio` | OpenAI API calls |

---

## Out of Scope (v1)

- iOS build (architecture is ready; publishing is deferred)
- Collaboration / shared tasks
- Transcription of voice memos (speech-to-text)
- Custom tags or folders
- Widget / home screen shortcut
