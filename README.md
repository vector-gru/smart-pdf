# smart-pdf
`This pdf scanner viewer project is primarily for personal use`

A simple, offline PDF scanner and reader for Android and iOS.

Description
-----------
smart-pdf is a lightweight mobile app (Flutter) for scanning documents with the device camera or importing images from the gallery, converting them to multi-page PDF documents, and reading or sharing PDFs locally. The app is designed to work fully offline for its core features. Advanced features (PDF editing, cloud sync, OCR search) can be gated as premium features later.

Core features (MVP)
-------------------
- Scan pages using device camera and convert them to PDF.
- Import images from the device gallery.
- Multiple images → one multi-page PDF (each image = one page).
- Automatic document edge detection + auto-crop on capture.
- Manual cropping and rotation after capture.
- Rename documents before or after saving.
- Edit saved documents: add/remove pages, rename.
- Share documents (Android/iOS share sheet).
- Open and read existing PDF files (PDF reader).
- From file list (home screen) user can: share, save to drive, export pages as JPEG, add/remove favourite, modify scan, rename, print, delete.
- Local-only data storage (no cloud sync in MVP).
- Simple navigation: bottom nav with Home, Files, Recent, Favorites; top appbar with search and Premium icon; hamburger menu for import/settings/etc.

Why this app
------------
Designed for personal use — quick, reliable scans and a pleasant reader experience without requiring internet access.

Screens & UX
-----------
- Home: list of saved PDFs (card/list). Each item shows thumbnail, title, pages count, and actions (favourite, share, menu).
- Viewer: read PDF with swipe/scroll, pinch-zoom, page jump.
- Scanner: camera preview with auto-crop overlay, capture button, quick retake.
- Edit Page: crop, rotate, reorder, delete, add page.
- Files: full file manager for all saved PDFs.
- Recent: recently opened/edited documents.
- Favorites: user-marked favourites.
- App menu (hamburger): Import files, Import images, Settings (enable/disable auto-crop), Theme (light/dark), Rate app, Language, Share app, Send feedback, Privacy policy.
- Top-right: Search (icon) to filter documents; Premium icon next to it for future in-app purchase flow.

Technical overview
------------------
- Flutter app targeting android & ios:
  - Flutter stable channel (use `flutter doctor` to ensure environment ready).
- PDF creation:
  - Generate PDF from images (each image -> one PDF page) using `pdf` package (dart_pdf) or similar.
- PDF viewing:
  - `pdfx`, `flutter_pdfview`, `syncfusion_flutter_pdfviewer`, or `pdf_render` (choose based on features you need).
- Image capture + scanning:
  - `camera` or `mobile_scanner` for capture.
  - Auto edge detection: `edge_detection`, `document_scanner_flutter`, or `google_ml_kit` for custom detection.
  - Cropping: `image_cropper` (or built-in custom crop UI if tighter control required).
- Image import:
  - `image_picker` or `file_picker`.
- File storage & metadata:
  - Files (PDFs) stored under app documents directory via `path_provider`.
  - Metadata (title, path, created_at, is_favorite, pages_count, thumbnail_path) stored in a lightweight DB: `sqflite` or `hive` (hive is simpler and faster for key-value style metadata).
- Share / Print:
  - `share_plus` for sharing.
  - `printing` for print and PDF conversion helpers.
- Save pages as JPEG:
  - Render PDF pages to images with `pdf_render` or render images directly before creating PDF (store each page image).
- Permissions:
  - `permission_handler` for camera, photos and storage access.
- Offline-first:
  - No remote sync for MVP. Local-only storage and in-app premium gating.

Recommended package list (starting point)
-----------------------------------------
- camera or mobile_scanner
- image_picker
- edge_detection or document_scanner_flutter or google_ml_kit (for edge detection)
- image_cropper
- pdf (dart_pdf) or printing (for PDF creation)
- pdfx or flutter_pdfview (for viewing)
- path_provider
- hive or sqflite
- share_plus
- permission_handler
- pdf_render (for exporting PDF pages to images)

Setup & run (local)
-------------------
1. Ensure Flutter is installed and working:
   flutter doctor -v

2. Clone this repository and open project:
   git clone git@github.com:vector-gru/smart-pdf.git
   cd smart-pdf

3. Install dependencies:
   flutter pub get

4. iOS-specific (macOS):
   cd ios
   pod install
   cd ..

5. Run app (select device or simulator/emulator):
   flutter devices
   flutter run

Build
-----
- Android (debug): flutter run -d <device-id>
- Android (release APK): flutter build apk --release
- Android (app bundle): flutter build appbundle --release
- iOS (release): flutter build ios --release (requires Xcode signing via Runner workspace)

Data & file conventions
----------------------
- App stores PDF files in: <AppDocuments>/smart_pdf/files/
- Thumbnails stored in: <AppDocuments>/smart_pdf/thumbs/
- Metadata stored in Hive or SQLite box/table: documents with fields:
  - id (uuid)
  - title
  - path (absolute)
  - created_at
  - updated_at
  - pages_count
  - thumbnail_path
  - is_favourite
  - last_opened_at

MVP flow & screen-by-screen mapping
-----------------------------------
1. Launch → Home (list of saved PDFs)
   - Floating action button (FAB): Start new scan / Import images.
   - Each list item: tap opens viewer; long-press or menu opens actions (rename, share, delete, export pages).

2. Scan flow:
   - Camera view (auto edge detection enabled by default if opt-in via settings).
   - Capture → apply auto-crop → show preview with ability to re-crop/rotate/delete/accept.
   - Add more pages or Save as PDF (prompt to name document).

3. Import images:
   - Pick multi images from gallery → show per-image editor (crop/rotate) → save as multi-page PDF.

4. Edit saved document:
   - Open document → Edit Pages → reorder/add/remove/replace pages → save changes.

Search & navigation
-------------------
- Top-right search icon reveals search bar to filter by title.
- Hamburger menu provides app-level actions.
- Bottom navigation: Home, Files, Recent, Favorites.

Permissions & platform notes
----------------------------
- Android: request CAMERA, READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE (depending on API level), MANAGE_EXTERNAL_STORAGE only if you must access broad storage (avoid if possible).
- iOS: NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription in Info.plist.
- iOS: use CocoaPods; test on real device for camera and file access behavior.

Testing
-------
- Manual testing for scanning & cropping across a set of real documents (different lighting/backgrounds).
- Unit tests for utilities (file naming, PDF generation).
- Integration tests (flutter_driver or integration_test) to cover capture → save → view → share.

Persistence & backup strategy (future)
-------------------------------------
- MVP: local-only with optional export to share/drive.
- Future: optional cloud backup & sync (premium) using encrypted uploads.

Monetization & premium ideas (future)
-------------------------------------
- Premium features (one-time or subscription):
  - Edit/modify existing PDF content (advanced editing).
  - OCR & searchable PDFs.
  - Cloud backup & sync across devices.
  - Remove ads (if/when ads are added).
  - Unlimited pages per document (if you limit in free tier).

Roadmap (high-level)
--------------------
1. MVP (v0.1): Camera capture, auto-crop, manual crop, rotate, multi-image → create PDF, view & share, local storage, rename, delete, favourites, search.
2. v0.2: Edit pages after save, export pages to JPEG, printing.
3. v0.3: Premium gating, OCR (searchable PDFs), cloud backup.
4. v1.0: Polish UI, accessibility improvements, translations.

Contributing
------------
Contributions, issues and feature requests are welcome. For code contributions:
- Fork the repo
- Create a feature branch
- Open a PR with a clear description and screenshots (if UI change)

License
-------
MIT — see LICENSE file.

Acknowledgements
----------------
This project uses several community-maintained Flutter packages and native platform APIs for camera, cropping, PDF generation and sharing. Please respect the licenses of third-party libraries used.

Contact
-------
Author: @vector-gru
Email: popelouis1@outlook.com
