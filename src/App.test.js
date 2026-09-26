import { render, screen, fireEvent } from '@testing-library/react';
import App from './App';

describe('App Component', () => {
  test('renders hello world heading', () => {
    render(<App />);
    const heading = screen.getByText(/hello world/i);
    expect(heading).toBeInTheDocument();
  });

  test('renders welcome message', () => {
    render(<App />);
    const message = screen.getByText(/welcome to react with harness ci\/cd/i);
    expect(message).toBeInTheDocument();
  });

  test('displays initial count as 0', () => {
    render(<App />);
    const countDisplay = screen.getByText('Count:');
    expect(countDisplay).toBeInTheDocument();
  });

  test('increment button increases count', () => {
    render(<App />);
    const incrementBtn = screen.getByTestId('increment-btn');
    
    fireEvent.click(incrementBtn);
    
    const updatedCount = screen.getByText('1');
    expect(updatedCount).toBeInTheDocument();
  });

  test('reset button resets count to 0', () => {
    render(<App />);
    const incrementBtn = screen.getByTestId('increment-btn');
    const resetBtn = screen.getByTestId('reset-btn');
    
    fireEvent.click(incrementBtn);
    fireEvent.click(incrementBtn);
    fireEvent.click(resetBtn);
    
    const countDisplay = screen.getByText(/0/);
    expect(countDisplay).toBeInTheDocument();
  });

  test('decrement button decreases count', () => {
    render(<App />);
    const decrementBtn = screen.getByTestId('decrement-btn');
    
    fireEvent.click(decrementBtn);
    
    const countDisplay = screen.getByText(/-1/);
    expect(countDisplay).toBeInTheDocument();
  });

  test('renders harness pipeline stages', () => {
    render(<App />);
    const pipelineStages = screen.getByText('✅ Harness Pipeline Stages:');
    expect(pipelineStages).toBeInTheDocument();
  });

  test('renders all pipeline stage items', () => {
    render(<App />);
    expect(screen.getByText('Build & Test')).toBeInTheDocument();
    expect(screen.getByText('Code Quality Gates')).toBeInTheDocument();
    expect(screen.getByText('Staging Approval')).toBeInTheDocument();
    expect(screen.getByText('Deploy to Staging')).toBeInTheDocument();
    expect(screen.getByText('Smoke Tests')).toBeInTheDocument();
    expect(screen.getByText('Production Approval')).toBeInTheDocument();
    expect(screen.getByText('Deploy to Production')).toBeInTheDocument();
    expect(screen.getByText('Health Checks')).toBeInTheDocument();
  });
});
