# Party Games App - Architecture Overview

## System Architecture

### MVVM Pattern Implementation
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Views       │    │   ViewModels    │    │     Models      │
│                 │    │                 │    │                 │
│ CategorySelection│◄──►│GameCategoriesVM │◄──►│   GameCategory  │
│ GameSession     │    │GameSessionVM    │    │   GameCard      │
│ GameCard        │    │CardInteractionVM│    │   GameSession   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                ▲                       ▲
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   SwiftUI       │    │   SwiftData     │
                       │   @Observable   │    │   Persistence   │
                       └─────────────────┘    └─────────────────┘
```

## Core Components

### 1. Data Layer (SwiftData Models)

#### GameCategory
- **Purpose**: Represents game categories (Truth or Dare, Would You Rather, etc.)
- **Key Features**: 
  - Unique identification and naming
  - Card count tracking
  - Icon name for UI display
  - One-to-many relationship with GameCards
- **Persistence**: SwiftData @Model

#### GameCard  
- **Purpose**: Individual game prompts/questions
- **Key Features**:
  - Sequential numbering within categories
  - Prompt text content
  - Difficulty level (1-5)
  - Usage tracking and favorites
  - Many-to-one relationship with GameCategory
- **Persistence**: SwiftData @Model

#### GameSession
- **Purpose**: Tracks user game sessions and progress
- **Key Features**:
  - Session timing and duration
  - Progress tracking and completed cards
  - Player count and settings
  - Card shuffling state
  - Session statistics
- **Persistence**: SwiftData @Model

### 2. Business Logic Layer (ViewModels)

#### GameCategoriesViewModel
- **Responsibility**: Category management and selection
- **Key Features**:
  - Category loading and caching
  - Search and filtering capabilities
  - Data initialization from JSON
  - Error handling and loading states
- **Pattern**: @Observable for SwiftUI reactivity

#### GameSessionViewModel  
- **Responsibility**: Session lifecycle and card navigation
- **Key Features**:
  - Session start/pause/resume/end
  - Card progression and navigation
  - Progress calculation and statistics
  - Session validation and restoration
- **Pattern**: @Observable for SwiftUI reactivity

#### CardInteractionViewModel
- **Responsibility**: Card gesture handling and animations
- **Key Features**:
  - Swipe gesture processing (4 directions)
  - Animation state management
  - Card interaction feedback
  - Accessibility support
- **Pattern**: @Observable for SwiftUI reactivity

### 3. Presentation Layer (SwiftUI Views)

#### CategorySelectionView
- **Purpose**: Main app entry point for category selection
- **Features**:
  - Grid-based category display
  - Search functionality
  - Loading and error states
  - Navigation to game sessions

#### GameSessionView  
- **Purpose**: Game session interface (placeholder implementation)
- **Features**:
  - Session information display
  - Navigation controls
  - Session management UI

#### GameCardView
- **Purpose**: Interactive swipeable card component
- **Features**:
  - Multi-directional swipe gestures
  - Visual feedback and animations
  - Accessibility support
  - Card state management

## Data Flow Architecture

### 1. App Initialization Flow
```
App Launch → ContentView → Data Validation → JSON Import (if needed) → Category Loading
```

### 2. Category Selection Flow  
```
CategorySelectionView → GameCategoriesViewModel → SwiftData Query → UI Update
```

### 3. Game Session Flow
```
Category Selected → GameSessionView → GameSessionViewModel → Card Navigation → Progress Tracking
```

### 4. Card Interaction Flow
```
User Swipe → CardInteractionViewModel → Gesture Processing → Animation → Navigation
```

## State Management

### @Observable Pattern
- **ViewModels**: Use @Observable for reactive state updates
- **Views**: Automatic UI updates when ViewModel state changes
- **Performance**: Efficient SwiftUI re-rendering with minimal overhead

### SwiftData Integration
- **Model Context**: Shared across ViewModels for data operations
- **Queries**: Declarative fetch descriptors for data retrieval
- **Relationships**: Automatic relationship management between models
- **Persistence**: Automatic persistence with model changes

## Error Handling Strategy

### Graceful Degradation
- **Network**: Offline-first design with local data
- **Data**: Validation and fallback mechanisms  
- **UI**: Error states with recovery actions
- **Session**: State preservation and restoration

### Error Types
- **Data Import**: JSON parsing and validation errors
- **SwiftData**: Database operation failures
- **Navigation**: State consistency errors
- **User Input**: Validation and feedback

## Performance Considerations

### Memory Management
- **Lazy Loading**: Categories and cards loaded on demand
- **State Cleanup**: Proper ViewModel lifecycle management
- **Cache Strategy**: Intelligent caching of frequently accessed data

### UI Performance
- **Animation Optimization**: Smooth 60fps card interactions
- **List Performance**: Efficient category grid rendering
- **State Updates**: Minimal UI re-renders with @Observable

## Platform Considerations

### iOS-First Design
- **Target**: iOS 17.0+ for modern SwiftUI features
- **UI Patterns**: Native iOS design language and interactions
- **Gestures**: iOS-optimized touch and swipe handling
- **Accessibility**: Full VoiceOver and accessibility support

### SwiftUI Best Practices
- **View Composition**: Small, reusable view components
- **State Management**: Proper use of @State, @Observable
- **Navigation**: SwiftUI navigation patterns
- **Performance**: Efficient view updates and rendering

This architecture provides a solid foundation for a scalable, maintainable party games app with professional iOS development practices.