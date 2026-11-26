# Tech Context: Hyperswitch Client Core

## Technology Stack

### Core Technologies
- **ReScript 11.1.4**: Primary language for type-safe functional programming
- **React 19.0.0**: UI framework for component-based architecture
- **React Native 0.79.1**: Cross-platform mobile development framework
- **TypeScript 5.0.4**: Type definitions and gradual typing support
- **Node.js 18+**: Runtime environment and build tooling

### Build and Development Tools
- **Webpack 5.93.0**: Module bundling for web deployments
- **Metro**: React Native bundler and development server
- **Babel**: JavaScript compilation and transformation
- **ESLint**: Code linting and style enforcement
- **Prettier**: Code formatting and style consistency
- **Husky**: Git hooks for quality assurance

### Platform-Specific Technologies

#### iOS Development
- **Swift/Objective-C**: Native iOS implementation
- **Xcode**: Development environment and build system
- **CocoaPods**: Dependency management
- **iOS 12+**: Minimum supported version

#### Android Development
- **Kotlin/Java**: Native Android implementation
- **Gradle**: Build system and dependency management
- **Android Studio**: Development environment
- **Android API 21+**: Minimum supported version

#### Web Development
- **Webpack Dev Server**: Local development server
- **HTML/CSS/JS**: Standard web technologies
- **Progressive Web App**: Enhanced web capabilities
- **Modern Browser Support**: ES6+ features

## Development Setup

### Prerequisites
- Node.js 18+ with Yarn 3.6.4 package manager
- Platform-specific SDKs (Xcode for iOS, Android Studio for Android)
- Git with submodule support
- Development environment variables

### Installation Process
```bash
# Clone repository with submodules
git clone --recursive <repository-url>

# Install dependencies
yarn install

# Setup environment variables
cp .en .env
# Configure .env with required values

# Install platform-specific dependencies
yarn bundle  # iOS CocoaPods
```

### Development Commands
- `yarn run server`: Start mock development server
- `yarn run re:start`: Start ReScript compiler in watch mode
- `yarn run start`: Start React Native Metro bundler
- `yarn run web`: Start web development server
- `yarn run ios`: Launch iOS simulator
- `yarn run android`: Launch Android emulator

### Build Commands
- `yarn run re:build`: Compile ReScript to JavaScript
- `yarn run bundle:ios`: Create iOS bundle
- `yarn run bundle:android`: Create Android bundle
- `yarn run build:web`: Build optimized web bundle

## Technical Constraints

### Performance Requirements
- **Bundle Size**: Optimized for mobile platforms (<5MB total)
- **Load Time**: Initial load <3 seconds on 3G networks
- **Memory Usage**: Efficient memory management for mobile devices
- **Battery Impact**: Minimal battery drain during payment flows

### Compatibility Requirements
- **iOS**: Support iOS 12+ (95%+ device coverage)
- **Android**: Support API 21+ (Android 5.0+, 98%+ device coverage)
- **Web Browsers**: Support modern browsers (Chrome 80+, Firefox 75+, Safari 13+)
- **React Native**: Compatible with RN 0.79+ architecture

### Security Constraints
- **PCI DSS Compliance**: Secure handling of payment data
- **Data Encryption**: TLS 1.2+ for all network communication
- **Key Management**: Secure storage of API keys and tokens
- **Code Obfuscation**: Protection against reverse engineering

### Platform Limitations
- **iOS App Store**: Compliance with Apple guidelines
- **Google Play**: Compliance with Android policies
- **Web Security**: Content Security Policy (CSP) compliance
- **Cross-Origin**: CORS handling for web deployments

## Dependencies

### Core Dependencies
- **@sentry/react-native**: Error tracking and monitoring
- **react-native-svg**: Vector graphics support
- **react-native-inappbrowser-reborn**: In-app browser functionality

### Payment-Specific Dependencies
- **react-native-hyperswitch-netcetera-3ds**: 3D Secure authentication
- **react-native-hyperswitch-samsung-pay**: Samsung Pay integration
- **react-native-hyperswitch-scancard**: Card scanning functionality
- **react-native-klarna-inapp-sdk**: Klarna payment integration

### Development Dependencies
- **@rescript/core**: ReScript standard library
- **@rescript/react**: React bindings for ReScript
- **rescript-react-native**: React Native bindings for ReScript
- **detox**: End-to-end testing framework
- **jest**: Unit testing framework

### Build Dependencies
- **@react-native/babel-preset**: Babel configuration for React Native
- **@react-native/metro-config**: Metro bundler configuration
- **webpack-dev-server**: Web development server
- **semantic-release**: Automated release management

## Tool Usage Patterns

### ReScript Development
- **Type-First Development**: Define types before implementation
- **Functional Composition**: Prefer function composition over classes
- **Pattern Matching**: Use pattern matching for complex conditionals
- **Immutable Data**: Leverage ReScript's immutable data structures

### React Patterns
- **Hooks**: Use hooks for state management and side effects
- **Context**: Use React Context for global state
- **Component Composition**: Prefer composition over inheritance
- **Performance**: Use React.memo and useMemo for optimization

### Cross-Platform Development
- **Platform Detection**: Conditional logic for platform-specific features
- **Shared Components**: Maximize code reuse across platforms
- **Native Modules**: Minimal native code for platform-specific APIs
- **Bundle Management**: Platform-specific bundling strategies

### Testing Strategies
- **Unit Tests**: Jest for component and function testing
- **Integration Tests**: Testing payment flows end-to-end
- **Platform Tests**: Detox for mobile app testing
- **Manual Testing**: Device testing on real hardware

## Environment Configuration

### Environment Variables
```env
# API Endpoints
HYPERSWITCH_PRODUCTION_URL="https://api.hyperswitch.io"
HYPERSWITCH_INTEG_URL="https://integ-api.hyperswitch.io"
HYPERSWITCH_SANDBOX_URL="https://sandbox.hyperswitch.io"

# Logging Configuration
HYPERSWITCH_LOGS_PATH="/logs/sdk"

# Asset Endpoints
PROD_ASSETS_END_POINT="https://assets.hyperswitch.io"
SANDBOX_ASSETS_END_POINT="https://sandbox-assets.hyperswitch.io"
INTEG_ASSETS_END_POINT="https://integ-assets.hyperswitch.io"
```

### Platform-Specific Configuration

#### iOS Configuration
- **Info.plist**: App configuration and permissions
- **Bundle Identifier**: Unique app identifier
- **Code Signing**: Development and distribution certificates
- **Capabilities**: Payment processing permissions

#### Android Configuration
- **build.gradle**: Build configuration and dependencies
- **AndroidManifest.xml**: App permissions and components
- **Keystore**: App signing configuration
- **ProGuard**: Code obfuscation rules

#### Web Configuration
- **webpack.config.js**: Build and development server configuration
- **index.html**: Web app entry point
- **Progressive Web App**: Service worker and manifest configuration

## Development Workflow

### Version Control
- **Git Flow**: Feature branches with pull request reviews
- **Submodules**: iOS and Android repositories as submodules
- **Semantic Versioning**: Automated versioning with semantic-release
- **Change Logs**: Automated changelog generation

### Code Quality
- **ESLint**: JavaScript/TypeScript linting
- **ReScript Format**: Automatic code formatting
- **Prettier**: Consistent code style
- **Husky**: Pre-commit hooks for quality checks

### Continuous Integration
- **Automated Testing**: Run tests on all pull requests
- **Build Verification**: Ensure builds succeed on all platforms
- **Security Scanning**: Automated vulnerability detection
- **Performance Testing**: Monitor bundle size and performance

### Release Process
- **Semantic Release**: Automated version bumping and publishing
- **Platform Builds**: Automated iOS and Android builds
- **Distribution**: Automated deployment to app stores and CDN
- **Documentation**: Automated API documentation generation

## Debugging and Monitoring

### Development Tools
- **React Native Debugger**: Enhanced debugging for React Native
- **Flipper**: Mobile app debugging platform
- **ReScript Language Server**: IDE integration for ReScript
- **Metro Inspector**: React Native bundle analysis

### Production Monitoring
- **Sentry**: Error tracking and performance monitoring
- **Custom Logging**: Structured logging for payment flows
- **Analytics**: User interaction and payment conversion tracking
- **Performance Metrics**: Real-time performance monitoring

### Testing Tools
- **Jest**: Unit and integration testing
- **Detox**: End-to-end mobile app testing
- **React Native Testing Library**: Component testing utilities
- **Postman**: API testing and documentation
