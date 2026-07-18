import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import GradientMomentCard from './GradientMomentCard';
import { MOMENT_GRADIENTS, DEFAULT_GRADIENT_KEY } from './momentGradients';

it('renders the given text', () => {
  render(<GradientMomentCard text="Feeling great today!" />);
  expect(screen.getByText('Feeling great today!')).toBeInTheDocument();
});

it('applies the CSS gradient for a known background key', () => {
  render(<GradientMomentCard text="Sunset vibes" backgroundColor="gradient_ocean" />);
  const card = screen.getByTestId('gradient-moment-card');
  expect(card).toHaveStyle({ background: MOMENT_GRADIENTS.gradient_ocean });
});

it('falls back to the default gradient for an unknown key', () => {
  render(<GradientMomentCard text="Mystery mood" backgroundColor="not_a_real_key" />);
  const card = screen.getByTestId('gradient-moment-card');
  expect(card).toHaveStyle({ background: MOMENT_GRADIENTS[DEFAULT_GRADIENT_KEY] });
});

it('falls back to the default gradient when no key is provided', () => {
  render(<GradientMomentCard text="No color at all" />);
  const card = screen.getByTestId('gradient-moment-card');
  expect(card).toHaveStyle({ background: MOMENT_GRADIENTS[DEFAULT_GRADIENT_KEY] });
});
