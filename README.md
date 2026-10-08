# MultiTimer

MultiTimer runs several countdown timers at once. Save groups of timers as bundles and run them as chains, one step after another, automatically or with a tap to continue.

## Key Features

- Several timers side by side, each with its own progress bar. A finished timer keeps counting into negative time, so you can see how late it is.
- Alerts when a timer or a chain step finishes, also with the screen locked or the app closed.
- Bundles: saved groups of timers, such as "Dinner" or a workout, added in one tap.
- Chains: a bundle with two or more timers runs as one card, step by step. Each link between steps is automatic or waits for you to tap Continue.
- Everything is saved, and the time stays correct after the app was closed.
- Swipe to delete with Undo, an edit mode to select, reorder and delete several items, and a details screen to edit a running chain.
- A purple light theme and a green-teal dark theme that follow the phone's setting. Card colours show whether a timer is ready, running or finished. The Nunito font and a stopwatch app icon.

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
- lib/app_colors.dart: The light and dark themes (including the font), the card colours for ready, running and finished, and the swipe button colours.
- lib/card_parts.dart: The time style shared by timer and chain cards.
- lib/empty_list_message.dart: The message shown when there are no timers or no bundles yet.
- lib/main.dart: The application entry point: starts the notification service and opens the main screen.

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
    [x] Interface Polish: Light and dark themes, card colours by state, matching timer and chain cards with progress bars, messages for empty lists, bundle cards with a preview, and a compact bundle editor.
    [x] Finishing Touches: App icon, matching swipe button colours and the Nunito font.
