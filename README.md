# MultiTimer

A reactive, multi-stage state machine for complex asynchronous workflow management.

MultiTimer is a cross-platform application built with Flutter designed to orchestrate and track multi-step processes that require precise timing and sequential execution. The application provides a robust interface for managing overlapping or dependent timed tasks, ensuring high visibility into the status of long-running workflows.
## Key Features

- Reactive State Management: Implements a dedicated timer model to manage real-time updates and concurrent countdowns across the application.
- Sequential Stage Orchestration: Built to guide users through defined phases of a process, providing clear feedback on current progress and upcoming steps.
- Dynamic Temporal Formatting: Includes custom logic for converting raw durations into standardized, human-readable temporal formats.
- Decoupled Architecture: Follows a modular design pattern, separating core timing logic from the presentation layer to ensure scalability and maintainability.

## System Components
- Framework: Flutter.
- Language: Dart.
- Compatibility: Optimized for Android, iOS, Web, and Desktop environments.

## Repository Architecture

- lib/timer_model.dart: The core logic engine responsible for managing state transitions and high-precision countdown calculations.
- lib/timer_card.dart: A modular UI component for visualizing individual process stage progress.
- lib/home_page.dart: The primary dashboard that orchestrates the collection of active timers.
- lib/chain_model.dart: The logic of a chain: steps run one after another, linked automatically or with a manual continue, and catch up from the clock after the app was closed.
- lib/chain_card.dart: The card that shows a chain's current step, its progress and its controls.
- lib/list_item.dart: An entry in the main list, either a single timer or a chain.
- lib/bundles_page.dart and lib/bundle_editor_page.dart: Saved bundles (named groups of timers): list, create, edit, reorder, delete and add to the timer list. A bundle with two or more timers is added as one chain. The editor also shows and edits a chain's steps.
- lib/bundle_model.dart and lib/bundle_store.dart: The bundle data and its local storage.
- lib/main.dart: The application entry point, handling global configuration and theme initialization.

## Setup and Deployment

To deploy the application in a development environment:

- Environment Preparation: Ensure the Flutter SDK is configured on your system.

- Dependency Acquisition:
```Bash
    git clone https://github.com/alonagertskin/multitimer.git
    cd multitimer
    flutter pub get
```
- Connect an Android device/emulator or a supported desktop environment and run:
```Bash
    flutter run
```
## Development Roadmap

The project is currently in active development with the following professional milestones:

    [x] Persistence Layer: Implementation of local storage for session recovery and state persistence across application lifecycles.
    [x] Clock-Accurate Countdowns: Displayed time is calculated from each timer's end time, so it stays correct when the app is paused or in the background.
    [x] Background Notification Services: Integration of system-level alerts for stage completion during background execution.
    [x] Everyday Basics: Editing, reordering, swipe-to-delete with Undo, and an edit mode to select, reorder and delete several timers at once.
    [x] Bundles: Saved groups of timers that are added to the list in one tap, and can be edited, reordered and deleted.
    [x] Chain Cards: A bundle shown as one card that steps through its timers, automatically or with a manual continue between steps.
    [ ] Interface Polish.
