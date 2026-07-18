import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import PinnedBar from './PinnedBar';

it('renders nothing when pinned is empty', () => {
  const { container } = render(
    <PinnedBar pinned={[]} onJump={jest.fn()} onUnpin={jest.fn()} />
  );
  expect(container).toBeEmptyDOMElement();
});

it('shows the first pinned message and an N pinned affordance when there are more', () => {
  const pinned = [
    { _id: '1', message: 'First pinned message' },
    { _id: '2', message: 'Second pinned message' },
  ];
  render(<PinnedBar pinned={pinned} onJump={jest.fn()} onUnpin={jest.fn()} />);

  expect(screen.getByText('First pinned message')).toBeInTheDocument();
  expect(screen.getByText('2 pinned')).toBeInTheDocument();
});

it('calls onJump with the first pinned message id when the row is clicked', () => {
  const onJump = jest.fn();
  const pinned = [{ _id: 'abc', message: 'Hello' }];
  render(<PinnedBar pinned={pinned} onJump={onJump} onUnpin={jest.fn()} />);

  fireEvent.click(screen.getByTestId('pinned-bar-jump'));
  expect(onJump).toHaveBeenCalledWith('abc');
});

it('calls onUnpin with the first pinned message id when the x button is clicked', () => {
  const onUnpin = jest.fn();
  const pinned = [{ _id: 'abc', message: 'Hello' }];
  render(<PinnedBar pinned={pinned} onJump={jest.fn()} onUnpin={onUnpin} />);

  fireEvent.click(screen.getByTestId('pinned-bar-unpin'));
  expect(onUnpin).toHaveBeenCalledWith('abc');
});
