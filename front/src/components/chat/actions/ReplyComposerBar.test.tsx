import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import ReplyComposerBar from './ReplyComposerBar';

it('renders nothing when replyingTo is null', () => {
  const { container } = render(
    <ReplyComposerBar replyingTo={null} onCancel={jest.fn()} />
  );
  expect(container).toBeEmptyDOMElement();
});

it('renders the sender name and a quoted snippet of the original message', () => {
  const replyingTo = { sender: { name: 'Aziz' }, message: 'See you at the market tomorrow' };
  render(<ReplyComposerBar replyingTo={replyingTo} onCancel={jest.fn()} />);

  expect(screen.getByText('Replying to Aziz')).toBeInTheDocument();
  expect(screen.getByText('See you at the market tomorrow')).toBeInTheDocument();
});

it('calls onCancel when the x button is clicked', () => {
  const onCancel = jest.fn();
  const replyingTo = { sender: { name: 'Aziz' }, message: 'Hi' };
  render(<ReplyComposerBar replyingTo={replyingTo} onCancel={onCancel} />);

  fireEvent.click(screen.getByTestId('reply-composer-bar-cancel'));
  expect(onCancel).toHaveBeenCalledTimes(1);
});
