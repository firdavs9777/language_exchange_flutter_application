import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import MomentReactionRow from './MomentReactionRow';

const reactions = [
  { emoji: '❤️', users: ['me', 'x'] },
  { emoji: '🔥', users: ['y'] },
];

it('aggregates duplicate emojis into one chip with the right count', () => {
  render(<MomentReactionRow reactions={reactions} myUserId="me" onToggle={jest.fn()} />);

  const heartChip = screen.getByTestId('moment-reaction-chip-❤️');
  const fireChip = screen.getByTestId('moment-reaction-chip-🔥');

  expect(heartChip).toHaveTextContent('❤️');
  expect(heartChip).toHaveTextContent('2');
  expect(fireChip).toHaveTextContent('1');
});

it("highlights the current user's reaction", () => {
  render(<MomentReactionRow reactions={reactions} myUserId="me" onToggle={jest.fn()} />);

  const heartChip = screen.getByTestId('moment-reaction-chip-❤️');
  const fireChip = screen.getByTestId('moment-reaction-chip-🔥');

  expect(heartChip).toHaveAttribute('aria-pressed', 'true');
  expect(heartChip.className).toMatch(/teal/);

  expect(fireChip).toHaveAttribute('aria-pressed', 'false');
  expect(fireChip.className).not.toMatch(/teal/);
});

it('fires onToggle with the emoji when a chip is clicked', () => {
  const onToggle = jest.fn();
  render(<MomentReactionRow reactions={reactions} myUserId="me" onToggle={onToggle} />);

  fireEvent.click(screen.getByTestId('moment-reaction-chip-🔥'));
  expect(onToggle).toHaveBeenCalledWith('🔥');
});

it('renders nothing when there are no reactions and quick-pick is off', () => {
  const { container } = render(
    <MomentReactionRow reactions={[]} myUserId="me" onToggle={jest.fn()} />
  );
  expect(container).toBeEmptyDOMElement();
});

it('renders the moments quick-pick row when showQuickPick is true', () => {
  const onToggle = jest.fn();
  render(
    <MomentReactionRow reactions={[]} myUserId="me" onToggle={onToggle} showQuickPick />
  );

  expect(screen.getByTestId('moment-quick-pick-❤️')).toBeInTheDocument();
  expect(screen.getByTestId('moment-quick-pick-🔥')).toBeInTheDocument();
  expect(screen.getByTestId('moment-quick-pick-😂')).toBeInTheDocument();
  expect(screen.getByTestId('moment-quick-pick-😢')).toBeInTheDocument();
  expect(screen.getByTestId('moment-quick-pick-😮')).toBeInTheDocument();
  expect(screen.getByTestId('moment-quick-pick-👏')).toBeInTheDocument();

  fireEvent.click(screen.getByTestId('moment-quick-pick-😂'));
  expect(onToggle).toHaveBeenCalledWith('😂');
});
