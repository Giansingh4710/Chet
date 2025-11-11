# AGENTS.md - Quick Reference for Coding Agents

## Build & Test Commands
```bash
xcodebuild -project Chet.xcodeproj -scheme Chet -sdk iphonesimulator build  # Build for simulator
xcodebuild test -project Chet.xcodeproj -scheme Chet -destination 'platform=iOS Simulator,name=iPhone 15'  # Run all tests
xcodebuild test -project Chet.xcodeproj -scheme Chet -only-testing:ChetTests/ChetTests/testExample  # Run single test
```

## Code Style Guidelines
- **Naming**: PascalCase for types/protocols, camelCase for functions/variables, SCREAMING_SNAKE_CASE for constants
- **SwiftData Models**: Use `@Model`, `@Attribute(.unique)` for natural keys, appropriate `@Relationship` delete rules
- **Error Handling**: Use `try?` for SwiftData saves, async/await for API calls, no force unwrapping
- **Imports**: Group system frameworks first, then third-party (none used), then local modules
- **@AppStorage**: Prefix settings with "settings." or feature-specific names
- **Comments**: Document complex logic and API endpoints, use `// MARK: -` for section headers

## Key Patterns
- **Widget Updates**: Call `WidgetCenter.shared.reloadTimelines(ofKind:)` after data changes
- **Shared Data**: Use `UserDefaults.appGroup` and `group.xyz.gians.Chet` app group
- **File References**: Use format `filename:lineNumber` when referencing code (e.g., `Models.swift:292`)
- **Gestures**: Chain gesture modifiers appropriately, store temporary vs permanent scale values separately
- **Deep Links**: Handle `chet://` URLs in `onOpenURL` modifier with proper navigation path updates
