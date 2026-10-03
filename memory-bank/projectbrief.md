# Project Brief: Hyperswitch Client Core

## Overview
Hyperswitch Client Core is a comprehensive cross-platform SDK that enables secure payment processing across multiple platforms including Web, iOS, Android, React Native, and Flutter. This repository serves as the foundational layer that powers the Hyperswitch payment ecosystem.

## Core Purpose
- **Unified Payment SDK**: Provide a single, consistent payment processing solution across all major platforms
- **Cross-Platform Compatibility**: Enable seamless integration with web, mobile, and native applications
- **Security-First Approach**: Implement secure payment flows with built-in fraud protection and compliance
- **Developer Experience**: Offer intuitive APIs and comprehensive documentation for easy integration

## Key Features
- Multi-platform support (Web, iOS, Android, React Native, Flutter)
- Secure payment processing with 3DS authentication
- Support for multiple payment methods (cards, wallets, bank transfers)
- Headless payment flows for custom UI implementations
- Real-time payment status tracking and webhooks
- Comprehensive logging and debugging capabilities
- Localization support for global markets

## Architecture Strategy
- **Modular Design**: Core logic written in ReScript, compiled to JavaScript for universal compatibility
- **Git Submodule Structure**: Enables platform-specific implementations while sharing core logic
- **Native Bridge Pattern**: Platform-specific wrappers communicate with the JavaScript core
- **Configurable Environment**: Support for production, sandbox, and integration environments

## Target Users
- **E-commerce Platforms**: Businesses needing robust payment processing
- **Mobile App Developers**: Native iOS/Android app developers
- **Web Developers**: Frontend teams building checkout experiences
- **Platform Integrators**: Teams integrating payments into existing systems

## Success Metrics
- Seamless cross-platform functionality
- High developer adoption and satisfaction
- Secure, PCI-compliant payment processing
- Performance optimization across all platforms
- Comprehensive test coverage and reliability

## Technical Constraints
- Must maintain compatibility across React Native 0.79+
- Support for iOS 12+ and Android API 21+
- Web compatibility with modern browsers
- Bundle size optimization for mobile platforms
- Offline capability for essential functions

## Integration Requirements
- Hyperswitch Dashboard API integration
- Support for multiple payment processors
- Webhook handling for payment status updates
- Environment-specific configuration management
- Comprehensive error handling and recovery
