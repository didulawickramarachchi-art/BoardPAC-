import { Component } from 'react'

export default class ErrorBoundary extends Component {
  state = { error: null }
  static getDerivedStateFromError(error) { return { error } }
  componentDidCatch(error, info) { console.error('Uncaught application error', error, info) }
  render() {
    if (!this.state.error) return this.props.children
    return <main className="center-page" role="alert"><b>Application error</b><h2>This page could not be displayed</h2><p>{this.state.error.message}</p><button className="primary" onClick={() => window.location.reload()}>Reload application</button></main>
  }
}
