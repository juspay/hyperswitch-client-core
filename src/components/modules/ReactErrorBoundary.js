import React from 'react';

/**
 * Error boundary for Sentry.res. It is JavaScript because an error boundary
 * must be a class component, which ReScript cannot declare.
 *
 * Props: `fallback({ error, componentStack, resetError })`, the same contract
 * as Sentry's ErrorBoundary; `onError(error, componentStack)`, called once per
 * caught error; and `children`.
 */
export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null, componentStack: null };
    this.resetError = () => this.setState({ error: null, componentStack: null });
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    const componentStack = info && info.componentStack ? info.componentStack : null;
    this.setState({ componentStack });
    if (typeof this.props.onError === 'function') {
      try {
        this.props.onError(error, componentStack);
      } catch {
        // Reporting must never break the fallback.
      }
    }
  }

  render() {
    const { error, componentStack } = this.state;
    if (error != null) {
      return this.props.fallback({
        error,
        componentStack,
        resetError: this.resetError,
      });
    }
    return this.props.children;
  }
}
