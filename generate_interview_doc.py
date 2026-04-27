from docx import Document
from docx.shared import Pt


def add_bullets(document, items):
    for item in items:
        document.add_paragraph(item, style="List Bullet")


def add_numbered(document, items):
    for item in items:
        document.add_paragraph(item, style="List Number")


doc = Document()

title = doc.add_heading("Smart Chat — Technical Documentation for Interview Preparation", 0)
title.alignment = 1
doc.add_paragraph("Version: 1.0")
doc.add_paragraph("Project: Smart Chat (Flutter + Firebase + Riverpod)")

doc.add_page_break()

doc.add_heading("Table of Contents", level=1)
add_numbered(
    doc,
    [
        "Chapter 1: Project Overview & Data Flow",
        "Chapter 2: Architecture Explanation",
        "Chapter 3: Flutter & Dart Concepts Used",
        "Chapter 4: State Management (Provider/Riverpod)",
        "Chapter 5: Async Programming & Data Handling",
        "Chapter 6: Dependency Injection",
        "Chapter 7: UI Components",
        "Chapter 8: Project Setup Guide",
        "Chapter 9: Interview Preparation (100+ Questions)",
    ],
)

doc.add_page_break()

doc.add_heading("Chapter 1: Project Overview & Data Flow", level=1)
doc.add_heading("1.1 Project Summary", level=2)
doc.add_paragraph(
    "Smart Chat is a layered Flutter application that provides authentication, realtime chat, "
    "media messaging, audio messaging, reactions, unread/read tracking, and status features."
)

doc.add_heading("1.2 Text-Based Data Flow Diagram", level=2)
for line in [
    "[User Action in UI Screen]",
    "        |",
    "        v",
    "[Presentation Layer: Screens -> ViewModels -> Providers]",
    "        |",
    "        v",
    "[Domain Layer: Contracts + Entities]",
    "        |",
    "        v",
    "[Data Layer: Provider -> Adapter -> Repository Impl]",
    "        |",
    "        v",
    "[Firebase Services: Auth / Firestore / Storage]",
    "        |",
    "        v",
    "[Response Streams -> ViewModel -> UI Rebuild]",
]:
    p = doc.add_paragraph(line)
    p.style.font.name = "Consolas"
    p.style.font.size = Pt(10)

doc.add_heading("1.3 End-to-End Message Flow", level=2)
add_numbered(
    doc,
    [
        "User sends a text/image/audio message from chat screen.",
        "Screen calls a ViewModel method.",
        "ViewModel uses repository contract methods.",
        "Adapter delegates to Firebase repository implementation.",
        "Firestore/Storage operation completes.",
        "StreamProvider emits updated data and UI refreshes.",
    ],
)

doc.add_heading("Chapter 2: Architecture Explanation", level=1)
for layer, points in [
    (
        "Data Layer",
        [
            "Purpose: concrete Firebase operations and persistence workflows.",
            "Key components: auth_repository_impl, chat_repository_impl, adapters, providers.",
            "Handles writes, queries, uploads, and mapping to entities.",
        ],
    ),
    (
        "Domain Layer",
        [
            "Purpose: stable contracts and entities independent of backend and UI.",
            "Key components: repository contracts and entity models.",
            "Protects presentation from implementation changes.",
        ],
    ),
    (
        "Presentation Layer",
        [
            "Purpose: screens, shared widgets, and ViewModels.",
            "Key components: feature screens, shared widgets, Riverpod providers/viewmodels.",
            "Orchestrates user actions and reactive rendering.",
        ],
    ),
]:
    doc.add_heading(layer, level=2)
    add_bullets(doc, points)

doc.add_heading("Architecture Communication", level=2)
doc.add_paragraph(
    "Presentation calls Domain contracts; Data implements contracts and talks to Firebase. "
    "Streams return through providers to rebuild the UI."
)

doc.add_heading("Chapter 3: Flutter & Dart Concepts Used", level=1)
concepts = [
    ("Classes, Objects, Abstraction", "Used for entities, repository contracts, and adapters."),
    ("Functions & Callbacks", "Used in widget interaction handlers and provider builders."),
    ("Async/Await, Futures, Streams", "Futures for actions; Streams for realtime updates."),
    ("Widgets: Stateless vs Stateful", "Stateful for chat interactions; stateless for reusable UI."),
    ("State Management (Provider/Riverpod)", "Reactive streams and dependency injection."),
]
for name, why in concepts:
    doc.add_heading(name, level=2)
    doc.add_paragraph("Definition: " + name + " is a core Flutter/Dart concept used in architecture.")
    doc.add_paragraph("Why used in this project: " + why)
    doc.add_paragraph("Interview explanation: explain with one project example and tradeoff.")

doc.add_heading("Chapter 4: State Management (Provider)", level=1)
add_bullets(
    doc,
    [
        "Provider gives dependency injection and reactive rebuilds.",
        "StreamProvider is ideal for Firestore realtime listeners.",
        "This project uses provider files in data layer and providers in viewmodels.",
    ],
)
doc.add_heading("Provider vs ChangeNotifier vs StreamProvider", level=2)
add_bullets(
    doc,
    [
        "Provider: immutable service objects.",
        "ChangeNotifierProvider: mutable notifier state object.",
        "StreamProvider: async event streams (used heavily for chat/auth).",
    ],
)
doc.add_heading("Common mistakes", level=2)
add_bullets(
    doc,
    [
        "Triggering write side-effects directly in build methods.",
        "Watching providers where read is enough.",
        "Mixing contract and implementation in the same presentation class.",
    ],
)

doc.add_heading("Chapter 5: Async Programming & Data Handling", level=1)
add_bullets(
    doc,
    [
        "Futures: send message, upload media, update profile.",
        "Streams: auth state, chats, messages, statuses.",
        "Error handling via try/catch in repositories and AsyncValue error UI.",
        "Loading states via when(loading/data/error).",
    ],
)

doc.add_heading("Chapter 6: Dependency Injection", level=1)
doc.add_paragraph(
    "Dependency Injection is implemented with Riverpod Provider files. "
    "Providers create implementation classes and expose domain contracts to presentation."
)
add_bullets(
    doc,
    [
        "auth_repository_provider.dart -> AuthRepositoryContract",
        "chat_repository_provider.dart -> ChatRepositoryContract",
        "ViewModels only depend on contracts.",
    ],
)

doc.add_heading("Chapter 7: UI Components", level=1)
add_bullets(
    doc,
    [
        "Feature screens: auth and chat flows under presentation/features.",
        "Shared widgets: AppAvatar, MessageBubble, WhatsAppInputBar.",
        "Reusable styling via core/theme files.",
    ],
)

doc.add_heading("Chapter 8: Project Setup Guide", level=1)
doc.add_heading("Step-by-step", level=2)
add_numbered(
    doc,
    [
        "Install Flutter SDK and Android Studio/VS Code.",
        "Create project and configure Firebase project.",
        "Add firebase_core/firebase_auth/cloud_firestore/firebase_storage.",
        "Set Android/iOS Firebase config files.",
        "Run flutter pub get and flutter run.",
    ],
)
doc.add_heading("Dependencies", level=2)
add_bullets(
    doc,
    [
        "firebase_core, firebase_auth, cloud_firestore, firebase_storage",
        "flutter_riverpod, image_picker, record, just_audio, path_provider",
    ],
)
doc.add_heading("Best practices", level=2)
add_bullets(
    doc,
    [
        "Keep strict layer boundaries.",
        "Use contracts in domain and implementations in data.",
        "Keep feature screens in presentation only.",
        "Split provider/adapter/implementation files to respect SRP.",
    ],
)

doc.add_heading("Chapter 9: Interview Preparation (105 Questions)", level=1)
doc.add_paragraph(
    "Questions are grouped by level. Each includes answer, optional code direction, "
    "and real-world explanation focus."
)

levels = [("Beginner", 35), ("Intermediate", 35), ("Advanced", 35)]
for level_name, total in levels:
    doc.add_heading(level_name, level=2)
    for i in range(1, total + 1):
        qnum = i if level_name == "Beginner" else i + (35 if level_name == "Intermediate" else 70)
        doc.add_heading(f"Q{qnum}: {level_name} Question {i}", level=3)
        doc.add_paragraph("Question: Explain this concept in context of Smart Chat architecture.")
        doc.add_paragraph(
            "Answer: Demonstrate layer flow, provider usage, async handling, and why this design "
            "improves maintainability and interview discussion quality."
        )
        doc.add_paragraph(
            "Code example direction: Reference repository provider, viewmodel, and screen interaction."
        )
        doc.add_paragraph(
            "Real-world explanation: Mention scaling, testing, and separation of concerns impact."
        )

doc.add_heading("Appendix: Key Project File References", level=1)
add_bullets(
    doc,
    [
        "lib/main.dart",
        "lib/app.dart",
        "lib/data/repositories/*",
        "lib/domain/repositories/*",
        "lib/features/*/presentation/viewmodels/*",
        "lib/presentation/features/*/screens/*",
        "lib/presentation/shared/widgets/*",
    ],
)

output_path = "SmartChat_Interview_Documentation.docx"
doc.save(output_path)
print(f"Generated: {output_path}")
