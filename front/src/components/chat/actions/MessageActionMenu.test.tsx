import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import MessageActionMenu, { MessageActionMenuProps } from './MessageActionMenu';

const noop = () => {};

const baseProps: Omit<MessageActionMenuProps, 'message' | 'meId'> = {
  onReply: jest.fn(),
  onForward: jest.fn(),
  onCopy: jest.fn(),
  onPin: jest.fn(),
  onBookmark: jest.fn(),
  onTts: jest.fn(),
  onEdit: jest.fn(),
  onDelete: jest.fn(),
  onReact: jest.fn(),
  onClose: jest.fn(),
};

const recentOwnTextMessage = {
  _id: 'm1',
  sender: 'me',
  messageType: 'text',
  createdAt: new Date().toISOString(),
};

const partnerMessage = {
  _id: 'm2',
  sender: 'partner',
  messageType: 'text',
  createdAt: new Date().toISOString(),
};

it('shows Edit for an editable own text message', () => {
  render(<MessageActionMenu {...baseProps} message={recentOwnTextMessage} meId="me" />);
  expect(screen.getByTestId('action-edit')).toBeInTheDocument();
  expect(screen.getByTestId('action-delete')).toHaveTextContent('Delete for everyone');
});

it('hides Edit for a partner message', () => {
  render(<MessageActionMenu {...baseProps} message={partnerMessage} meId="me" />);
  expect(screen.queryByTestId('action-edit')).not.toBeInTheDocument();
  expect(screen.getByTestId('action-delete')).toHaveTextContent('Delete');
  expect(screen.getByTestId('action-delete')).not.toHaveTextContent('everyone');
});

it('hides Edit for an own message that is too old', () => {
  const old = {
    ...recentOwnTextMessage,
    createdAt: new Date(Date.now() - 20 * 60 * 1000).toISOString(),
  };
  render(<MessageActionMenu {...baseProps} message={old} meId="me" />);
  expect(screen.queryByTestId('action-edit')).not.toBeInTheDocument();
});

it('calls onReply then onClose when Reply is clicked', () => {
  const onReply = jest.fn();
  const onClose = jest.fn();
  render(
    <MessageActionMenu
      {...baseProps}
      onReply={onReply}
      onClose={onClose}
      message={recentOwnTextMessage}
      meId="me"
    />
  );
  fireEvent.click(screen.getByTestId('action-reply'));
  expect(onReply).toHaveBeenCalledTimes(1);
  expect(onClose).toHaveBeenCalledTimes(1);
});

it('calls onReact then onClose when a quick-pick emoji is clicked', () => {
  const onReact = jest.fn();
  const onClose = jest.fn();
  render(
    <MessageActionMenu
      {...baseProps}
      onReact={onReact}
      onClose={onClose}
      message={recentOwnTextMessage}
      meId="me"
    />
  );
  fireEvent.click(screen.getByTestId('quick-pick-👍'));
  expect(onReact).toHaveBeenCalledWith('👍');
  expect(onClose).toHaveBeenCalledTimes(1);
});
