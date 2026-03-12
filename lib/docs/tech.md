⚙️

**TECHNOLOGY STACK**

Project Management Mobile App

**Flutter • Firebase • SQLite**

Version 1.0 | March 2026

# **1\. Technology Stack Overview**

This document defines the complete technology stack for the Project Management Mobile App. Three core technologies work together in clearly separated layers, each with a distinct responsibility.

| 🐦<br><br>**FLUTTER**<br><br>UI Layer<br><br>All screens, navigation & animations | 🔥<br><br>**FIREBASE**<br><br>Cloud Layer<br><br>Auth, project data & real-time sync | 🗄️<br><br>**SQLITE**<br><br>Local Layer<br><br>Attachments & photos stored on-device |
| --- | --- | --- |

**Architecture Principle**

Each layer has a clear, non-overlapping responsibility. Flutter renders the UI and bridges both databases. Firebase stores all project text data in the cloud. SQLite stores binary files locally on the device. They never conflict because their jobs are entirely different.

**🐦 Section 2 - Flutter (UI Layer)**

## **2.1 What Flutter Does in This App**

- Builds and renders all 15 screens of the app
- Manages all navigation between screens using go_router
- Handles animations - progress bars, chart transitions, Gantt timeline
- Connects to Firebase for all cloud data read and write operations
- Connects to SQLite for local attachment read and write operations
- Triggers biometric authentication (fingerprint and Face ID)
- Schedules and displays local push notifications for task reminders
- Generates PDF reports for export and sharing

## **2.2 Why Flutter Is the Right Choice**

| **Advantage** | **Benefit to This App** |
| --- | --- |
| Single codebase | One codebase runs on both Android and iOS - no duplication of work |
| 60fps performance | Smooth animations on progress bars, Gantt chart, and analytics charts |
| Rich widget library | Pre-built UI components speed up development significantly |
| Hot reload | See UI changes instantly during development without restarting the app |
| Strong package ecosystem | Excellent packages for charts, biometrics, file picking, and PDF generation |
| Dart language | Strongly typed - fewer bugs in financial calculations and date logic |

## **2.3 Flutter Packages Required**

All packages are installed via pubspec.yaml and downloaded from pub.dev.

**Navigation & State Management**

| **Package** | **Purpose** |
| --- | --- |
| go_router | Declarative routing and navigation between all 15 screens |
| riverpod | State management - shares and manages data across all screens |
| flutter_riverpod | Flutter integration layer for Riverpod |

**Firebase Integration**

| **Package** | **Purpose** |
| --- | --- |
| firebase_core | Required base package - must be initialized before all other Firebase services |
| firebase_auth | Login, Sign Up, Google Sign-In, Apple Sign-In, session management |
| cloud_firestore | Read and write all project data to Firestore cloud database |
| firebase_analytics | Track app usage and view crash reports (optional but free) |

**Local Database - SQLite**

| **Package** | **Purpose** |
| --- | --- |
| sqflite | SQLite database engine built into the app on the device |
| path_provider | Locate the correct local directory to store the SQLite database file |
| path | Build correct file system paths across Android and iOS |

**Security & Biometrics**

| **Package** | **Purpose** |
| --- | --- |
| local_auth | Fingerprint and Face ID authentication - biometric lock and unlock |
| flutter_secure_storage | Store PIN codes and session tokens securely in the device keychain |

**File Handling & Attachments**

| **Package** | **Purpose** |
| --- | --- |
| file_picker | Pick PDFs, Word documents, and spreadsheets from device storage |
| image_picker | Pick photos from camera or gallery (receipt photos, profile avatar) |
| open_file | Open and preview attached files inline within the app |
| mime | Detect file type (pdf, jpg, mp3, etc.) from file bytes automatically |

**UI Components & Charts**

| **Package** | **Purpose** |
| --- | --- |
| fl_chart | Bar charts, line charts, and donut charts for the Analytics page |
| syncfusion_flutter_gantt | Gantt timeline visual inside the Project Detail page |
| flutter_slidable | Swipe-to-delete gesture on task and subtask list items |
| shimmer | Loading skeleton animation while project data loads from Firestore |
| cached_network_image | Cache and display profile images smoothly and efficiently |

**Notifications & Date Handling**

| **Package** | **Purpose** |
| --- | --- |
| flutter_local_notifications | Schedule and display subtask deadline reminders |
| intl | Format dates, currencies, and numbers according to user locale |
| timezone | Handle correct timezones when scheduling notifications |

**Export & Sharing**

| **Package** | **Purpose** |
| --- | --- |
| pdf | Generate formatted PDF project and financial reports on-device |
| share_plus | Share reports via WhatsApp, Email, or any installed share target |
| excel | Generate Excel and CSV financial exports |

**Utilities**

| **Package** | **Purpose** |
| --- | --- |
| uuid | Generate unique IDs for projects, phases, tasks, and subtasks |
| connectivity_plus | Detect online and offline status for sync management |
| permission_handler | Request storage, camera, and notification permissions from the OS |

**🔥 Section 3 - Firebase (Cloud Layer)**

## **3.1 What Firebase Stores**

Firebase stores all project-related text data. Binary files (attachments, photos) are excluded and handled by SQLite instead.

| **Data Type** | **Stored in Firebase?** | **Reason** |
| --- | --- | --- |
| User profile (text fields) | Yes - Firestore | Name, email, phone - needs cloud sync |
| Projects | Yes - Firestore | Core app data - must be cloud-backed and synced |
| Phases | Yes - Firestore | Nested under projects in Firestore |
| Tasks | Yes - Firestore | Nested under phases in Firestore |
| Subtasks | Yes - Firestore | Nested under tasks in Firestore |
| Clients and contacts | Yes - Firestore | Reused across multiple projects |
| Payment records | Yes - Firestore | Financial history must be safe in the cloud |
| Expenses | Yes - Firestore | Financial data needs cloud backup |
| Activity logs | Yes - Firestore | Audit trail per project - must be persistent |
| Project notes | Yes - Firestore | Text notes, not binary files |
| File attachments | No - SQLite only | Binary files stored locally on device |
| Receipt photos | No - SQLite only | Binary images stored locally |
| Profile avatar image | No - SQLite (default) | Stored locally; optional cloud backup |

## **3.2 Firebase Services Used**

**Service 1 - Firebase Authentication**

- Handles all user login, sign-up, and session management automatically
- Supported sign-in methods: Email + Password, Google Sign-In, Apple Sign-In
- Forgot Password flow is handled entirely by Firebase - no custom code needed
- Each user receives a unique uid - all Firestore data is stored under this uid
- Session tokens are stored securely - user stays logged in across app restarts

**Service 2 - Cloud Firestore**

The main database for all project data. Firestore is a NoSQL document database - data is organised in collections and nested subcollections.

- Real-time listeners - the Flutter UI updates instantly when data changes in Firestore
- Built-in offline support - the app works without internet and syncs when connection returns
- Scales automatically - no database server to set up or maintain
- Security Rules - enforced server-side so users can only access their own data

**Service 3 - Firebase Analytics (Optional)**

- Tracks which features are used most within the app
- Shows crash reports and error logs for debugging
- Completely free - requires no additional configuration cost

## **3.3 Firestore Data Structure**

All data is nested under the authenticated user's uid. This ensures complete data isolation between different users.

Firestore Root

│

└── users/

└── {uid}/

├── profile/

│ └── name, email, phone, createdAt

│

├── projects/

│ └── {projectId}/

│ ├── name, category, status, tags\[\]

│ ├── totalPrice, advanceAmount

│ ├── startDate, endDate

│ ├── clientId, description, isPinned

│ │

│ └── phases/

│ └── {phaseId}/

│ ├── name, startDate, endDate, status

│ └── tasks/

│ └── {taskId}/

│ ├── name, priority, startDate, endDate

│ └── subtasks/

│ └── {subtaskId}/

│ ├── name, startDate, endDate

│ ├── isDone, reminderDate

│

├── clients/

│ └── {clientId}/

│ └── name, company, email, phone, location

│

├── payments/

│ └── {paymentId}/

│ └── projectId, amount, date, status, label

│

├── expenses/

│ └── {expenseId}/

│ └── projectId, name, amount, date, category

│

├── activityLogs/

│ └── {logId}/

│ └── projectId, action, timestamp

│

└── notes/

└── {noteId}/

└── projectId, content, createdAt

## **3.4 Firestore Security Rules**

Security Rules are set in the Firebase Console and enforced server-side. They ensure every user can only read and write their own data - no exceptions.

rules_version = '2';

service cloud.firestore {

match /databases/{database}/documents {

// Each user can ONLY access their own data

match /users/{uid}/{document=\*\*} {

allow read, write: if request.auth != null

&& request.auth.uid == uid;

}

// Block all other access by default

match /{document=\*\*} {

allow read, write: if false;

}

}

}

## **3.5 Offline Behaviour**

- When offline: Firestore serves the last successfully synced cached data
- User can view all projects, tasks, subtasks, and financial data normally
- Any changes made while offline are queued locally by Firestore
- When internet returns: Firestore automatically pushes all queued changes to the cloud
- SQLite attachments always work offline since they are stored on-device

**🗄️ Section 4 - SQLite (Local Built-in Layer)**

## **4.1 Role of SQLite in This App**

SQLite is a built-in database that lives entirely inside the app on the user's device. It requires no internet connection and is specifically used to store binary file data that is unsuitable for Firestore.

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Why SQLite for Attachments - Not Firebase Storage?</strong></p><ul><li>Attachments are binary files (PDFs, images, audio) - Firestore only stores text and numbers</li><li>Storing files locally means they open instantly with no network delay</li><li>Sensitive documents (contracts, NDAs) never leave the device - maximum privacy</li><li>No storage costs - SQLite is free and limited only by device storage space</li><li>Works fully offline - attachments are always accessible regardless of internet connection</li></ul></th></tr></tbody></table></div>

## **4.2 What SQLite Stores**

| **Table** | **Data Stored** | **Linked To** |
| --- | --- | --- |
| attachments | File bytes - PDF, image, audio, URLs | Project / Phase / Task / Subtask ID |
| profile_cache | Profile avatar image bytes | Firebase Auth uid |
| payment_receipts | Receipt photo bytes | Firestore payment record ID |

## **4.3 SQLite Database Schema**

Three tables are created automatically when the app launches for the first time. The database file is stored in the app's private directory on the device.

**Table 1 - attachments**

CREATE TABLE attachments (

id TEXT PRIMARY KEY, -- UUID generated by the app

project_id TEXT NOT NULL, -- Links to Firestore project document ID

phase_id TEXT, -- Optional: links to phase

task_id TEXT, -- Optional: links to task

subtask_id TEXT, -- Optional: links to subtask

file_name TEXT NOT NULL, -- Display name e.g. Contract.pdf

file_type TEXT NOT NULL, -- pdf, jpg, png, mp3, url

file_data BLOB, -- Actual file bytes (null for URLs)

file_url TEXT, -- For external links and URLs

file_size INTEGER, -- Size in bytes

uploaded_at TEXT NOT NULL, -- ISO 8601 date string

notes TEXT -- Optional note about the attachment

);

**Table 2 - profile_cache**

CREATE TABLE profile_cache (

uid TEXT PRIMARY KEY, -- Firebase Auth user ID

display_name TEXT, -- User full name

email TEXT, -- User email address

phone TEXT, -- User phone number

avatar_data BLOB, -- Profile photo image bytes

last_synced TEXT -- ISO date of last Firestore sync

);

**Table 3 - payment_receipts**

CREATE TABLE payment_receipts (

id TEXT PRIMARY KEY, -- UUID

payment_id TEXT NOT NULL, -- Links to Firestore payment document ID

receipt_data BLOB, -- Receipt photo image bytes

uploaded_at TEXT -- ISO 8601 date string

);

## **4.4 Attachment Policies**

- Maximum size per attachment: 10 MB - prevents excessive device storage usage
- App shows a warning if user tries to attach a file larger than 10 MB
- Voice memos are capped at 2 minutes recording length
- User can view total attachment storage used from the Settings page
- User can delete individual attachments to free up device space

# **5\. Key Data Flows - All Three Layers Working Together**

These flows describe exactly what happens at each layer when the user performs a key action in the app.

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 1 - User Creates a New Project</strong></p><ul><li>Step 1: User fills the project form in Flutter UI and taps Save</li><li>Step 2: Flutter validates all required fields (name, category, start date)</li><li>Step 3: Flutter writes the project document to Firestore under users/{uid}/projects/</li><li>Step 4: Firestore real-time listener detects the new document immediately</li><li>Step 5: Flutter UI updates - new project card appears on Home Dashboard instantly</li><li>Step 6: No SQLite interaction - projects are cloud data only</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 2 - User Attaches a PDF to a Project</strong></p><ul><li>Step 1: User taps Add Attachment on the Project Detail screen</li><li>Step 2: Flutter opens file_picker - user selects a PDF from device storage</li><li>Step 3: Flutter reads the file bytes into memory</li><li>Step 4: Flutter saves the file bytes into the SQLite attachments table on-device</li><li>Step 5: Flutter saves attachment metadata (name, type, size, date, project_id) to Firestore</li><li>Step 6: UI shows the new attachment in the attachments list immediately</li><li>Step 7: Next time the project opens - metadata loads from Firestore, file bytes load from SQLite</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 3 - App Launch with Biometric Authentication</strong></p><ul><li>Step 1: App launches - Flutter checks if a valid session token exists in secure storage</li><li>Step 2: Session is active - Flutter shows the biometric lock screen</li><li>Step 3: User places finger on sensor - local_auth package handles the fingerprint check</li><li>Step 4: Biometric passes - Flutter navigates to the Home Dashboard</li><li>Step 5: Firestore real-time listeners activate - project data loads from cloud</li><li>Step 6: SQLite is immediately ready for any attachment reads</li><li>Step 7: If biometric fails 3 times - Flutter falls back to PIN or password entry</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 4 - App Used While Offline</strong></p><ul><li>Step 1: User opens the app with no internet connection</li><li>Step 2: connectivity_plus detects the offline status and shows an offline indicator</li><li>Step 3: Firestore serves cached data from the last successful sync automatically</li><li>Step 4: User can view all projects, tasks, subtasks, and financial data normally</li><li>Step 5: SQLite attachments work perfectly - they are always stored on the device</li><li>Step 6: User makes changes - Firestore queues them locally on-device</li><li>Step 7: Internet returns - Firestore automatically pushes all queued changes to cloud</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 5 - Subtask Marked as Done (Auto Progress Update)</strong></p><ul><li>Step 1: User taps the checkbox on a subtask in the Flutter UI</li><li>Step 2: Flutter immediately updates the UI (optimistic update - feels instant to user)</li><li>Step 3: Flutter writes isDone = true to the subtask document in Firestore</li><li>Step 4: Flutter recalculates Task progress = average isDone % of all its subtasks</li><li>Step 5: Flutter recalculates Phase progress = average progress % of all its tasks</li><li>Step 6: Flutter recalculates Project progress = average progress % of all its phases</li><li>Step 7: Progress bars on Project Detail and Home Dashboard update automatically</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Flow 6 - Export Project as PDF Report</strong></p><ul><li>Step 1: User taps Export on Project Detail or from the Settings page</li><li>Step 2: Flutter fetches full project data from Firestore (phases, tasks, subtasks)</li><li>Step 3: Flutter fetches financial data (payments, expenses) from Firestore</li><li>Step 4: Flutter uses the pdf package to generate a formatted PDF in memory</li><li>Step 5: PDF is temporarily saved to device storage using path_provider</li><li>Step 6: Flutter opens share_plus - user selects WhatsApp, Email, or another target</li><li>Step 7: Temporary PDF file is deleted from device storage after sharing completes</li></ul></th></tr></tbody></table></div>

# **6\. Key Architecture Decisions**

These decisions were made deliberately to optimize for privacy, performance, cost, and development simplicity.

| **Decision** | **Choice Made** | **Reason** |
| --- | --- | --- |
| State management | Riverpod | Modern, clean, testable - ideal for this app size |
| Attachment storage | SQLite only (local) | Binary files, privacy, offline access, zero cost |
| Profile avatar | SQLite default, optional Firebase Storage backup | Fast local display with cloud backup as user option |
| Attachment max size | 10 MB per file | Prevents excessive device storage consumption |
| Auth sign-in methods | Email + Google + Apple | Covers all users; Apple required for iOS App Store |
| Firestore structure | Nested subcollections under uid | Clean data isolation and simple security rules |
| Offline support | Firestore built-in cache | No custom code needed - Firestore handles it automatically |
| PDF generation | On-device using pdf package | No server required; works offline; instant generation |
| Security enforcement | Firestore Security Rules (server-side) | Users can never access each other's data |
| Progress calculation | Calculated in Flutter UI layer | Fast, works offline, no extra Firestore reads needed |

# **7\. Recommended Development Order**

Build the app in this sequence to ensure each foundation layer is solid before adding features on top of it.

| **Phase** | **What to Build** | **Technologies** |
| --- | --- | --- |
| Phase 1 | Firebase project setup, Auth configuration, Firestore Security Rules | Firebase Console |
| Phase 2 | Flutter project setup, folder structure, Riverpod, go_router routing | Flutter, Dart |
| Phase 3 | Login, Sign Up, and Forgot Password screens | Firebase Auth, Flutter |
| Phase 4 | Biometric lock screen, PIN fallback, secure session storage | local_auth, flutter_secure_storage |
| Phase 5 | SQLite setup - create all 3 tables on first app launch | sqflite, path_provider |
| Phase 6 | Home Dashboard - read projects from Firestore, display cards | Firestore, Flutter |
| Phase 7 | Add and Edit Project - write to Firestore, 4-level hierarchy | Firestore, Flutter |
| Phase 8 | Project Detail - phases, tasks, subtasks, auto progress bars | Firestore, Flutter |
| Phase 9 | Attachment system - file picker, save to SQLite, metadata to Firestore | sqflite, file_picker |
| Phase 10 | Finance and Pocket page - payments, expenses, net profit | Firestore, Flutter |
| Phase 11 | Analytics page - bar, line, and donut charts with time filters | fl_chart, Firestore |
| Phase 12 | Notifications - subtask reminders and overdue alerts | flutter_local_notifications |
| Phase 13 | PDF export and sharing feature | pdf package, share_plus |
| Phase 14 | Dark mode, Settings, Client Book, Project Templates | Flutter, Firestore |
| Phase 15 | Testing, performance optimization, and App Store submission | Flutter testing tools |

# **8\. Complete Technology Reference Summary**

| **Category** | **Technology** | **Responsibility** | **Works Offline?** |
| --- | --- | --- | --- |
| UI & All Screens | Flutter (Dart) | All 15 screens, navigation, animations | Yes |
| Authentication | Firebase Auth | Login, Sign Up, Google, Apple, sessions | Cached |
| Cloud Database | Cloud Firestore | Projects, phases, tasks, subtasks, finances | Yes (cached) |
| Local Database | SQLite via sqflite | Attachments, receipts, profile avatar photo | Always |
| Biometric Auth | local_auth | Fingerprint, Face ID, app lock and unlock | Always |
| Secure Storage | flutter_secure_storage | PIN, session tokens, auth secrets | Always |
| File Attachments | file_picker + sqflite | Pick and store PDFs, images, audio files | Always |
| Notifications | flutter_local_notifications | Subtask reminders, overdue task alerts | Always |
| Charts | fl_chart | Analytics bar, line, and donut charts | Yes |
| Gantt Timeline | syncfusion_flutter_gantt | Visual timeline in Project Detail screen | Yes |
| PDF Export | pdf package | Generate project and financial PDF reports | Yes |
| Sharing | share_plus | Share reports via WhatsApp, Email, etc. | Needs internet |
| State Management | Riverpod | App-wide data state across all screens | Yes |
| Navigation | go_router | Screen routing and deep linking | Yes |

**Stack is Defined. Time to Build. 🚀**

**Flutter • Firebase • SQLite**

Project Management App - Version 1.0 | March 2026