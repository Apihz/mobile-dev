# KanbanBoard

**Group Name:** Coselaw

**Repo:** https://github.com/Apihz/mobile-dev.git

### Group Members

| Name | Matric No | Assigned Tasks |
|---|---|---|
| Muhammad Hafiz Bin Mohd Khairulariman | 2314629 | Firebase setup, Authentication, Board page, AI task import |
| Aiman bin Ahmad Zainulkamal| 2311929 | Team page, Team collection in Firebase, Enhancing UI for Team page |
| Syazwan Fariz Bin Shamsul Azzmar | 2012003 | _<tasks>_ |

---

## Introduction

KanbanBoard is a task management app built with Flutter. The idea behind it is simple, instead of keeping your tasks in your head, scattered across chat messages, or in a plain notes app, you put them on a board with three columns (To Do, Doing, Done) and just drag the cards across as the work moves forward. Everything is connected to Firebase, so tasks are saved online and synced in real time, which means a whole team can look at the same board and see updates as they happen.

We chose to build this as a mobile app because most people manage their day from their phone, not a desktop. A board you can pull up anywhere and update with a quick drag fits how students and
small teams actually work.

## Problem Statement

A lot of students and small teams don't really have a proper way to keep track of who is doing what. Group assignments and side projects usually get organised through WhatsApp chats, random to-do notes, or just verbal agreements, and things slip through the cracks fast. There's no single place where everyone can see what still needs to be done, what's in progress, and what's already
finished.

The common task apps out there either feel too heavy and complicated for a small group, or they don't show progress in a clear visual way. People end up not knowing the status of a task until hey ask someone directly, deadlines get forgotten, and the same work sometimes gets done twice.

KanbanBoard tries to solve this by giving the team one shared board that updates live. Everyone logs into their own account, tasks are organised into clear stages, and moving a task forward is as easy as dragging a card. Because it's backed by Firebase, the board stays in sync for everyone
without anyone having to refresh or message "is this done yet?".

## Objective

- Give small teams and students one shared place to organise tasks visually.
- Make updating progress as quick as dragging a card between columns.
- Keep everything synced in real time across all members through Firebase.
- Keep the app simple and clean so there's almost no learning curve.

## Target Users & Platform

- **Target users:** university students and small teams who need a lightweight way to manage group tasks and assignments.
- **Platform:** Android (built with Flutter, so it can extend to iOS later).

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend as a Service:** Firebase (Authentication, Cloud Firestore)
- **AI:** Firebase AI Logic (Gemini) for the AI task import feature
- **State management:** Provider

---

## Member Contributions

### Muhammad Hafiz Bin Mohd Khairulariman – 2314629

**What I worked on:** Firebase backend setup, the authentication flow (login/register), the Kanban board page where users manage their tasks, and the AI task import feature that turns a PDF brief into ready-made tasks.

**Details:**

**1. Firebase setup.** Before anyone could log in or save a task, the app needed Firebase connected properly, which honestly took me a while to get right. I added the Firebase packages the app depends on:

- **firebase_core** – needed to start Firebase at all
- **firebase_auth** – for the login/register
- **cloud_firestore** – the database where tasks are stored

Firebase gets initialised at the very start of the app (in `main.dart`) before the UI is built, otherwise the auth and database calls crash because the services aren't ready yet. I learned that the hard way. I also set up App Check so it only turns on for release builds, because while developing it kept blocking my requests on the emulator.

**2. Authentication.** The auth code lives in `lib/features/auth/`. I kept the actual Firebase calls in a separate service class (`auth_service.dart`) so the screens don't talk to Firebase directly – they just call methods like sign in, register and sign out. This made it cleaner and easier to reuse. The screens I built are the welcome screen, the login form, and the register form.

For the forms I used Flutter's `Form` and `TextFormField` with validators, so empty or invalid fields get caught before anything is sent to Firebase. I added validation for the email and password fields and a show/hide password button. One part I'm happy with is the error handling – Firebase throws ugly codes like `invalid-credential` that a normal user wouldn't understand, so I wrote a small helper that turns them into plain messages like *"Incorrect email or password."* before showing them on screen. The whole login state is driven by a stream that listens to Firebase's auth changes, so the app automatically switches between the welcome screen and the main
app when a user logs in or out.

**3. The Kanban board page.** This was the biggest part. The board lives in `lib/features/board/` and I split it into screens, widgets and services so it isn't one giant file (board screen and task detail screen; column, task card, add-task sheet and settings sheet widgets, and a firestore_service that holds all the database calls for tasks).

- **Real-time tasks:** the board listens to a live stream, so when a task is added, edited or moved (even by a teammate) it shows up without refreshing.
- **Drag and drop:** each column is a drop target and each card can be dragged. Dropping a card on another column updates its status and shows a snackbar like *"Moved to Doing"*. The column highlights while you drag a card over it.
- **Auto-scroll:** dragging a card to the screen edge scrolls the board automatically, so you can move cards across columns that don't all fit on screen. This was fiddly to get smooth.
- **CRUD for tasks:** adding/editing happens in a bottom sheet. A task has a title, description, priority, assignee, start date, deadline and a subtask checklist. Tapping a card opens the detail screen to edit or delete it.
- **Display settings:** a settings sheet to sort tasks (priority, deadline, title, newest) and toggle what shows on the cards.
- **UX touches:** a time-based greeting in the app bar, empty-state messages so blank columns don't look broken, and horizontal scrolling to handle overflow.

**4. AI task import (PDF).** This is the feature that most interesting. Instead of typing out every task by hand, a user can upload their assignment or group project brief as a PDF (or just paste the text), pick a start date and deadline, and the app reads it and generates a full list of tasks automatically. It lives in `lib/features/ai_import/`.

I used Firebase AI Logic (Gemini) for this. The PDF is sent straight to the model along with a prompt, and I made it return structured JSON using a response schema, so I always get back clean task data (title, description, priority, dates, subtasks and a suggested assignee) instead of plain paragraphs I'd have to parse myself. The prompt is written to think like a real student group and produce concrete tasks (e.g. "Write Introduction section", "Design ERD and database schema") rather than vague phases like "Implementation".

- **PDF picker:** uses `file_picker` to choose a PDF, with a size limit (~15 MB) so big files don't break things.
- **Scheduling:** the model spreads tasks between the chosen start and deadline, and I clamp every returned date back inside that range in case it goes out of bounds.
- **Assignees:** if the team has members, the model suggests who should do what, and I match those names back to real member IDs.
- **Preview before saving:** extracted tasks open in a preview screen first, so nothing gets written to the board until the user is happy with it. Saving them uses a single batch write to Firestore.

**Problems faced:**

- *Firebase wouldn't initialise properly at first* – fixed it by making sure Firebase finishes initialising before the app UI is built.
- *App Check kept blocking my requests during development* – set it to only run in release builds.
- *Ugly Firebase error messages* – wrote a helper to map error codes to friendly text.
- *Board overflowed on smaller screens* – used a horizontal scroll plus the edge auto-scroll so
  everything stays reachable.
- *CocoaPods/Podfile issues on iOS* – cleaned and reinstalled the pods to get a stable build.
- *Merge conflicts when combining feature branches* – worked through them with the group and made
  sure the board logic stayed intact after merging.

<!-- Next member: add your ### subsection below this line, following the template above. -->

### [Syazwan Fariz Bin Shamsul Azmar] – [2012003]

**What I worked on:** Complete frontend implementation, architectural state mapping, and real-time backend synchronization for the personal Daily Planner module, including the development of an interactive month-view calendar with contextual deadline markers, synchronous client-side dataset filtering pipelines, and visual layout alignment with our global application scaffolding.

**Details:**

* **1. TableCalendar Integration & Design System Compliance:** I integrated the `table_calendar` package to serve as the core visual calendar interface for students. To maintain a cohesive look across screens, I hardcoded our group’s exact theme specifications as class-level immutable `static const Color` flags (including `0xFF131315` for the canvas, `0xFF0E0E10` for card surfaces, and `0xFF5B5FEF` for primary buttons). This micro-optimization stores hex configurations statically in memory, preventing wasteful object re-allocations during Flutter frame redraws.
* **2. Memory-Cached Contextual Deadline Markers:** I configured the calendar’s `eventLoader` property to scan our live task array and dynamically render a green indicator dot directly under dates containing active deliverables. This relies on recognition over recall, showing students heavy delivery weeks at a glance. It searches the synchronized in-memory cache directly, which keeps the scrolling interface running at a smooth 60 FPS while protecting our Firebase read limits.
* **3. Real-Time Data Streaming & User Context Isolation:** I wired the entire screen layout to a Cloud Firestore database stream using a native Flutter `StreamBuilder` that tracks our project’s tasks subcollection via `service.watchTasks(projectId)`. When a teammate creates or edits an item, the updates sync live without requiring a page refresh. I wrote a client-side database query using a high-order `.where()` filter on the snapshot array to isolate rows where the logged-in user is the explicit assignee (`currentUser.uid` or unassigned) while discarding completed data entries (`status != 'done'`).
* **4. Temporal Normalization & Chronological Triage Buckets:** I built a date evaluation loop that strips out hour, minute, and millisecond properties from `DateTime.now()` to create a clean `todayDateOnly` reference anchor. This prevents timezone slipping or late-night boundary calculation errors. The system computes due-date differences via `.difference()`, sorting active deliverables into three distinct list arrays: *Overdue* (flagged with an urgent red left border), *Today*, and *Upcoming*. It then runs inline comparison mutators (`.sort()`) to arrange all generated list cards in ascending chronological order.
* **5. UX Guard Gates & Interactive Components Integration:** I implemented structural conditional checks at the top of the main `build` routine. If data streams are loading, the app locks down behind a progress spinner. If a user hasn't joined or selected an active team project (`currentTeam == null`), a fallback placeholder screen triggers. This view renders our shared custom `TeamSwitcherDropdown` directly inside the app bar actions array so the student can instantly choose a group context and safely recover page data.
* **6. Mobile Thumb-Zone Call to Actions:** I aligned our screen's submission workflows with the `BoardScreen` by stripping out old text elements from the app bar and implementing a prominent bottom-anchored Floating Action Button (+). This button hooks straight into the framework's native `showModalBottomSheet` layout engine to slide up our universal `AddTaskSheet` form from the bottom of the viewport. It pre-seeds the initial workspace status parameter to `'todo'`, ensuring rapid, comfortable task creation within a student's natural typing range.

**Problems faced:**

* *Fragile Cross-Feature Relative Imports:* When referencing widgets from other folders (like importing the board folder's task components), using multi-hop relative directory jumps (`../../../../`) broke path tracking and threw 25 syntax errors. I solved this by cleaning up the header files and refactoring every module import to use explicit, absolute project package strings (`package:flutter_app_1/...`).
* *Font Weight Token Syntax Typo:* An accidental lowercase typo inside our custom typography mapping configuration (`FontWeight.g600`) threw unexpected framework exceptions and blocked hot reloading. I fixed it immediately by reviewing the typography stack and substituting the text with a valid material system weight token (`FontWeight.w600`).
* *Dart VM Connection Protocol Timeout Errors:* Running deep project cache wipes (`flutter clean`) occasionally caused local compilation tasks to heavily consume memory resources, triggering thread stutters that crashed the Dart proxy bridge tunnel with the emulator device. I resolved this port collision by executing a terminal server reset sequence (`adb kill-server` followed by `adb start-server`) and forcing a dedicated fallback outbound debugger port flag (`flutter run --vmservice-out-bound-port=8888`).

### [Aiman bin Ahmad Zainulkamal] - [2311929]

**What I worked on:** Creating a team page that contains information about a specific team that has been created by users. Team leader is chosen based on a role-based member management. Team leader can add new teammates into the team and those teammates are appeared in the page with two information, which are name and email. Team leader can track the project progress among teammates as the page is integrated with the tasks at the kanban page. Teammates that are freshly join the team are able to do so by using the join-by-code system.

**Details:**

**1. Team page setup** I built two screens for the team part, which are `create_team_screen.dart` for creating a team and adding teammates using google and `team_screen.dart` for the team information viewing. `team_state.dart` is the crucial file in team part because it carries a role as a central state for many adjustmnet such as team selection, member management, and join requests by the new teamates. Then, `firestore_service.dart` and `team_service.dart` are created to manage the team functionality and connection into Firebase properly. The CRUD for the team page is available, so users as the team leaders can update, edit or delete their team based on their preferences. The main widgets that I built for this page are `add_member_sheet.dart`, `member_card.dart`, and `member_task_status.dart`. Each widget are considered as the main UI template for the team page as every widgets are run through them.

**2. Team data models (`lib/models/team.dart`)** I built `Team` class that contains some properties such as `id`, `name`, `leaderId`, `joinCode`, and `memberIds` fields for the team overall information. I also used `fromMap()` factory to fetch any changes in the Firebase that stores `team collection` of the team members information. Then, `TeamMember` class exists which is contains `uid`, `name`, `email`, `role (leader or member)`, and `joinedAt`. Those properties are very important as they show the each teammate information and using email as the `uid` for each team members. `fromMap()` and `toMap()` are implemented for Firestore round_trips to get any update about the `team collection`.

**3. Central Team State (`lib/state/team_state.dart`)** I created this file as the main component of the team part because it acts as a provider for many functionalities within the team folder. A `ChangeNotifier` is called for this file because it gives the CRUD functionalities for the team page.

* `loadTeams()` - This method runs as a team insertion, where it queries Firestore `projects` that recognizes the logged_in UID is in the `memberIds` array, then it automatically selects the first team that has been loaded with its teammates.
* `createTeam()` - Instead of adding a new teammate manually by sending through email, team leaders can generate  a 6-digit join code from `DateTime.now().milisecondsSinceEpoch.toString().substring(7)` as it can create some random numbers for the join code differently based on the specific daytime to avoid many duplicable codes that may cause harm to this app in terms of security such as team collection breach, data manipulation, and DDoS attacks. It also writes project documentatiion and automatically adds the team creator as the team leader.
* `addMember()` and `removeMember()` - Those are privileged by team leaders only as it can add new teammates and checks whether the page contains any duplicates before inserting the teammates data. But, team leaders cannot remove themselves.
* `joinByCode()` - This function searches Firestore to do a `joinCode` matching for the new teammates that wants to join thorugh the code and checks the member status. If he or she is not a member yet, add them into the team.
* `deleteTeam()` - This method is applicable to the team leaders only as it can delete the team starts cancelling active streams, removing the team from local list, and automatically selecting the next team or clearing all teams immediately.

**3. Firestore Service Layer (`lib/features/team/services/team_service.dart`)** This file runs as the interaction between the team page and the `team collection` in the Firestore and it is the service part. Users can get a rela-time stream of teammate list through `watchMembers()` from `projects/{id}/members` that the list is ordered by `joinedAt`. Then, the `addMember()` and `removeMember()` create subcollection and update method for the `memberIds` by using the logical interaction in Firebase such as `arrayUnion`, `arrayRemove`, and `members.{uid}` map field. This file also runs the join request lifecycle, where the leader sends the join team code by using `sendJoinRequest()` to the new teammate and they can accept the invitation through `acceptJoinRequest()` or decline it through `rejectJoinRequest()`. `deleteTeam()` is the abort function to remove the team immediately but manually handeld by team leader as Firestore does not auto-delete subcollections when parent is deleted. Lastly, the `computeTaskStats()` is a static method than returning the task status whether it is `todo`, `doing`, `done`, or `overdue`. The status outputs are appeared in the teammates' card name, below the email section in the team page. It counts the task status by filtering tasks where `assigneeId == uid`.

**4. UI Screens and Widgets** I built two main screens for the team module. The create team screen (`lib/features/team/screens/create_team_screen.dart`) is a form where the user enters a team name and can optionally invite teammates by typing their email addresses, which appear as removable chips. The team screen (`lib/features/team/screens/team_screen.dart`) shows the selected team’s info, where member count and a shareable 6-digit join code followed by a scrollable list of all members. Each member row is rendered by the MemberCard widget (`lib/features/team/widgets/member_card.dart`), which displays an avatar with the person’s initials, their name and email, a role badge (`“Leader” or “Member”`), and a horizontal segmented progress bar showing their task distribution. The bar uses four colour-coded segments tha classify `green for Done`, `blue for Doing`, `red for Overdue`, and `grey for To Do` with a legend underneath. The leader sees two buttons at the bottom: Add New Teammate, which opens the AddMemberSheet bottom sheet (`lib/features/team/widgets/add_member_sheet.dart`) with name and email fields to add a member directly, and Delete Team, which shows a confirmation dialog before cascading the deletion. Non-leader members instead see a Notify Team Leader button that sends a join request through Firestore. Across the app, the team switcher dropdown (`lib/shared/widgets/team_switcher_dropdown.dart`) sits in the app bar as a pill-shaped button showing the current team name. Tapping it opens a bottom sheet listing all the user’s teams with a checkmark on the active one, plus two options at the bottom`“Create new team”` navigates to the create screen, and `“Join existing team”` opens a dialog where the user enters a 6-digit join code shared by a team leader.

**Problem faced:**
* **Firestore cascade delete** - Firestore doesn't automatically delete subcollections when a parent doc is deleted. I had to write my own cascade in `team_service.dart` that fetches/deletes every single doc in the `members`, `joinRequests`, and `tasks` subcollections one at a time before deleting the project doc.
* **Stream lifecycle management** - Switching teams or even deleting a team left old StreamSubscription runners leaking stale data from the last team. I fixed this by calling `_memberSub?.cancel()` and `_requestSub?.cancel()` every time the user switches teams, removes a team, or logs out. This ensures only the currently selected team's data is streaming through.
* **Role-based access control** - Not every team member should be able to add or remove other teammates! I added guard clauses throughout `team_state.dart` that check if the current user’s `UID` matches the team’s `leaderId`. If a non-leader tries to add, remove, or delete they get a friendly `“Only the team leader can…”` error message instead, which we show in the UI.
* **State cleanup on logout** - Team data would stick around in memory after signing out, which causes the next login to load stale teams. I added a `reset()` method to `TeamState` that cancels all active streams, clears the team list, members, and join requests, and notifies listeners that this is called in `app.dart` whenever the auth stream emits a null user.

## How to Run

1. Run `flutter pub get` to install the packages.
2. Make sure the Firebase config files are in place (`google-services.json` for Android).
3. Run `flutter run`.

After that, register an account, create or select a team, and you can start adding tasks to the
board.

---

## References

Firebase. (2024). *Add Firebase to your Flutter app*. Google. https://firebase.google.com/docs/flutter/setup

Firebase. (2024). *Get started with Firebase Authentication on Flutter*. Google. https://firebase.google.com/docs/auth/flutter/start

Firebase. (2024). *Get data with Cloud Firestore*. Google. https://firebase.google.com/docs/firestore/query-data/get-data

Flutter. (2024). *Drag a UI element*. https://docs.flutter.dev/cookbook/effects/drag-a-widget

Flutter. (2024). *Build a form with validation*. https://docs.flutter.dev/cookbook/forms/validation

Firebase. (2024). *Firebase AI Logic*. Google. https://firebase.google.com/docs/ai-logic

Google. (2024). *Generate structured output (JSON) using the Gemini API*. https://ai.google.dev/gemini-api/docs/structured-output

Asynchronous programming: Streams. (2025). https://dart.dev/libraries/async/using-streams

Send data to a new screen. (2025). https://docs.flutter.dev/cookbook/navigation/passing-data

Get realtime updates with Cloud Firestore  |  Firebase. (2026). Firebase. https://firebase.google.com/docs/firestore/query-data/listen

table_calendar | Flutter package. (2025). Dart Packages. https://pub.dev/packages/table_calendar
---

## Generative AI Disclosure

- **Hafiz (2314629) – AI used inside the app:** The AI task import feature uses Google's Gemini model (through Firebase AI Logic) to read a PDF brief and generate tasks.This is the only part that was vibecoded. 

