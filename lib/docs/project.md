📱

**PROJECT MANAGEMENT APP**

Complete Design & Feature Specification

_Your Projects. Your Control._

Version 1.0 | March 2026

# **1\. Brand & Visual Identity**

The app uses a modern, professional visual identity designed to convey trust, clarity, and productivity on mobile devices.

## **1.1 Color Palette**

| **Color Role** | **Hex Code** | **Usage** |
| --- | --- | --- |
| Primary - Deep Indigo | #4F46E5 | Main buttons, headers, active states |
| Accent - Vibrant Amber | #F59E0B | CTAs, FAB button, highlights |
| Success - Emerald | #10B981 | Completed, fully paid, done states |
| Danger - Rose | #F43F5E | Overdue, unpaid balance, errors |
| Background | #F8FAFC | App background (light mode) |
| Dark Mode Background | #0F172A | App background (dark mode) |
| Card Surface | #FFFFFF | Card backgrounds with subtle shadow |
| Text Dark | #1E293B | Headings, primary text |
| Text Mid | #475569 | Body text, descriptions |
| Text Light | #94A3B8 | Captions, timestamps, placeholders |

## **1.2 Typography**

Font Family: Inter - clean, modern, highly readable on mobile screens across all sizes.

| **Text Style** | **Weight** | **Size** | **Usage** |
| --- | --- | --- | --- |
| Page Title | Bold | 24px | Screen headings |
| Section Title | Bold | 18px | Card and section headers |
| Body Text | Regular | 14px | Descriptions, details |
| Labels / Captions | Medium | 12px | Badges, tags, timestamps |
| Financial Figures | SemiBold | 16-18px | Amounts, prices, totals |

## **1.3 UI Style Rules**

- Corner radius: 16px on cards, 12px on buttons, 8px on input fields
- Shadows: Subtle drop shadow on cards (0px 2px 8px rgba(0,0,0,0.08))
- Spacing: 16px standard padding inside cards, 24px between sections
- Bottom navigation: 5-tab bar - Home, Projects, Tasks, Analytics, Settings
- Floating Action Button (FAB): Amber circle, bottom-right, add new item
- Dark mode: Full dark mode support, respects system preference automatically

# **2\. App Architecture & Navigation**

## **2.1 4-Level Project Hierarchy**

The app organizes work in four nested levels, giving structure to both simple and complex projects:

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Hierarchy Structure</strong></p><ul><li>Level 1 - PROJECT: The top-level container (e.g., 'E-Commerce Mobile App')</li><li>Level 2 - PHASE: A stage of the project (e.g., Planning, Design, Development, Testing)</li><li>Level 3 - TASK: A specific piece of work within a phase (e.g., 'UI Wireframes')</li><li>Level 4 - SUBTASK: The smallest unit of work (e.g., 'Draw login screen wireframe')</li></ul></th></tr></tbody></table></div>

Example full hierarchy:

| **Level** | **Example Name** | **Has Dates?** | **Has Progress?** |
| --- | --- | --- | --- |
| Project | E-Commerce Mobile App | Yes - Start & End | Auto from Phases |
| Phase | Phase 2 - Design | Yes - within Project | Auto from Tasks |
| Task | UI Wireframes | Yes - within Phase | Auto from Subtasks |
| Subtask | Login Screen Wireframe | Yes - within Task | Done / Not Done |

## **2.2 Timeline Rules & Date Validation**

Dates are strictly validated so nothing can go outside its parent's boundaries:

- A Phase cannot start before the Project start date
- A Phase cannot end after the Project end date
- A Task cannot go outside its parent Phase dates
- A Subtask cannot go outside its parent Task dates
- Date picker greys out invalid dates automatically
- If a Project end date is extended, app offers to auto-extend all children or keep them
- If a Subtask is overdue, its parent Task turns yellow/red
- If a Task is overdue, its parent Phase and Project status turns red

## **2.3 Bottom Navigation**

| **Tab** | **Icon** | **Screen** |
| --- | --- | --- |
| 1   | 🏠  | Home Dashboard |
| 2   | 📁  | Projects List |
| 3   | ✅   | Global Tasks View |
| 4   | 📊  | Analytics |
| 5   | ⚙️  | Settings |

# **3\. All App Pages - Detailed Specification**

The app consists of 15 screens, each described in detail below.

## **Page 1 - Splash & Onboarding**

| **Purpose** | First impression, brand introduction, user orientation |
| --- | --- |
| **Screens** | 1 splash screen + 3 swipeable onboarding slides |

**Content:**

- Splash: App logo + name centered, tagline: 'Your Projects. Your Control.'
- Slide 1: Track all your projects in one place (illustration)
- Slide 2: Manage money - prices, advances, remaining amounts
- Slide 3: Analyze your growth - weekly, monthly, annual charts
- Get Started button (Amber) + Log In text link at the bottom

## **Page 2 - Login Screen**

| **Purpose** | Authenticate returning users |
| --- | --- |
| **Design** | Clean centered card, minimal fields |

**Fields & Elements:**

- App logo at the top
- Email address input field
- Password input field with show/hide toggle
- Log In button (Indigo, full width)
- Forgot Password? link below button
- Divider: 'or continue with'
- Google sign-in button + Apple sign-in button
- Biometric login prompt if fingerprint/Face ID is enabled
- Bottom link: Don't have an account? Sign Up

## **Page 3 - Sign Up Screen**

| **Purpose** | Create a new account |
| --- | --- |
| **Design** | Same card style as Login |

**Fields:**

- Full Name
- Email Address
- Password + Confirm Password
- Phone Number (optional)
- Create Account button (Indigo, full width)
- Terms & Privacy Policy checkbox
- Bottom link: Already have an account? Log In

## **Page 4 - Home Dashboard**

| **Purpose** | Quick snapshot of all projects |
| --- | --- |
| **Access** | First screen after login / biometric unlock |

**Top Bar:**

- Profile avatar (top left) - tap to go to Settings
- Greeting: 'Good morning, John 👋'
- Notification bell icon (top right) with unread badge

**Summary Chips (3 pills in a row):**

- Total Projects | Active | Completed

**Project Cards (scrollable list):**

- Project name + category badge (Mobile / Website / Desktop / Other)
- Auto-calculated overall progress bar (% from subtask completion)
- Start date + Expected end date
- Status dot: Active 🟢 / Overdue 🔴 / On Hold 🟡 / Completed ✅
- Pinned/starred projects appear at the top of the list

**FAB Button:**

- Amber floating + button, bottom right - tap to add new project

## **Page 5 - Add / Edit Project**

| **Purpose** | Create a new project or edit an existing one |
| --- | --- |
| **Design** | Progressive - quick create first, details later |

**Quick Create (Step 1 - 30 seconds):**

- Project Name (required)
- Category: Mobile App / Website / Desktop / Other - pill selector
- Start Date - date picker
- 'Create & Add Details Later' button - project created instantly

**Full Details (Step 2 - optional):**

- Description (multiline text area)
- Total Project Price
- Advance Amount Received
- Remaining Amount (auto-calculated, shown in colored box)
- Expected End Date
- Status: Active / On Hold / Completed - toggle
- Client / Owner - select from saved contacts or add new
- Custom Tags - add color tags (e.g., Urgent, Personal, Government)
- Project Template - option to start from a saved template
- Save Project button (Indigo, full width)

## **Page 6 - Project Detail Page**

| **Purpose** | Full view of one project with all tracking information |
| --- | --- |
| **Access** | Tap any project card from Home or Projects list |

**Top Section:**

- Project name (large heading) + Category badge
- Status badge + Edit icon (top right)
- Overall progress bar (auto from subtask completion %)

**Cards Row:**

- Financial Card: Total Price | Advance Received | Remaining Amount (color-coded)
- Timeline Card: Start date | End date | Days remaining

**Mini Gantt Timeline:**

- Horizontal visual showing project period
- Phases appear as colored blocks within the project bar
- Tap a phase block to navigate directly to that phase

**Client Info Card:**

- Client Name, Company, Email (tap to open mail), Phone (tap to call), Location
- Contract Type: Fixed Price or Hourly

**Completion Details (when project is Done):**

- Completion date, final amount received, client sign-off status, delivery notes

**Attachments Section:**

- List of attached files with name, size, date added
- Supported: PDF, images, Word docs, spreadsheets, Figma links, URLs, voice memos
- Tap to preview, long press for share/delete/rename options
- \+ Add Attachment button

**Phases List (expandable):**

- Each phase shown as a collapsible row with its own progress bar
- Tap phase to expand and see tasks within it

**Activity Log:**

- Auto-generated audit trail of everything that happened on this project
- Cannot be edited - shows dates, actions, and changes

**Notes / Journal:**

- Free-text scratchpad for quick notes, client requests, meeting notes
- Each note is timestamped automatically

## **Page 7 - Phase Detail Page**

| **Purpose** | View and manage all tasks within a specific phase |
| --- | --- |
| **Access** | Tap a phase from Project Detail |

**Content:**

- Phase name + date range (within project boundaries)
- Phase progress bar (auto from task completion)
- Tasks list - each card shows: task name, dates, priority, status badge
- \+ Add Task button
- Option to mark entire phase as complete

## **Page 8 - Task Detail Page**

| **Purpose** | View subtasks and track time within a task |
| --- | --- |
| **Access** | Tap a task from Phase Detail |

**Content:**

- Task name + date range (within phase boundaries)
- Priority badge: High 🔴 / Medium 🟡 / Low 🟢
- Task progress bar (auto from subtask completion)
- Subtasks list - each row: checkbox, name, start date, end date, status
- Checkbox to mark subtask done - auto-updates task and project progress
- Long press subtask for Edit / Delete options
- Custom reminder per subtask: 'Remind me 2 days before due'
- Attachments section at task level
- \+ Add Subtask button

## **Page 9 - Global Tasks View**

| **Purpose** | See all tasks across all projects in one list |
| --- | --- |
| **Access** | Tasks tab in bottom navigation |

**Filter Bar:**

- Filter by: Project | Status | Priority | Due Date

**Task Cards:**

- Task name
- Parent project name and phase (smaller, gray text)
- Due date
- Status badge: To Do / In Progress / Done
- Priority dot: High / Medium / Low

## **Page 10 - Analytics Page**

| **Purpose** | Visual tracking of projects and money over time |
| --- | --- |
| **Access** | Analytics tab in bottom navigation |

**Time Filter Tabs:**

- Weekly | Monthly | Semi-Annual | Annual

**Charts & Sections:**

- Project Activity Chart: bar chart - projects started vs completed per period
- Revenue Chart: line graph - total amount earned per period
- Category Breakdown: donut chart - Mobile vs Website vs Desktop vs Other %
- Task Completion Rate: bar chart per week - subtasks done vs total

**Summary Stats:**

- Total Revenue Collected
- Total Remaining (unpaid across all projects)
- Projects Completed vs In Progress
- Average project duration
- Busiest phase / task type

**Drill-down levels:**

- Project view - overall completion and money
- Task view - which tasks are on time vs late per period
- Subtask view - granular daily/weekly progress

## **Page 11 - Client / Contact Book**

| **Purpose** | Save and manage client contacts for reuse across projects |
| --- | --- |
| **Access** | From Settings or Add Project screen |

**Client Card shows:**

- Full name + company name
- Email + phone (tap to call or email)
- Location
- Number of projects with this client and their status summary

**Actions:**

- Add new client
- Edit client details
- View all projects linked to this client
- Delete client (with warning if projects are linked)

## **Page 12 - Pocket / Finance Page**

| **Purpose** | Full financial tracking per project and overall totals |
| --- | --- |
| **Access** | Finance option in Settings |

**Per Project Financial Card:**

- Project name
- Total Price
- Amount Received (with payment history breakdown)
- Amount Remaining
- Expenses logged against the project
- Net Profit = Amount Received minus Expenses

**Payment History per Project:**

- Each payment: amount, date, status (Received / Pending)
- Attach a receipt photo to each payment

**Expense Logging:**

- Add expenses: tools, subscriptions, freelancers, other costs
- Each expense: name, amount, date, category, optional receipt

**Bottom Overall Summary:**

- Total Received (all projects combined)
- Total Expenses (all projects combined)
- Overall Net Profit (highlighted, large font - green if positive)

## **Page 13 - Settings Page**

| **Purpose** | App preferences, security, profile, and configuration |
| --- | --- |
| **Access** | Settings tab in bottom navigation |

**Sections:**

- Profile: name, email, phone, profile avatar
- Security (see Section 4 for full biometric details)
- Finance / Pocket - link to Page 12
- Notifications - toggle reminders and alerts
- Dark Mode toggle - also respects system preference
- Project Templates - manage saved templates
- Export Data - export as PDF or CSV
- Client Book - link to Page 11
- About / Version info
- Log Out

## **Page 14 - Notifications Page**

| **Purpose** | All alerts and reminders in one place |
| --- | --- |
| **Access** | Bell icon on Home Dashboard |

**Notification types:**

- Subtask due tomorrow: 'Wireframes subtask due tomorrow!'
- Subtask overdue: 'Color scheme subtask is 2 days overdue'
- Task overdue: 'UI Design task is behind schedule'
- Project at risk: '⚠️ Project 80% time used but only 40% complete'
- Task completed: '🎉 UI Design Task 1 is complete!'
- Project completed: '🎊 Project successfully completed!'
- Payment reminder: 'Final payment of \$400 is still pending'

**Interaction:**

- Tap any notification to go directly to the relevant project/task
- Swipe to dismiss
- Mark all as read

## **Page 15 - Export & Reports Page**

| **Purpose** | Generate and share project reports and financial summaries |
| --- | --- |
| **Access** | From Settings or individual project detail |

**Export options:**

- Project Report as PDF - full project details, phases, tasks, financial summary
- Financial Summary as Excel/CSV - all projects with amounts
- Share via WhatsApp, Email, or any installed share target
- Export a single project or all projects at once

# **4\. Security & Biometric Authentication**

The app provides multiple layers of security with a seamless biometric experience.

## **4.1 Authentication Flow**

| **Scenario** | **Authentication Method** |
| --- | --- |
| First time user | Sign Up → email + password |
| Returning user (session active) | Fingerprint or Face ID prompt → Home |
| Session expired / app backgrounded | Fingerprint or Face ID → Home |
| Biometric fails 3 times | Falls back to PIN or password |
| Manual logout | Full email + password login required |
| Biometric not set up | Standard email + password login |

## **4.2 Biometric Setup Options**

- Enable Fingerprint Login 🫆 - ON/OFF toggle in Settings
- Enable Face ID Login 👤 - ON/OFF toggle in Settings
- Option: 'Require biometric every time app opens'
- Option: 'Lock app after X minutes of inactivity' - 1 / 5 / 15 / 30 min / Never
- Set 4 or 6-digit PIN as backup to biometric
- Change Password option
- Remote logout (if logged in on multiple devices)

## **4.3 Lock Screen Design**

When the app is locked, a minimal lock screen appears showing:

- App logo centered
- Fingerprint icon (if fingerprint enabled) - tap to scan
- 'Use Password Instead' text link below
- No project data visible until authenticated

# **5\. Document Attachments**

Attachments can be added at every level of the hierarchy.

| **Level** | **Example Attachments** |
| --- | --- |
| Project | Contract PDF, NDA, proposal document, project brief |
| Phase | Phase brief, design brief, approval sign-off document |
| Task | Design files, reference images, requirements doc |
| Subtask | Screenshots, voice notes, small reference files |

## **5.1 Supported File Types**

- 📄 PDF documents
- 🖼️ Images - JPG, PNG
- 📝 Word documents
- 📊 Spreadsheets
- 🎨 Design links - Figma, Adobe XD URL
- 🔗 Any external URL or link
- 🎙️ Voice memos - short audio notes

## **5.2 Attachment Interactions**

- Tap to preview the file inline in the app
- Long press for options: Share / Delete / Rename
- Shows file size and upload date next to each attachment
- \+ Add Attachment button at the bottom of each attachments section

# **6\. Auto-Calculations & Progress Logic**

## **6.1 Progress Calculation Flow**

| **Level** | **Calculation Method** |
| --- | --- |
| Subtask | Done = 100%, Not Done = 0% |
| Task | Average % of all Subtasks within it |
| Phase | Average % of all Tasks within it |
| Project | Average % of all Phases within it |

Example: A project has 2 phases:

- Phase 1 = 100% (all tasks and subtasks done)
- Phase 2 = 50% (half of subtasks done)
- Project overall progress = 75% - calculated automatically

## **6.2 Financial Calculations**

| **Field** | **Formula** |
| --- | --- |
| Remaining Amount | Total Project Price minus Advance Amount Received |
| Net Profit (per project) | Amount Received minus All Expenses Logged |
| Overall Net Profit | Sum of all project Net Profits |
| Days Remaining | Project End Date minus Today's Date |

## **6.3 Project Health Indicator**

The app calculates a health status comparing time used vs progress made:

| **Health Status** | **Condition** | **Color** |
| --- | --- | --- |
| On Track | Progress % >= Time Used % | Green 🟢 |
| At Risk | Progress % is 20-40% behind Time Used % | Yellow 🟡 |
| Critical | Progress % is 40%+ behind Time Used % | Red 🔴 |
| Completed | All subtasks done | Indigo ✅ |

# **7\. Additional Recommended Features**

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 1 - Client / Contact Book</strong></p><ul><li>Save client names, emails, phone, company, location</li><li>Select a saved client when creating a new project</li><li>View all projects linked to one client from their profile</li><li>See client summary: 'Client A has 3 projects - 2 done, 1 active'</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 2 - Invoice &amp; Payment Record Tracker</strong></p><ul><li>Track payment installments per project (Advance, Milestone 1, Milestone 2, Final)</li><li>Each payment has: amount, date, status (Received / Pending)</li><li>Attach a receipt photo to each payment entry</li><li>Running total: Total Price | Amount Received | Amount Still Due</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 3 - Project Tags &amp; Custom Labels</strong></p><ul><li>Add custom color tags: Urgent, Client Revision, Personal, Government, Internal</li><li>Filter projects on Home screen by tag</li><li>Tags appear as small colored chips on project cards</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 4 - Activity Log / Audit Trail</strong></p><ul><li>Auto-generated log inside every project</li><li>Records: subtask completions, attachments added, dates changed, notes written</li><li>Cannot be manually edited - trusted history of what happened</li><li>Shows: action description + timestamp + who did it</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 5 - Project Templates</strong></p><ul><li>Save any project structure as a reusable template</li><li>Built-in templates: Mobile App (5 phases), Website (4 phases), Generic (3 phases)</li><li>When creating a new project, select a template to pre-fill phases and tasks</li><li>Save massive time on repeat project types</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 6 - Pin / Favourite Projects</strong></p><ul><li>Pin urgent or active projects to the top of the Home dashboard</li><li>Star a project to mark as favourite</li><li>Pinned projects always appear first, regardless of creation date</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 7 - Custom Subtask Reminders</strong></p><ul><li>Set a reminder per subtask: '2 days before due' or specific date/time</li><li>Push notification sent at chosen time</li><li>Can snooze or dismiss from the notification</li><li>Reminder badge appears on the subtask in the list</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 8 - Project Notes / Journal</strong></p><ul><li>Free-text scratchpad attached to each project</li><li>Jot quick ideas, client requests, meeting notes</li><li>Each note entry is timestamped automatically</li><li>Different from attachments - pure text, instantly writable</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 9 - Export &amp; Sharing</strong></p><ul><li>Export a full project report as a PDF</li><li>Share project summary via WhatsApp or Email</li><li>Export financial summary as Excel or CSV</li><li>Export a single project or all projects at once</li></ul></th></tr></tbody></table></div>

<div class="joplin-table-wrapper"><table><tbody><tr><th><p><strong>Feature 10 - Dark Mode</strong></p><ul><li>Full dark mode for all 15 screens</li><li>Toggle manually in Settings or follows system preference automatically</li><li>Designed with dark background #0F172A and lighter card surfaces</li></ul></th></tr></tbody></table></div>

# **8\. Smart Notification & Alert System**

| **Trigger Condition** | **Notification Message** | **Priority** |
| --- | --- | --- |
| Subtask due tomorrow | '{SubtaskName}' is due tomorrow! | Medium |
| Subtask overdue | '{SubtaskName}' is {N} days overdue | High |
| Task overdue | Task '{TaskName}' is behind schedule | High |
| Project 80% time, 40% done | ⚠️ Project '{Name}' is at risk | Critical |
| All subtasks in a task done | 🎉 Task '{TaskName}' is complete! | Low |
| All tasks done | 🎊 Project '{Name}' completed! | Low |
| Payment pending | Final payment of \${amount} is still pending | Medium |
| Phase starts tomorrow | Phase '{PhaseName}' starts tomorrow | Low |

# **9\. Complete Page Reference**

| **#** | **Page Name** | **Purpose** | **Nav Access** |
| --- | --- | --- | --- |
| 1   | Splash / Onboarding | First impression, brand intro | App open (first time) |
| 2   | Login | Authenticate returning users | App open |
| 3   | Sign Up | Create new account | From Login |
| 4   | Home Dashboard | Project overview snapshot | Home tab |
| 5   | Add / Edit Project | Create or update a project | FAB button |
| 6   | Project Detail | Full project view + phases | Tap project card |
| 7   | Phase Detail | Tasks within a phase | Tap phase in project |
| 8   | Task Detail | Subtasks + time tracking | Tap task in phase |
| 9   | Global Tasks View | All tasks across projects | Tasks tab |
| 10  | Analytics | Charts + financial tracking | Analytics tab |
| 11  | Client Book | Saved client contacts | Settings |
| 12  | Pocket / Finance | Money tracking per project | Settings |
| 13  | Settings | Profile, security, preferences | Settings tab |
| 14  | Notifications | All alerts and reminders | Bell icon |
| 15  | Export & Reports | PDF/CSV generation | Settings or project |

**Ready to Build 🚀**

This document covers the complete design specification.

Next step: Choose your tech stack and start building screen by screen.

**Recommended Tech Stack Options**

React Native (cross-platform iOS + Android) | Flutter | Native Swift / Kotlin