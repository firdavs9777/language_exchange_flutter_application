# Report Evidence Attachment Design

**Date:** 2026-07-09  
**Feature:** Users can attach screenshots and text evidence to support violation reports; admins review evidence in report detail pane.

---

## Goal

Improve report quality by allowing users to attach visual evidence (screenshots) and text excerpts when submitting violation reports. Currently, admins review reports with only a reason + optional description, making it hard to verify claims. Evidence attachments give admins the context needed to make informed moderation decisions.

---

## Scope

**In scope:**
- File attachment UI in report dialogs (all report types: user, moment, message, comment, story)
- Evidence upload to DigitalOcean Spaces (reuse existing `uploadToSpaces` infrastructure)
- Evidence display in admin report detail pane
- Auto-delete evidence when report is resolved
- File validation (JPG, PNG, TXT; max 5MB each; max 5 files per report)

**Out of scope:**
- Video/audio evidence (image + text only)
- Evidence versioning or edit history
- Public visibility of evidence (admin-only)
- Evidence search/indexing

---

## Design

### 1. File Constraints

| Constraint | Value | Rationale |
|-----------|-------|-----------|
| Allowed types | JPG, PNG, TXT | Covers screenshots + extracted text |
| Max per file | 5 MB | DigitalOcean Spaces default; prevents abuse |
| Max per report | 5 files | Enough for typical multi-step violations; prevents report spam |
| Total per report | 25 MB | 5 × 5 MB |

MIME types:
- `image/jpeg`, `image/jpg`, `image/png` (images)
- `text/plain` (text files)

### 2. Flutter Frontend

#### Report Dialog Changes

**New UI section: Evidence attachment**

Insert between description field and submit button:

```
┌─────────────────────────────────────┐
│ Add Evidence (Required)              │
│ Upload screenshots or text           │
├─────────────────────────────────────┤
│ [📎 Add Files]  (up to 5 files)     │
│                                     │
│ ✓ screenshot1.jpg (2.3 MB)  [✕]   │
│ ✓ chat_excerpt.txt (48 KB)  [✕]   │
│                                     │
│ Progress: 2.4 MB / 25 MB           │
└─────────────────────────────────────┘
```

**Behavior:**
- "Add Files" button opens file picker (camera + gallery + file browser)
- Each file shown as: checkmark + name + size + delete icon
- Delete icon removes the file from the list
- Total size progress bar shown below
- File count badge: "2/5 files"
- Submit button disabled until ≥1 evidence file selected

**Validation (client-side):**
- Reject files if type not in allowed list → toast "JPEG, PNG, or TXT only"
- Reject if file > 5 MB → toast "File too large (max 5 MB)"
- Reject if total > 25 MB → toast "Total evidence exceeds 25 MB limit"
- Reject if ≥5 files already selected → disable "Add Files" button

**Upload on submit:**
- When user taps submit, show loader over the report dialog: "Uploading evidence..."
- For each file, POST to `/api/v1/reports/:reportId/evidence` (only after report is created)
- Collect returned URLs
- Store URLs in Report model's `evidence` array
- Then show success toast and close dialog

**Error handling:**
- If upload fails for 1+ files, show toast: "Failed to upload {filename}. Report submitted without evidence."
  - Report is still created (evidence is optional on backend for backward compat)
  - User can re-attach via report detail later (if we build that UI; not in this wave)

#### Report Model Changes

Extend `Report` model (or wherever mapped from backend) to include:

```dart
List<EvidenceFile>? evidence;

class EvidenceFile {
  final String filename;
  final String url;
  final String type; // 'image' | 'text'
  final int size; // bytes
  final DateTime uploadedAt;
}
```

### 3. Admin Reports Screen Changes

#### Report Detail Pane

New section at bottom: **Evidence**

**Empty state:**
```
Evidence: None provided
```

**With evidence:**
```
Evidence (2 files)
──────────────────
📷 screenshot1.jpg (2.3 MB) [open]
📄 chat_excerpt.txt (48 KB) [open]
```

**Image handling:**
- Render as inline thumbnail (100×100 dp max)
- Tap to open full-size in modal overlay (with zoom + download button)
- Filename + size shown below

**Text handling:**
- Show first 200 chars in expandable preview block
- Tap to expand/collapse (show full text inline)
- Filename + size shown below

**No delete button for admin** — evidence is read-only in detail pane.

### 4. Backend

#### New Report Schema Fields

```javascript
// In models/Report.js, extend the schema:
evidence: [
  {
    filename: String,        // original filename
    url: String,            // DigitalOcean Spaces CDN URL
    type: String,           // 'image' or 'text' (derived from MIME type)
    size: Number,           // bytes
    uploadedAt: Date,       // when uploaded
    key: String,            // S3 key for deletion later
    _id: false
  }
],
```

Default: empty array `[]`.

#### New Endpoint: Upload Evidence

```
POST /api/v1/reports/:reportId/evidence
Content-Type: multipart/form-data

Body: single file in field `file`
```

**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "filename": "screenshot.jpg",
    "url": "https://my-projects-media.sfo3.cdn.digitaloceanspaces.com/reports/...",
    "type": "image",
    "size": 245000,
    "uploadedAt": "2026-07-09T15:22:00Z"
  }
}
```

**Validation (backend):**
- Check MIME type against whitelist (image/jpeg, image/png, text/plain)
- Reject if size > 5 MB
- Check report exists + authenticated user is the reporter (or admin)
- Reject if evidence array already has 5 files → 400 "Max 5 files per report"

**Storage:**
- Reuse `uploadToSpaces` middleware pattern
- Store in path: `reports/{reportId}/{timestamp}-{filename}`
- Use Cloudflare CDN URL (via `CDN_URL` env var, fallback to DigitalOcean)

**Errors:**
- 400 Bad Request: invalid file type, too large, max files exceeded
- 404 Not Found: report doesn't exist
- 403 Forbidden: user is not the reporter and not an admin
- 413 Payload Too Large: request body > 10 MB

#### Evidence Deletion on Report Resolution

Extend `resolveReport` action in `controllers/report.js`:

When action is `'user_banned'`, `'content_removed'`, `'user_warned'`, `'user_suspended'`, `'no_violation'`, or `'dismissed'`:

```javascript
// After the action-specific logic (ban/suspend/delete content/etc):
if (report.evidence && report.evidence.length > 0) {
  const s3 = require('../config/spaces');
  for (const file of report.evidence) {
    try {
      await s3.deleteObject({
        Bucket: 'my-projects-media',
        Key: file.key
      }).promise();
    } catch (err) {
      console.error(`Failed to delete evidence file ${file.key}:`, err.message);
      // Don't fail the entire resolution if one file delete fails
    }
  }
}

// Then clear the evidence array
report.evidence = [];
await report.save();
```

Fire-and-forget deletion — if a file fails to delete, log the error and continue (don't block report resolution).

---

## Data Flow

### User Reports with Evidence

```
Flutter (User)
    ↓
1. User taps "Report" on content
2. ReportDialog opens with new "Evidence" section
3. User taps "Add Files" → file picker
4. User selects up to 5 JPG/PNG/TXT files
5. Each file shown in list with preview
6. User taps "Submit Report"
    ↓
Backend (Create Report)
    ↓
POST /api/v1/reports
- reason, description, type, reportId, reportedUser
- NO evidence in body yet (files uploaded separately)
    ↓
Response: Report created, _id = ABC123
    ↓
Flutter (Upload Evidence)
    ↓
For each file:
  POST /api/v1/reports/ABC123/evidence
  - multipart file + metadata
    ↓
Backend (Store Evidence)
    ↓
Use uploadToSpaces middleware
- Validate file (type, size)
- Upload to Spaces: reports/ABC123/{timestamp}-{filename}
- Store metadata in Report.evidence array
    ↓
Response: evidence object with URL
    ↓
Flutter (Complete)
    ↓
Show success toast, close dialog
User can see their report in "My Reports" with evidence attached
```

### Admin Reviews Evidence

```
Flutter (Admin)
    ↓
1. Admin opens AdminReportsScreen
2. Clicks on a report → detail pane opens
3. Scrolls to "Evidence" section at bottom
4. Sees thumbnail + filename for each file
5. Taps thumbnail → full-size modal with zoom
    ↓
Backend (Retrieve Evidence)
    ↓
Evidence URLs already in Report doc
Frontend displays URLs directly
(No additional backend call needed)
```

### Evidence Cleanup

```
Admin Action
    ↓
Admin taps "Resolve" on report
Selects action (user_banned, content_removed, etc)
    ↓
Backend (Resolve Report)
    ↓
1. Execute action (ban user, delete content, etc)
2. Delete evidence files from Spaces (for each file.key)
3. Clear Report.evidence array
4. Save report
    ↓
Evidence now deleted from Spaces
Report shows "Evidence: None"
```

---

## Backward Compatibility

**Frontend:** Evidence is **required** in new client.
- Older clients don't support evidence attachment
- If an older client submits a report, backend still accepts it (evidence array stays empty)
- Admins see "Evidence: None" for reports from old clients
- No API breaking changes

**Backend:** Evidence is **optional**.
- Report can be created without evidence
- Report can be created with evidence
- `GET /api/v1/reports` returns evidence array (empty or populated)
- No version bump needed

**Migration:** No data migration. Existing reports in DB have no evidence array (or empty array). Queries read it as empty gracefully.

---

## Error Handling

| Scenario | Frontend | Backend |
|----------|----------|---------|
| File type invalid | Reject file, toast "JPEG, PNG, or TXT only" | 400 Bad Request |
| File > 5 MB | Reject file, toast "File too large" | 413 Payload Too Large |
| Total > 25 MB | Reject new files, toast "Limit exceeded" | 400 Bad Request (report has 5 files) |
| Upload fails mid-stream | Retry? Or show partial? | 500 Internal Server Error (report created, re-try upload) |
| Report doesn't exist | N/A | 404 Not Found |
| User not authorized | N/A | 403 Forbidden |
| Delete evidence fails | Continue (non-blocking) | Log error, continue |

**User experience on upload failure:**
- If 1+ files fail to upload, show toast: "Report submitted. {N} file(s) failed to upload."
- Report is still created (data integrity, don't lose the report)
- User is notified that evidence is incomplete (not silent failure)

---

## File Organization

### Backend

```
controllers/
  └── report.js (extend resolveReport + add evidence cleanup logic)

middleware/
  └── (reuse uploadToSpaces.js for evidence uploads)

models/
  └── Report.js (add evidence schema field)

routes/
  └── report.js (add POST /api/v1/reports/:reportId/evidence)
```

No new middleware or helpers; reuse existing `uploadToSpaces`.

### Flutter

```
lib/
  ├── widgets/
  │   ├── report_dialog.dart (extend with evidence section)
  │   └── evidence_preview_widget.dart (new: thumbnail/text preview)
  │
  ├── pages/
  │   └── reports/
  │       └── admin_reports_screen.dart (extend detail pane with evidence section)
  │
  ├── services/
  │   └── report_service.dart (add uploadEvidence method)
  │
  └── models/
      └── report_model.dart (add EvidenceFile class, extend Report)
```

---

## Testing

### Frontend (Flutter)

- **Evidence section renders:** evidence UI appears in report dialog
- **File picker works:** can select JPG, PNG, TXT; file list updates
- **Validation works:** rejects invalid types/sizes; shows correct toasts
- **Submit uploads:** evidence files POST to backend; URLs collected
- **Error case:** upload fails → report still created, toast shown
- **Admin view:** evidence thumbnails render in detail pane; tap to expand
- **Text preview:** expandable text block shows content

### Backend

- **Schema validates:** evidence array stores correctly
- **Upload endpoint:**
  - Rejects invalid types (400)
  - Rejects oversized files (413)
  - Rejects 6th file (400)
  - Accepts valid files (201, returns metadata)
- **File storage:** evidence files land in Spaces at correct path
- **Resolution cleanup:** evidence files deleted from Spaces when report resolved
- **Backward compat:** reports without evidence array work fine

---

## Future Enhancements

- ❌ Evidence re-upload / editing (out of scope for v1)
- ❌ Evidence versioning (out of scope)
- ❌ Audio/video evidence (out of scope)
- ❌ Admin annotation on evidence (out of scope)
- ❌ Automated content moderation (e.g., NSFW flagging) (out of scope)

---

## Rollback

If evidence attachment breaks:
1. Revert backend (evidence cleanup on report resolve)
2. Revert Flutter UI (report dialog, admin detail pane)
3. Evidence files already in Spaces stay; admin can manually clean via S3 CLI if needed
4. Reports without evidence are fully functional (backward compat)

No DB migration needed — evidence array defaults to empty.

---

## Questions & Assumptions

1. **File picker:** Flutter's standard file picker (e.g., `file_picker` package) — assumes already in use elsewhere
2. **Image compression:** No compression on upload (unlike existing chat images); we compress on image post, not report evidence
3. **CDN:** Assumes `CDN_URL` env var already set in backend; fallback to DigitalOcean CDN
4. **Text file preview:** Show up to 500 chars inline; tap "Read more" to expand full text

---
