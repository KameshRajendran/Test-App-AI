import React from 'react';
import './App.css';

function App() {
  const [count, setCount] = React.useState(0);

  return (
    <div className="App">
      <header className="App-header">
        <h1>🚀 Hello World!</h1>
        <p>Welcome to React with Harness CI/CD Pipeline</p>
        
        <div className="card">
          <h2>Counter Demo</h2>
          <p>Count: <span className="count-display">{count}</span></p>
          <div className="button-group">
            <button 
              className="btn btn-increment"
              onClick={() => setCount(count + 1)}
              data-testid="increment-btn"
            >
              Increment
            </button>
            <button 
              className="btn btn-reset"
              onClick={() => setCount(0)}
              data-testid="reset-btn"
            >
              Reset
            </button>
            <button 
              className="btn btn-decrement"
              onClick={() => setCount(count - 1)}
              data-testid="decrement-btn"
            >
              Decrement
            </button>
          </div>
        </div>

        <div className="info">
          <h3>✅ Harness Pipeline Stages:</h3>
          <ul>
            <li>Build & Test</li>
            <li>Code Quality Gates</li>
            <li>Staging Approval</li>
            <li>Deploy to Staging</li>
            <li>Smoke Tests</li>
            <li>Production Approval</li>
            <li>Deploy to Production</li>
            <li>Health Checks</li>
          </ul>
        </div>

        <footer>
          <p>React v18.2 | Harness CI/CD | Kubernetes Ready</p>
        </footer>
      </header>
    </div>
  );
}

export default App;
