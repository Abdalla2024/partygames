# Party Games iOS App - Implementation Guide

## Project Overview

A SwiftUI-based party games app featuring 10 categories of interactive cards with a swipeable Tinder-like interface. Built using MVVM architecture with SwiftData for persistence.

## Architecture

### MVVM Pattern
- **Models**: SwiftData models for data persistence
- **ViewModels**: @Observable classes for reactive state management  
- **Views**: SwiftUI views with proper separation of concerns

### Core Components

#### Models (SwiftData)
1. **GameCategory** - Categories of party games
2. **GameCard** - Individual game cards with prompts  
3. **GameSession** - User game sessions and progress

#### ViewModels
1. **GameCategoriesViewModel** - Category management and state
2. **GameSessionViewModel** - Session management and progress
3. **CardInteractionViewModel** - Card gesture handling

#### Views
1. **CategorySelectionView** - Main category selection screen
2. **GameSessionView** - Game session interface  
3. **GameCardView** - Swipeable card component

## Data Structure

### Categories (10 total)
- Truth or Dare (52 cards)
- Would You Rather (52 cards) 
- Never Have I Ever (52 cards)
- Two Truths and a Lie (52 cards)
- Questions (52 cards)
- Deep Questions (52 cards)
- Couple Questions (52 cards)
- Friend Questions (52 cards)
- Family Questions (52 cards)
- Get to Know You (51 cards)

**Total: 463 cards across 10 categories**

## Key Features

### Card Interface
- Swipeable Tinder-like interface
- Gesture directions: Right (next), Left (skip), Up (favorite), Down (discard)
- Visual feedback and animations
- Progress tracking

### Session Management
- Start/pause/resume sessions
- Progress tracking and statistics
- Session history and analytics
- Card shuffling options

### Data Persistence
- SwiftData for local storage
- Automatic data initialization from JSON
- Session state preservation
- User preferences and favorites

## File Structure

```
Party Games/
├── Models/
│   ├── GameCategory.swift
│   ├── GameCard.swift
│   ├── GameSession.swift
│   └── GameDataManager.swift
├── ViewModels/
│   ├── GameCategoriesViewModel.swift
│   ├── GameSessionViewModel.swift
│   └── CardInteractionViewModel.swift
├── Views/
│   ├── CategorySelectionView.swift
│   ├── GameSessionView.swift
│   └── Components/
│       └── GameCardView.swift
├── ContentView.swift
└── Party_GamesApp.swift
```

## Implementation Status

✅ **Completed Components:**
- SwiftData models with relationships
- JSON data import system (463 cards)
- MVVM ViewModels with @Observable
- Category selection UI with grid layout
- Swipeable card interface with gestures
- Session management and progress tracking
- iOS-optimized UI components
- Build system configuration

## Getting Started

1. **Data Initialization**: App automatically imports card data from `couples_party_games_complete.json` on first launch
2. **Category Selection**: Users choose from 10 available categories
3. **Game Session**: Swipeable card interface with gesture controls
4. **Progress Tracking**: Session statistics and completion tracking

## Technical Details

- **Platform**: iOS 17.0+
- **Framework**: SwiftUI + SwiftData
- **Architecture**: MVVM with @Observable
- **Persistence**: SwiftData local storage
- **UI Pattern**: Card-based swiping interface
- **Gesture Support**: Multi-directional swipe gestures
- **State Management**: Reactive @Observable ViewModels

## Development Commands

```bash
# Build for simulator
xcodebuild build -project "Party Games.xcodeproj" -scheme "Party Games" -destination "name=iPhone 16"

# Run tests
xcodebuild test -project "Party Games.xcodeproj" -scheme "Party Games" -destination "name=iPhone 16"
```

## Data Sources

- **Primary Data**: `couples_party_games_complete.json` (463 cards)
- **Asset Icons**: Category icons in Assets.xcassets
- **Persistence**: SwiftData local database

This implementation provides a complete party games experience with professional UI/UX patterns and robust data management.