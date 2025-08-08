# Party Games App - MVVM Architecture Design Plan

## Executive Summary
Transform the current basic SwiftData app into a comprehensive party games application with 10 game categories, card-based UI, and swipe interactions using MVVM architecture.

## Requirements Analysis

### Core Features
- **10 Game Categories**: Would You Rather, Truth or Dare, This or That, Never Have I Ever, Who's Most Likely To, Memory Match, Impersonation, How Well Do You Know Me, Bucket List, Story Time
- **Card Interface**: Swipeable card deck for each game category
- **Data**: 463 total cards (approximately 46-52 cards per category)
- **Platform**: iOS/macOS multiplatform support
- **Storage**: SwiftData (no external database)

### Data Structure Analysis
```
Total Cards: 463
- Would You Rather: 52 cards
- Truth or Dare: 52 cards  
- This or That: 52 cards
- Memory Match: 52 cards
- Who's Most Likely To: 51 cards
- How Well Do You Know Me: 51 cards
- Impersonation: 51 cards
- Bucket List: 51 cards
- Never Have I Ever: 51 cards
- Story Time: 50 cards
```

## MVVM Architecture Design

### Model Layer (SwiftData)
```swift
// Core data models
@Model class GameCategory {
    var id: String
    var name: String
    var iconName: String
    var cardCount: Int
    var cards: [GameCard]
}

@Model class GameCard {
    var id: String
    var gameType: String
    var number: Int
    var prompt: String
    var isCompleted: Bool
    var category: GameCategory?
}

@Model class GameSession {
    var id: String
    var categoryId: String
    var currentCardIndex: Int
    var completedCards: [String]
    var startDate: Date
    var isActive: Bool
}
```

### ViewModel Layer
```swift
// Main categories management
@Observable class GameCategoriesViewModel {
    var categories: [GameCategory] = []
    var isLoading: Bool = false
    
    func loadCategories()
    func getCategoryByName(_ name: String) -> GameCategory?
}

// Individual game session management
@Observable class GameSessionViewModel {
    var currentSession: GameSession?
    var currentCard: GameCard?
    var remainingCards: [GameCard] = []
    var isSessionActive: Bool = false
    
    func startNewSession(for category: GameCategory)
    func nextCard()
    func markCardComplete()
    func shuffleCards()
    func resetSession()
}

// Card interaction management
@Observable class CardInteractionViewModel {
    var cardOffset: CGSize = .zero
    var isCardDragging: Bool = false
    
    func onCardDragChanged(_ value: DragGesture.Value)
    func onCardDragEnded(_ value: DragGesture.Value)
    func swipeToNextCard()
}
```

### View Layer (SwiftUI)
```swift
// Main category selection view
struct CategorySelectionView: View

// Individual game session view
struct GameSessionView: View

// Swipeable card component
struct GameCardView: View

// Navigation and flow management
struct ContentView: View (updated)
```

## Implementation Tasks

### Phase 1: Data Layer Setup
**Priority: High**
1. **Create SwiftData Models**
   - Design GameCategory, GameCard, GameSession models
   - Set up relationships and constraints
   - Add validation and computed properties

2. **JSON Data Loader**
   - Create service to parse couples_party_games_complete.json
   - Map JSON data to SwiftData models
   - Handle initial data seeding

3. **Asset Integration**
   - Move PNG icons to main Assets.xcassets
   - Create consistent naming convention
   - Ensure proper resolution support

### Phase 2: ViewModel Architecture
**Priority: High**
4. **GameCategoriesViewModel**
   - Implement category loading and management
   - Add filtering and search capabilities
   - Handle state management for loading states

5. **GameSessionViewModel**
   - Session lifecycle management
   - Card progression logic
   - Progress tracking and persistence

6. **CardInteractionViewModel**
   - Swipe gesture handling
   - Animation state management
   - Card transition effects

### Phase 3: UI Implementation
**Priority: Medium**
7. **CategorySelectionView**
   - Grid layout with category cards
   - Icon display and category names
   - Navigation to game sessions
   - Platform-specific adaptations (iOS/macOS)

8. **GameSessionView**
   - Card deck visualization
   - Progress indicators
   - Navigation controls
   - Session management UI

9. **GameCardView**
   - Swipeable card component
   - Gesture recognition
   - Visual feedback animations
   - Content layout and typography

### Phase 4: Integration & Polish
**Priority: Medium**
10. **Navigation Flow**
    - Update ContentView to support new navigation
    - Implement proper state restoration
    - Handle deep linking (future consideration)

11. **Platform Optimizations**
    - macOS-specific UI adjustments
    - Keyboard navigation support
    - Window sizing and constraints

12. **Testing & Validation**
    - Unit tests for ViewModels
    - SwiftData model tests
    - UI tests for core flows
    - Performance optimization

## Technical Specifications

### SwiftData Schema
```swift
// Schema configuration in App entry point
let schema = Schema([
    GameCategory.self,
    GameCard.self,
    GameSession.self
])
```

### File Structure
```
Party Games/
├── Models/
│   ├── GameCategory.swift
│   ├── GameCard.swift
│   └── GameSession.swift
├── ViewModels/
│   ├── GameCategoriesViewModel.swift
│   ├── GameSessionViewModel.swift
│   └── CardInteractionViewModel.swift
├── Views/
│   ├── CategorySelectionView.swift
│   ├── GameSessionView.swift
│   ├── GameCardView.swift
│   └── Components/
├── Services/
│   ├── GameDataLoader.swift
│   └── JSONParser.swift
└── Resources/
    └── couples_party_games_complete.json
```

### Dependencies & Tools
- SwiftUI (UI framework)
- SwiftData (persistence layer)
- Swift Testing (testing framework)
- No external dependencies required

## Risk Assessment

### Technical Risks
- **Medium**: SwiftData relationship complexity with large dataset
- **Low**: JSON parsing performance with 463 cards
- **Low**: Memory management with card animations

### Mitigation Strategies
- Lazy loading of cards within sessions
- Efficient SwiftData queries with @Query
- Proper memory management in ViewModels

## Success Metrics
- All 10 game categories display correctly
- Smooth card swiping with 60fps animations
- Session state persistence across app launches
- Support for both iOS and macOS platforms
- Zero crashes during normal usage flows

## MVP Scope
1. Category selection screen with all 10 games
2. Functional card swiping for each category
3. Basic session management (start/end games)
4. Data persistence with SwiftData
5. Core navigation between views

**Out of MVP Scope:**
- Advanced statistics/analytics
- Social sharing features
- Custom game creation
- Multiplayer support
- Advanced animations beyond basic swipe

## Next Steps
1. Review this plan for approval
2. Begin Phase 1 implementation
3. Iterate based on testing feedback
4. Continuous updates to this plan as development progresses