# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Plan & Review

### Before starting work
- Write a plan to .claude/tasks/TASK_NAME.md.
- The plan  should be a detailed implementation plan and the reasoning behind them, as well as tasks broken down.
- Don't over plan it, always think MVP.
- Once you write the plan, firstly ask me to review it. Do not continue until I approve the plan.

### While implementing
- You should update the plan as you work.
- After you complete tasks in the plan, you should update and append detailed descriptions of the changes you made, so following tasks can be easily handed over to other engineers

## Project Overview

Party Games is a SwiftUI-based iOS/macOS application created with Xcode's default SwiftData template. The app currently implements a basic item management interface with persistent storage using SwiftData.

## Architecture

### Core Components
- **App Entry Point**: `Party_GamesApp.swift` - Contains the main app structure with SwiftData ModelContainer setup
- **Main View**: `ContentView.swift` - Implements NavigationSplitView with list/detail interface for item management
- **Data Model**: `Item.swift` - Simple SwiftData model containing only a timestamp property
- **Testing**: Uses Swift Testing framework (not XCTest) in `Party_GamesTests.swift`

### Data Layer
The app uses SwiftData for persistence with a ModelContainer configured in the app entry point. The current schema includes only the `Item` model, stored persistently (not in-memory).

### UI Architecture
- NavigationSplitView pattern for iOS/macOS compatibility
- Platform-specific UI adjustments using `#if os()` preprocessor directives
- SwiftUI environment-based data access via `@Query` and `@Environment(\.modelContext)`

## Common Development Commands

### Building and Running
```bash
# Build for simulator
xcodebuild -scheme "Party Games" -destination "platform=iOS Simulator,name=iPhone 15" build

# Run tests
xcodebuild test -scheme "Party Games" -destination "platform=iOS Simulator,name=iPhone 15"
```

### Testing Framework
This project uses the new Swift Testing framework (imported as `Testing`), not XCTest. Tests should use:
- `@Test` attribute instead of `func test...`
- `#expect(...)` for assertions instead of `XCTAssert...`
- `async throws` test functions are supported

### Platform Considerations
- The app targets both iOS and macOS with conditional compilation
- macOS-specific UI adjustments use `#if os(macOS)` 
- iOS-specific toolbar items use `#if os(iOS)`
- App Sandbox is enabled for macOS distribution

## Key Development Patterns

### SwiftData Usage
- Models use `@Model` macro
- Views access data via `@Query` property wrapper
- ModelContext accessed through `@Environment(\.modelContext)`
- All data operations should be wrapped in `withAnimation` blocks

### Multiplatform Development
When adding new features, consider platform-specific UI patterns:
- NavigationSplitView column widths for macOS
- Toolbar placement differences between iOS and macOS
- App Sandbox requirements for file access on macOS