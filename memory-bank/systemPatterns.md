# System Patterns: Hyperswitch Client Core

## Architecture Overview

### Core Architecture Pattern
The Hyperswitch Client Core follows a **Functional-First Multi-Platform Architecture** with the following key characteristics:

- **ReScript Core**: Functional programming approach with strong type safety
- **JavaScript Bridge**: Universal compatibility across platforms
- **Native Wrappers**: Platform-specific implementations that communicate with the core
- **Modular Design**: Loosely coupled components with clear boundaries

### High-Level System Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Platform  │    │ React Native    │    │ Native Platforms│
│   (Browser)     │    │   Platform      │    │  (iOS/Android)  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 JavaScript/ReScript Core                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Components  │  │   Hooks     │  │        Contexts         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Utilities  │  │    Types    │  │        Routes           │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Hyperswitch API │    │Payment Processors│    │Third-party APIs │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Key Technical Decisions

### 1. Language and Build System
- **ReScript**: Chosen for type safety, functional programming benefits, and JavaScript interop
- **Compilation Target**: JavaScript for universal platform compatibility
- **Build Tools**: ReScript compiler + platform-specific build systems (Webpack, Metro, Xcode, Gradle)

### 2. Cross-Platform Strategy
- **Shared Core Logic**: All business logic in ReScript/JavaScript
- **Platform Adapters**: Thin native layers for platform-specific features
- **Git Submodules**: Separate repositories for iOS and Android implementations
- **Bundle Management**: Platform-specific bundling strategies

### 3. State Management
- **React Context API**: For global state management
- **Hooks Pattern**: For component-level state and effects
- **Functional Approach**: Immutable state updates and pure functions

## Design Patterns in Use

### 1. Module Pattern
```
src/
├── components/     # Reusable UI components
├── contexts/       # Global state providers  
├── hooks/          # Custom React hooks
├── pages/          # Complete page implementations
├── routes/         # Navigation and routing
├── types/          # Type definitions
└── utility/        # Pure utility functions
```

### 2. Provider Pattern
- **Context Providers**: Wrap application with data providers
- **Dependency Injection**: Services injected through context
- **Configuration**: Environment-specific settings injected at runtime

### 3. Hook Pattern
- **Custom Hooks**: Encapsulate complex logic and state management
- **Composition**: Combine multiple hooks for complex behaviors
- **Reusability**: Share logic across components

### 4. Adapter Pattern
- **Platform Adapters**: Translate between native APIs and JavaScript core
- **Payment Method Adapters**: Consistent interface for different payment types
- **Network Adapters**: Abstract HTTP communication

### 5. Observer Pattern
- **Event Handling**: Payment status updates and user interactions
- **State Synchronization**: Keep UI in sync with payment state
- **Logging**: Centralized event tracking and debugging

## Component Relationships

### Core Component Hierarchy

```
App (Router)
├── ThemeProvider
├── LoadingProvider  
├── PaymentScreenProvider
├── LoggerProvider
└── AllApiDataProvider
    ├── Payment Pages
    │   ├── PaymentMethodSelection
    │   ├── PaymentForm
    │   └── PaymentConfirmation
    ├── Hosted Checkout
    ├── Payment Methods Management
    └── Widgets
        ├── CardWidget
        ├── BankWidget
        └── WalletWidget
```

### Context Relationships
- **AllApiDataContext**: Central data store for API responses
- **CardDataContext**: Manages payment card information
- **PaymentScreenContext**: Controls payment flow state
- **ThemeContext**: Manages styling and appearance
- **LoadingContext**: Handles loading states across app
- **LoggerContext**: Centralized logging and debugging

### Hook Dependencies
- **AllPaymentHooks**: Orchestrates complete payment flows
- **PaymentHook**: Handles individual payment operations
- **AllPaymentHelperHooks**: Utility functions for payment processing
- **BrowserHook**: Web-specific functionality
- **AlertHook**: User notifications and confirmations

## Critical Implementation Paths

### 1. Payment Initialization Flow
```
User Triggers Payment
       ↓
Initialize Payment Context
       ↓
Load Payment Methods from API
       ↓
Render Payment Method Selection
       ↓
User Selects Payment Method
       ↓
Load Payment Method Form
       ↓
Validate User Input
       ↓
Submit Payment Request
       ↓
Handle 3DS/Authentication
       ↓
Process Payment Response
       ↓
Update Payment Status
       ↓
Navigate to Confirmation
```

### 2. Cross-Platform Bridge Communication
```
JavaScript Core
       ↓
Platform Bridge (iOS/Android/Web)
       ↓
Native API Calls
       ↓
Response Handling
       ↓
Data Transformation
       ↓
JavaScript Callback
       ↓
UI Update
```

### 3. Error Handling Strategy
- **Validation Layer**: Client-side validation before API calls
- **Network Error Handling**: Retry logic and offline handling
- **Payment Specific Errors**: Specialized handling for payment failures
- **User-Friendly Messages**: Localized error messages
- **Logging**: Comprehensive error tracking for debugging

### 4. Security Implementation
- **Data Encryption**: Sensitive data encrypted in transit and at rest
- **Token Management**: Secure handling of API keys and session tokens
- **Input Sanitization**: Prevent injection attacks
- **Platform Security**: Leverage platform-specific security features

## Platform-Specific Patterns

### iOS Implementation
- **Swift Bridge**: Native Swift code communicating with JavaScript
- **Bundle Loading**: Load JavaScript bundle in iOS runtime
- **UI Integration**: Embed JavaScript UI in native view controllers
- **Keychain Integration**: Secure storage using iOS Keychain

### Android Implementation  
- **Kotlin Bridge**: Native Kotlin code with JavaScript engine
- **Bundle Management**: Asset loading and JavaScript execution
- **Activity Integration**: Embed in Android activities and fragments
- **SharedPreferences**: Secure storage using Android APIs

### Web Implementation
- **Webpack Bundling**: Optimized builds for web deployment
- **Progressive Enhancement**: Core functionality + enhanced features
- **Browser Compatibility**: Polyfills and feature detection
- **Performance Optimization**: Code splitting and lazy loading

### React Native Implementation
- **Metro Bundler**: React Native specific bundling
- **Native Modules**: Custom native module implementations
- **Bridge Communication**: JavaScript ↔ Native communication
- **Platform-Specific Code**: Conditional logic for iOS/Android differences

## Testing Patterns

### Unit Testing
- **Component Testing**: Isolated component behavior
- **Hook Testing**: Custom hook functionality
- **Utility Testing**: Pure function validation
- **Type Testing**: ReScript type system validation

### Integration Testing
- **Payment Flow Testing**: End-to-end payment scenarios
- **API Integration Testing**: External service communication
- **Cross-Platform Testing**: Behavior consistency across platforms
- **Error Scenario Testing**: Failure case handling

### Platform Testing
- **Detox (Mobile)**: End-to-end mobile app testing
- **Web Testing**: Browser compatibility testing
- **Performance Testing**: Load and stress testing
- **Security Testing**: Vulnerability assessment
