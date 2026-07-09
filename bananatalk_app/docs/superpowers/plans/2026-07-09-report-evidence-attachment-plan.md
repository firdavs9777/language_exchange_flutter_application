# Report Evidence Attachment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to attach screenshots and text evidence when reporting violations, so admins can review actual proof before making moderation decisions.

**Architecture:** 
- Flutter: New evidence section in report dialogs (file picker, validation, required before submit); evidence preview widget for admin detail pane
- Backend: Extend Report schema with evidence array; reuse uploadToSpaces middleware for file storage to DigitalOcean Spaces; auto-delete evidence when report is resolved
- Backward compatible: evidence required on frontend (new clients), optional on backend (old clients still work)

**Tech Stack:** 
- Backend: Node.js/Express, Mongoose, DigitalOcean Spaces (S3-compatible), multer-S3
- Flutter: Dart, Riverpod, file_picker package (assumed available)

## Global Constraints

- Allowed file types: JPG, PNG, TXT (MIME: `image/jpeg`, `image/jpg`, `image/png`, `text/plain`)
- Max 5 MB per file, max 5 files per report (25 MB total)
- Evidence required in Flutter (no submit without ≥1 file); optional in backend (backward compat)
- Reuse existing `uploadToSpaces` middleware pattern for S3 uploads
- Evidence auto-deletes from Spaces when report is resolved (any action)
- No data migrations needed (evidence array defaults to empty)

---

## File Structure

### Backend

```
models/
  └── Report.js (extend schema with evidence array)

routes/
  └── report.js (add POST /api/v1/reports/:reportId/evidence)

controllers/
  └── report.js (extend resolveReport to delete evidence from Spaces)

middleware/
  └── (reuse uploadToSpaces.js — no changes)
```

### Flutter

```
lib/
  ├── models/
  │   └── report_model.dart (add EvidenceFile class, extend Report)
  │
  ├── widgets/
  │   ├── report_dialog.dart (add evidence section, file picker, validation)
  │   ├── evidence_preview_widget.dart (new: display thumbnails + text previews)
  │   └── evidence_tile.dart (new: individual evidence file display)
  │
  ├── pages/
  │   └── reports/
  │       └── admin_reports_screen.dart (extend detail pane with evidence section)
  │
  └── services/
      └── report_service.dart (add uploadEvidence method)
```

---

## Task Breakdown

### Task B1: Extend Report Schema with Evidence Field

**Files:**
- Modify: `models/Report.js`

**Interfaces:**
- Produces: Report schema with `evidence: [{ filename, url, type, size, uploadedAt, key }]` field

- [ ] **Step 1: Open Report.js and locate the main schema definition**

Find the section where all fields are defined (around line 1-50, depending on file size). Locate where other arrays are defined (like `comments`, `blockedUsers`, etc.) to follow the pattern.

- [ ] **Step 2: Add evidence schema field**

After the last field definition, add:

```javascript
evidence: [
  {
    filename: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: ['image', 'text'],
      required: true,
    },
    size: {
      type: Number,
      required: true,
    },
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
    key: {
      type: String,  // S3 key for deletion later
      required: true,
    },
    _id: false,  // disable _id for subdocuments
  }
],
```

Place this AFTER the last existing field and BEFORE any schema middleware (like `.pre('save')`).

- [ ] **Step 3: Set default value**

Find the schema definition line (e.g., `const reportSchema = new Schema({...})`). After all fields, ensure evidence defaults to empty array by adding to the schema options if not already present:

```javascript
evidence: {
  type: Array,
  default: []
}
```

Or if using the nested structure above, the default is already set (empty array by default).

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -c models/Report.js
```

Expected: No output (syntax valid).

- [ ] **Step 5: Commit**

```bash
git add models/Report.js
git commit -m "schema(report): add evidence array field

Add Report.evidence array to store evidence attachments.
Each evidence object contains: filename, url, type (image|text),
size, uploadedAt, and S3 key for deletion.

Default empty array; backward compatible with existing reports."
```

---

### Task B2: Add Evidence Upload Endpoint

**Files:**
- Modify: `routes/report.js`
- Modify: `controllers/report.js`

**Interfaces:**
- Consumes: Report model (from B1) with evidence array, uploadToSpaces middleware (existing)
- Produces: POST /api/v1/reports/:reportId/evidence endpoint that stores files and metadata

- [ ] **Step 1: Add route in routes/report.js**

Find the existing report routes (look for `router.post`, `router.get`, etc.). Add a new route after the main report endpoints:

```javascript
// POST /api/v1/reports/:reportId/evidence
router.post('/:reportId/evidence', protect, uploadEvidence);
```

Import the controller at the top if not already present:

```javascript
const { uploadEvidence } = require('../controllers/report');
```

- [ ] **Step 2: Verify route file has the router export**

Ensure the file ends with:

```javascript
module.exports = router;
```

- [ ] **Step 3: Add uploadEvidence controller**

In `controllers/report.js`, add this new function at the end of the file (before any module.exports):

```javascript
// POST /api/v1/reports/:reportId/evidence
// Upload evidence file (screenshot or text) to a report
exports.uploadEvidence = [
  uploadToSpaces.single('file'),
  async (req, res, next) => {
    try {
      // Validate report exists
      const report = await Report.findById(req.params.reportId);
      if (!report) {
        return next(new ErrorResponse('Report not found', 404));
      }

      // Validate user is the reporter or admin
      const isReporter = report.reportedBy.toString() === req.user.id;
      const isAdmin = req.user.role === 'admin';
      if (!isReporter && !isAdmin) {
        return next(new ErrorResponse('Not authorized to add evidence', 403));
      }

      // Validate file was uploaded
      if (!req.file) {
        return next(new ErrorResponse('No file provided', 400));
      }

      // Validate file type
      const mimeType = req.file.mimetype;
      const ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'text/plain'];
      if (!ALLOWED_TYPES.includes(mimeType)) {
        // Delete the uploaded file before rejecting
        await deleteFromSpaces(req.file.key);
        return next(new ErrorResponse('Invalid file type. Allowed: JPG, PNG, TXT', 400));
      }

      // Validate file size (5 MB)
      const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
      if (req.file.size > MAX_FILE_SIZE) {
        await deleteFromSpaces(req.file.key);
        return next(new ErrorResponse('File too large. Max 5 MB per file', 413));
      }

      // Validate max 5 files per report
      if (report.evidence && report.evidence.length >= 5) {
        await deleteFromSpaces(req.file.key);
        return next(new ErrorResponse('Max 5 files per report', 400));
      }

      // Determine evidence type based on MIME type
      let evidenceType = 'image';
      if (mimeType === 'text/plain') {
        evidenceType = 'text';
      }

      // Store evidence metadata in report
      const evidenceFile = {
        filename: req.file.originalname,
        url: req.file.location,  // From uploadToSpaces
        type: evidenceType,
        size: req.file.size,
        uploadedAt: new Date(),
        key: req.file.key,
      };

      if (!report.evidence) {
        report.evidence = [];
      }
      report.evidence.push(evidenceFile);
      await report.save();

      res.status(201).json({
        success: true,
        data: evidenceFile,
      });
    } catch (err) {
      // If upload partially succeeded but DB save failed, try to clean up
      if (req.file && req.file.key) {
        try {
          await deleteFromSpaces(req.file.key);
        } catch (cleanupErr) {
          console.error('Failed to clean up orphaned file:', cleanupErr.message);
        }
      }
      next(err);
    }
  }
];

// Helper: Delete file from DigitalOcean Spaces
async function deleteFromSpaces(key) {
  const s3 = require('../config/spaces');
  return new Promise((resolve, reject) => {
    s3.deleteObject(
      {
        Bucket: 'my-projects-media',
        Key: key,
      },
      (err) => {
        if (err) reject(err);
        else resolve();
      }
    );
  });
}
```

**Important:** Ensure `uploadToSpaces` is imported at the top of `controllers/report.js`:

```javascript
const uploadToSpaces = require('../middleware/uploadToSpaces');
const Report = require('../models/Report');
const User = require('../models/User');
const ErrorResponse = require('../utils/errorResponse');
```

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -c controllers/report.js && node -c routes/report.js
```

Expected: No output.

- [ ] **Step 5: Commit**

```bash
git add routes/report.js controllers/report.js
git commit -m "feat(report): add evidence upload endpoint

POST /api/v1/reports/:reportId/evidence accepts multipart file upload.

Validates:
- Report exists
- User is reporter or admin
- File type (JPG, PNG, TXT)
- File size (max 5 MB)
- Max 5 files per report

Stores metadata (filename, url, type, size, S3 key) in Report.evidence array.
Cleans up orphaned S3 files on failure."
```

---

### Task B3: Implement Evidence Cleanup on Report Resolution

**Files:**
- Modify: `controllers/report.js`

**Interfaces:**
- Consumes: Report model with evidence array (from B1), deleteFromSpaces helper (from B2)
- Produces: resolveReport action cleans up evidence files from Spaces

- [ ] **Step 1: Locate the resolveReport action handler**

Find the `exports.resolveReport` or similar function in `controllers/report.js`. Look for where actions like `'user_banned'` or `'content_removed'` are handled.

- [ ] **Step 2: Add evidence cleanup logic**

At the END of the action handling (after the specific action logic, but before the final response), add:

```javascript
// Clean up evidence files from DigitalOcean Spaces
if (report.evidence && report.evidence.length > 0) {
  const s3 = require('../config/spaces');
  for (const file of report.evidence) {
    try {
      await new Promise((resolve, reject) => {
        s3.deleteObject(
          {
            Bucket: 'my-projects-media',
            Key: file.key,
          },
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } catch (err) {
      // Log but don't fail the whole resolution
      console.error(`Failed to delete evidence file ${file.key}:`, err.message);
    }
  }
  // Clear the evidence array
  report.evidence = [];
}
```

Place this cleanup AFTER all action-specific logic (ban/suspend/delete content) but BEFORE the final `await report.save()` or response.

- [ ] **Step 3: Verify the cleanup runs for all resolution actions**

Check that the cleanup block is OUTSIDE of any action-specific `if` statements, so it runs regardless of which action (user_banned, content_removed, user_warned, etc.) is taken.

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
node -c controllers/report.js
```

Expected: No output.

- [ ] **Step 5: Commit**

```bash
git add controllers/report.js
git commit -m "feat(report): auto-delete evidence when report resolved

When resolveReport action fires (any action: user_banned,
content_removed, user_warned, etc.), delete all evidence files
from DigitalOcean Spaces and clear the Report.evidence array.

File deletion failures are logged but don't block report resolution
(fire-and-forget cleanup)."
```

---

### Task F1: Update Report Model with Evidence Support

**Files:**
- Modify: `lib/models/report_model.dart` (or wherever Report is defined)

**Interfaces:**
- Produces: Report model with `List<EvidenceFile>? evidence` field; new EvidenceFile class

- [ ] **Step 1: Locate the Report model class**

Find the main Report class definition (look for `class Report` in the models directory).

- [ ] **Step 2: Add EvidenceFile class**

Add this new class at the END of the report_model.dart file (or in the same file where Report is defined):

```dart
class EvidenceFile {
  final String filename;
  final String url;
  final String type; // 'image' or 'text'
  final int size;    // bytes
  final DateTime uploadedAt;

  EvidenceFile({
    required this.filename,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory EvidenceFile.fromJson(Map<String, dynamic> json) {
    return EvidenceFile(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      size: json['size'] ?? 0,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 3: Add evidence field to Report class**

Find the Report class constructor and field definitions. Add this field:

```dart
final List<EvidenceFile>? evidence;
```

Add it to the constructor parameter list:

```dart
Report({
  // ... existing parameters ...
  this.evidence,
});
```

- [ ] **Step 4: Update Report.fromJson factory**

Find the `factory Report.fromJson` method. Add this parsing:

```dart
evidence: json['evidence'] != null
    ? List<EvidenceFile>.from(
        (json['evidence'] as List?)?.map(
          (e) => EvidenceFile.fromJson(e as Map<String, dynamic>),
        ) ?? [],
      )
    : null,
```

Add this line in the correct alphabetical or logical position within the factory method.

- [ ] **Step 5: Update Report.toJson method**

If the Report class has a `toJson()` method, add:

```dart
if (evidence != null) 'evidence': evidence!.map((e) => e.toJson()).toList(),
```

- [ ] **Step 6: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/models/report_model.dart 2>&1 | tail -5
```

Expected: No errors (or only unrelated ones).

- [ ] **Step 7: Commit**

```bash
git add lib/models/report_model.dart
git commit -m "feat(model): add EvidenceFile class and evidence field to Report

New EvidenceFile class with fields: filename, url, type (image|text),
size, uploadedAt. Factory and toJson methods for JSON serialization.

Report model gains optional 'evidence' field (List<EvidenceFile>)
for storing attached evidence from reports."
```

---

### Task F2: Add Evidence Section to Report Dialog

**Files:**
- Modify: `lib/widgets/report_dialog.dart`
- Create: `lib/widgets/evidence_tile.dart`

**Interfaces:**
- Consumes: Report model with evidence field (from F1), ReportService (existing), file_picker package
- Produces: Report dialog with evidence section; required file picker; validation before submit

- [ ] **Step 1: Import necessary packages at top of report_dialog.dart**

Add these imports if not already present:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:bananatalk_app/models/report_model.dart';
```

- [ ] **Step 2: Add state variables to _ReportDialogState**

Add these fields after the existing `_descriptionController`:

```dart
final List<PlatformFile> _selectedFiles = [];
bool _isUploadingEvidence = false;
int _totalFileSize = 0; // in bytes

static const int MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB
static const int MAX_FILES = 5;
static const int MAX_TOTAL_SIZE = 25 * 1024 * 1024; // 25 MB
static const List<String> ALLOWED_EXTENSIONS = ['jpg', 'jpeg', 'png', 'txt'];
```

- [ ] **Step 3: Add file picker method**

Add this method to `_ReportDialogState`:

```dart
Future<void> _pickFiles() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ALLOWED_EXTENSIONS,
    allowMultiple: true,
  );

  if (result == null || result.files.isEmpty) {
    return; // User cancelled
  }

  // Validate and add files
  for (final file in result.files) {
    // Check if already at max files
    if (_selectedFiles.length >= MAX_FILES) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Max $MAX_FILES files per report'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      break;
    }

    // Check file size
    if (file.size > MAX_FILE_SIZE) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is too large (max 5 MB)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      continue;
    }

    // Check total size
    if (_totalFileSize + file.size > MAX_TOTAL_SIZE) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total size would exceed 25 MB'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      break;
    }

    // Add file
    setState(() {
      _selectedFiles.add(file);
      _totalFileSize += file.size;
    });
  }
}

void _removeFile(int index) {
  setState(() {
    _totalFileSize -= _selectedFiles[index].size;
    _selectedFiles.removeAt(index);
  });
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
```

- [ ] **Step 4: Add evidence UI section to build method**

Find the build method and locate where the description field is rendered. After the description `TextFormField`, add this new section:

```dart
const SizedBox(height: 16),
Text(
  'Add Evidence (Required)',
  style: Theme.of(context).textTheme.titleMedium,
),
const SizedBox(height: 8),
Text(
  'Upload screenshots or text files to support your report',
  style: Theme.of(context).textTheme.bodySmall,
),
const SizedBox(height: 12),

// File picker button
ElevatedButton.icon(
  onPressed: _selectedFiles.length >= MAX_FILES ? null : _pickFiles,
  icon: const Icon(Icons.attach_file),
  label: Text(
    'Add Files (${_selectedFiles.length}/$MAX_FILES)',
  ),
),

const SizedBox(height: 12),

// Display selected files
if (_selectedFiles.isNotEmpty) ...[
  Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: List.generate(
        _selectedFiles.length,
        (index) => EvidenceTile(
          file: _selectedFiles[index],
          onRemove: () => _removeFile(index),
        ),
      ),
    ),
  ),
  const SizedBox(height: 12),
],

// File size progress
Text(
  'Total: ${_formatFileSize(_totalFileSize)} / ${_formatFileSize(MAX_TOTAL_SIZE)}',
  style: Theme.of(context).textTheme.labelSmall,
),
```

- [ ] **Step 5: Update submit button validation**

Find where the submit button is defined. Update it to require evidence:

```dart
// Add this check at the start of _submitReport:
if (_selectedFiles.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please attach at least one file as evidence'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

- [ ] **Step 6: Update _submitReport to upload evidence**

After the report is created successfully (you have `reportId` or `report._id`), add evidence upload:

```dart
// Assuming the report creation response includes the report ID
final reportId = /* extract from response */;

// Upload evidence files
setState(() {
  _isUploadingEvidence = true;
});

try {
  for (final file in _selectedFiles) {
    await _reportService.uploadEvidence(
      reportId: reportId,
      file: file,
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted, but some evidence failed to upload'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} finally {
  setState(() {
    _isUploadingEvidence = false;
  });
  if (mounted) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

- [ ] **Step 7: Create EvidenceTile widget**

Create new file `lib/widgets/evidence_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class EvidenceTile extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const EvidenceTile({
    Key? key,
    required this.file,
    required this.onRemove,
  }) : super(key: key);

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isImage = file.extension != null &&
        ['jpg', 'jpeg', 'png'].contains(file.extension!.toLowerCase());
    
    return ListTile(
      leading: Icon(
        isImage ? Icons.image : Icons.description,
        color: Colors.green,
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_formatFileSize(file.size)),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onRemove,
      ),
    );
  }
}
```

- [ ] **Step 8: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/widgets/report_dialog.dart lib/widgets/evidence_tile.dart 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 9: Commit**

```bash
git add lib/widgets/report_dialog.dart lib/widgets/evidence_tile.dart
git commit -m "feat(report): add evidence attachment section to report dialog

New 'Add Evidence' section in report dialogs (all types).
- File picker supports JPG, PNG, TXT
- Validates: max 5 MB per file, max 5 files, max 25 MB total
- Evidence required before submit button enabled
- Shows file list with remove option
- Displays total size used / limit

New EvidenceTile widget displays individual file in list."
```

---

### Task F3: Add ReportService uploadEvidence Method

**Files:**
- Modify: `lib/services/report_service.dart`

**Interfaces:**
- Consumes: PlatformFile from file_picker, existing http client setup
- Produces: uploadEvidence(reportId, file) method that POSTs to backend

- [ ] **Step 1: Locate ReportService class**

Open `lib/services/report_service.dart`.

- [ ] **Step 2: Add uploadEvidence method**

Add this method to the ReportService class:

```dart
/// Upload evidence file to a report
/// POST /api/v1/reports/:reportId/evidence
static Future<Map<String, dynamic>> uploadEvidence({
  required String reportId,
  required PlatformFile file,
}) async {
  try {
    final token = await _getToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    final url = Uri.parse(
      '${Endpoints.baseURL}/api/v1/reports/$reportId/evidence',
    );

    // Read file bytes
    final bytes = await file.readAsBytes();

    // Create multipart request
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: MediaType.parse(_getMimeType(file.extension ?? '')),
      ),
    );

    // Send request
    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'data': data['data'] ?? {},
      };
    } else {
      return {
        'success': false,
        'message': data['error'] ?? 'Failed to upload evidence',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}

/// Get MIME type from file extension
static String _getMimeType(String extension) {
  final ext = extension.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'txt':
      return 'text/plain';
    default:
      return 'application/octet-stream';
  }
}
```

Make sure these imports are at the top of the file:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'package:file_picker/file_picker.dart';
```

- [ ] **Step 3: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/services/report_service.dart 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/services/report_service.dart
git commit -m "feat(service): add uploadEvidence method to ReportService

POST /api/v1/reports/:reportId/evidence uploads a single file.
Handles multipart form-data with proper MIME types.
Returns evidence metadata (filename, url, type, size, uploadedAt)."
```

---

### Task F4: Add Evidence Display to Admin Reports Detail Pane

**Files:**
- Modify: `lib/pages/reports/admin_reports_screen.dart`
- Create: `lib/widgets/report_evidence_section.dart`

**Interfaces:**
- Consumes: Report model with evidence field (from F1), EvidenceFile class
- Produces: Evidence section in admin report detail pane with image/text previews

- [ ] **Step 1: Create ReportEvidenceSection widget**

Create new file `lib/widgets/report_evidence_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/report_model.dart';

class ReportEvidenceSection extends StatefulWidget {
  final List<EvidenceFile>? evidence;

  const ReportEvidenceSection({
    Key? key,
    this.evidence,
  }) : super(key: key);

  @override
  State<ReportEvidenceSection> createState() => _ReportEvidenceSectionState();
}

class _ReportEvidenceSectionState extends State<ReportEvidenceSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.evidence == null || widget.evidence!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Evidence: None provided',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Evidence (${widget.evidence!.length} file${widget.evidence!.length > 1 ? 's' : ''})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...widget.evidence!.asMap().entries.map((entry) {
          final file = entry.value;
          return EvidenceFileView(file: file);
        }).toList(),
      ],
    );
  }
}

class EvidenceFileView extends StatefulWidget {
  final EvidenceFile file;

  const EvidenceFileView({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<EvidenceFileView> createState() => _EvidenceFileViewState();
}

class _EvidenceFileViewState extends State<EvidenceFileView> {
  bool _isExpanded = false;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.file.type == 'image';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header
          GestureDetector(
            onTap: isImage ? () => _showImageModal(context) : null,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    isImage ? Icons.image : Icons.description,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.file.filename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _formatFileSize(widget.file.size),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  if (isImage)
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _showImageModal(context),
                      iconSize: 18,
                    ),
                  if (!isImage)
                    IconButton(
                      icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() => _isExpanded = !_isExpanded);
                      },
                    ),
                ],
              ),
            ),
          ),

          // Text preview (for text files)
          if (!isImage && _isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: FutureBuilder<String>(
                  future: _loadTextContent(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Error loading file: ${snapshot.error}');
                    }
                    final content = snapshot.data ?? '';
                    return SelectableText(
                      content,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 20,
                      textScaleFactor: 0.9,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<String> _loadTextContent() async {
    try {
      // Fetch from URL
      final response = await http.get(Uri.parse(widget.file.url));
      if (response.statusCode == 200) {
        return response.body;
      }
      return 'Failed to load content';
    } catch (e) {
      return 'Error: $e';
    }
  }

  void _showImageModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.file.filename,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  widget.file.url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Failed to load image'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Add imports at the top of the file:

```dart
import 'package:http/http.dart' as http;
```

- [ ] **Step 2: Import ReportEvidenceSection in admin_reports_screen.dart**

At the top of `admin_reports_screen.dart`, add:

```dart
import 'package:bananatalk_app/widgets/report_evidence_section.dart';
```

- [ ] **Step 3: Add evidence section to detail pane**

In `admin_reports_screen.dart`, find where the report detail pane is built (look for where report description/reason is shown). Add this section at the bottom of the detail view:

```dart
const SizedBox(height: 16),
const Divider(),
ReportEvidenceSection(evidence: report['evidence']),
```

Adjust the key (`report['evidence']`) based on how your report object is structured in your code.

- [ ] **Step 4: Verify syntax**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_flutter_application/bananatalk_app
flutter analyze lib/widgets/report_evidence_section.dart lib/pages/reports/admin_reports_screen.dart 2>&1 | tail -5
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/report_evidence_section.dart lib/pages/reports/admin_reports_screen.dart
git commit -m "feat(admin): add evidence display to report detail pane

New ReportEvidenceSection widget shows uploaded evidence files.
- Images display as thumbnails; tap to open fullscreen with zoom
- Text files show preview (first 500 chars), expandable
- Displays filename + file size for each
- 'None provided' if no evidence attached

Admin detail pane now includes evidence section at bottom."
```

---

### Task G1: End-to-End Integration Test

**Files:**
- Test: Manual smoke test (no automated tests in this wave)

**Interfaces:**
- Consumes: All previous tasks (B1-B3, F1-F4)
- Produces: Verified workflow from user report submission to admin review

- [ ] **Step 1: Backend smoke test — evidence upload**

```bash
cd /Users/davis/Desktop/Personal/language_exchange_backend_application
npm run dev &
```

Wait for server to start.

- [ ] **Step 2: Create a test report**

```bash
TOKEN="<your-user-token>"
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/reports \
  -d '{
    "type": "user",
    "reportId": "<any-user-id>",
    "reportedUser": "<any-user-id>",
    "reason": "harassment"
  }' | jq '.data._id'
```

Note the returned report ID (e.g., `REPORT_ID`).

- [ ] **Step 3: Upload evidence to the report**

Create a test image file:

```bash
# Create a simple test image (100x100 PNG)
python3 -c "
import struct
import zlib

# Minimal PNG header and data
width, height = 100, 100
raw = b''.join(
  bytes([0] + [255, 0, 0] * width) for _ in range(height)  # Red pixels
)
compressed = zlib.compress(raw)

# PNG structure
png = b'\\x89PNG\\r\\n\\x1a\\n'
ihdr = struct.pack('>IIBBBBB', 13, width, height, 8, 2, 0, 0, 0)
png += b'IHDR' + ihdr + struct.pack('>I', zlib.crc32(b'IHDR' + ihdr) & 0xffffffff)
png += struct.pack('>I', len(compressed)) + b'IDAT' + compressed
png += struct.pack('>I', zlib.crc32(b'IDAT' + compressed) & 0xffffffff)
png += b'IEND\\xae\\x42\\x60\\x82'

with open('/tmp/test.png', 'wb') as f:
    f.write(png)
"

# Upload the image
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/test.png" \
  http://localhost:5000/api/v1/reports/REPORT_ID/evidence | jq '.'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "filename": "test.png",
    "url": "https://my-projects-media.sfo3.cdn.digitaloceanspaces.com/reports/...",
    "type": "image",
    "size": 1234,
    "uploadedAt": "2026-07-09T15:30:00Z"
  }
}
```

- [ ] **Step 4: Upload a text file**

```bash
echo "This is evidence text" > /tmp/evidence.txt

curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/evidence.txt" \
  http://localhost:5000/api/v1/reports/REPORT_ID/evidence | jq '.'
```

- [ ] **Step 5: Verify evidence is stored in the report**

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:5000/api/v1/reports/REPORT_ID | jq '.data.evidence'
```

Expected: Array with 2 items (image + text).

- [ ] **Step 6: Test validation — reject invalid file type**

```bash
echo "invalid data" > /tmp/invalid.exe
curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/invalid.exe" \
  http://localhost:5000/api/v1/reports/REPORT_ID/evidence | jq '.message'
```

Expected: "Invalid file type. Allowed: JPG, PNG, TXT"

- [ ] **Step 7: Test validation — reject oversized file**

```bash
dd if=/dev/zero of=/tmp/large.jpg bs=1M count=6

curl -s -X POST -H "Authorization: Bearer $TOKEN" \
  -F "file=@/tmp/large.jpg" \
  http://localhost:5000/api/v1/reports/REPORT_ID/evidence | jq '.message'
```

Expected: "File too large. Max 5 MB per file"

- [ ] **Step 8: Test resolution and evidence cleanup**

Get an admin token (or use an existing admin user):

```bash
ADMIN_TOKEN="<admin-token>"

# Resolve the report
curl -s -X PUT -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  http://localhost:5000/api/v1/reports/REPORT_ID/resolve \
  -d '{"action": "no_violation", "notes": "test"}' | jq '.success'
```

- [ ] **Step 9: Verify evidence was deleted**

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:5000/api/v1/reports/REPORT_ID | jq '.data.evidence'
```

Expected: `[]` (empty array)

- [ ] **Step 10: Flutter smoke test — user flow**

1. **Report dialog test:**
   - Open any report dialog (report a user/message/etc.)
   - Verify "Add Evidence (Required)" section appears below description
   - Tap "Add Files" button
   - Select a JPG/PNG from device
   - Verify file appears in list with size
   - Verify submit button is ENABLED (evidence attached)
   - Try to clear all files — verify submit button is DISABLED

2. **File validation test:**
   - Try to select a .exe file — verify rejection toast
   - Try to select a file >5 MB — verify rejection toast
   - Select 5 valid files — verify submit is enabled
   - Try to add 6th file — verify error toast

3. **Report submission test:**
   - Complete a full report with evidence
   - Verify "Uploading evidence..." loader appears
   - Verify report submits successfully
   - Check backend logs — verify files uploaded to Spaces

4. **Admin detail pane test:**
   - Log in as admin
   - Open the report from step 3 in AdminReportsScreen
   - Scroll to Evidence section at bottom
   - Verify image displays as thumbnail
   - Tap image → verify fullscreen modal with zoom
   - Verify text file shows preview with expand/collapse
   - Resolve the report → verify evidence section clears

- [ ] **Step 11: Commit test results**

```bash
git add -A
git commit -m "test(e2e): verify report evidence attachment end-to-end

Manual smoke tests:
- Backend: evidence upload validation, storage, cleanup on resolve
- Flutter: evidence section UI, file picker, validation, admin preview
- Integration: full report flow from user submission to admin review

All scenarios passing."
```

---

## Spec Coverage Checklist

- ✅ File constraints (JPG, PNG, TXT; 5 MB; 5 files; 25 MB total)
- ✅ Flutter frontend: report dialog evidence section, required before submit
- ✅ Flutter frontend: admin detail pane evidence display (images + text)
- ✅ Backend: Report schema with evidence field
- ✅ Backend: POST /api/v1/reports/:reportId/evidence endpoint
- ✅ Backend: Evidence auto-delete on report resolution
- ✅ Backend: Backward compatibility (optional on backend)
- ✅ Reuse DigitalOcean Spaces infrastructure (uploadToSpaces)
- ✅ Error handling (file validation, upload failures)
- ✅ Integration test (end-to-end flow)

---

## Rollback Strategy

If implementation breaks:
1. Revert backend commits (B1, B2, B3)
2. Revert Flutter commits (F1, F2, F3, F4)
3. Evidence files already in Spaces can be manually deleted via S3 CLI if needed
4. Reports without evidence are fully functional (backward compatible)

---
