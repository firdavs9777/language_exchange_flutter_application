import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import PasswordStrengthMeter from './PasswordStrengthMeter';

it('shows Weak for short password', () => {
  render(<PasswordStrengthMeter password="abc" />);
  expect(screen.getByText(/Weak/i)).toBeInTheDocument();
});
it('shows Strong for compliant password', () => {
  render(<PasswordStrengthMeter password="Abcdef12" />);
  expect(screen.getByText(/Strong/i)).toBeInTheDocument();
});
