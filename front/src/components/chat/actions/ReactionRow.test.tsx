import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import ReactionRow, { aggregateReactions } from './ReactionRow';

const reactions = [
  { emoji: '❤️', users: ['me', 'x'] },
  { emoji: '👍', users: ['y'] },
];

it('aggregateReactions counts per emoji and flags reactedByMe', () => {
  const result = aggregateReactions(reactions, 'me');
  expect(result).toEqual([
    { emoji: '❤️', count: 2, reactedByMe: true },
    { emoji: '👍', count: 1, reactedByMe: false },
  ]);
});

it('renders aggregated chips, highlights mine, and toggles on click', () => {
  const onToggle = jest.fn();
  render(<ReactionRow reactions={reactions} myUserId="me" onToggle={onToggle} />);

  const heartChip = screen.getByTestId('reaction-chip-❤️');
  const thumbsChip = screen.getByTestId('reaction-chip-👍');

  expect(heartChip).toHaveTextContent('❤️');
  expect(heartChip).toHaveTextContent('2');
  expect(heartChip).toHaveAttribute('aria-pressed', 'true');
  expect(heartChip.className).toMatch(/teal/);

  expect(thumbsChip).toHaveTextContent('1');
  expect(thumbsChip).toHaveAttribute('aria-pressed', 'false');
  expect(thumbsChip.className).not.toMatch(/teal/);

  fireEvent.click(heartChip);
  expect(onToggle).toHaveBeenCalledWith('❤️');
});

it('renders nothing when there are no reactions and quick-pick is off', () => {
  const { container } = render(
    <ReactionRow reactions={[]} myUserId="me" onToggle={jest.fn()} />
  );
  expect(container).toBeEmptyDOMElement();
});

it('tolerates undefined reactions and still shows quick-pick when asked', () => {
  render(<ReactionRow reactions={undefined} myUserId="me" onToggle={jest.fn()} showQuickPick />);
  expect(screen.getByTestId('quick-pick-👍')).toBeInTheDocument();
});

it('clicking a quick-pick emoji calls onToggle', () => {
  const onToggle = jest.fn();
  render(<ReactionRow reactions={[]} myUserId="me" onToggle={onToggle} showQuickPick />);
  fireEvent.click(screen.getByTestId('quick-pick-😂'));
  expect(onToggle).toHaveBeenCalledWith('😂');
});
