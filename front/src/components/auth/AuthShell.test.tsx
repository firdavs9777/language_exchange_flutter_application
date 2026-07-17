import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import AuthShell from './AuthShell';

it('renders title, subtitle, and children', () => {
  render(<AuthShell title="Reset password" subtitle="We'll email you a code"><button>Go</button></AuthShell>);
  expect(screen.getByText('Reset password')).toBeInTheDocument();
  expect(screen.getByText("We'll email you a code")).toBeInTheDocument();
  expect(screen.getByRole('button', { name: 'Go' })).toBeInTheDocument();
});
