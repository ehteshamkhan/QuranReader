import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles.css";

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  render() {
    if (this.state.error) {
      const message =
        this.state.error?.stack ||
        this.state.error?.message ||
        String(this.state.error);

      return (
        <div className="fatal-error">
          <div className="fatal-error-card">
            <div className="fatal-error-icon">☾</div>
            <h1>Qur'an Reader couldn't start</h1>
            <p>
              The application encountered a JavaScript error instead of showing
              a blank page.
            </p>
            <pre>{message}</pre>
            <button onClick={() => window.location.reload()}>
              Reload Reader
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </React.StrictMode>
);