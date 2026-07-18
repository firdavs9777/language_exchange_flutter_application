import '@testing-library/jest-dom';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import { apiSlice } from '../../../store/slices/apiSlice';
import ForwardDialog from './ForwardDialog';

function makeStore() {
  return configureStore({
    reducer: {
      [apiSlice.reducerPath]: apiSlice.reducer,
      auth: (state: any = { userInfo: { user: { _id: 'me' } } }) => state,
    },
    middleware: (getDefaultMiddleware) => getDefaultMiddleware().concat(apiSlice.middleware),
  });
}

const conversationsPayload = {
  data: [
    {
      _id: 'c1',
      participants: [{ _id: 'me', name: 'Me' }, { _id: 'p1', name: 'Alice' }],
    },
    {
      _id: 'c2',
      participants: [{ _id: 'me', name: 'Me' }, { _id: 'p2', name: 'Bob' }],
    },
  ],
};

function mockFetch() {
  (global as any).fetch = jest.fn(async () => new Response(
    JSON.stringify(conversationsPayload),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  ));
}

it('renders nothing when closed', () => {
  mockFetch();
  const { container } = render(
    <Provider store={makeStore()}>
      <ForwardDialog open={false} onForward={jest.fn()} onClose={jest.fn()} />
    </Provider>
  );
  expect(container).toBeEmptyDOMElement();
});

it('lists conversation partners and forwards selected ids', async () => {
  mockFetch();
  const onForward = jest.fn();
  render(
    <Provider store={makeStore()}>
      <ForwardDialog open onForward={onForward} onClose={jest.fn()} />
    </Provider>
  );

  await waitFor(() => expect(screen.getByTestId('forward-target-p1')).toBeInTheDocument());
  expect(screen.getByTestId('forward-target-p2')).toBeInTheDocument();

  const submit = screen.getByTestId('forward-dialog-submit');
  expect(submit).toBeDisabled();

  fireEvent.click(screen.getByTestId('forward-target-p1'));
  expect(submit).not.toBeDisabled();

  fireEvent.click(submit);
  expect(onForward).toHaveBeenCalledWith(['p1']);
});

it('calls onClose when the close button is clicked', async () => {
  mockFetch();
  const onClose = jest.fn();
  render(
    <Provider store={makeStore()}>
      <ForwardDialog open onForward={jest.fn()} onClose={onClose} />
    </Provider>
  );
  await waitFor(() => expect(screen.getByTestId('forward-target-p1')).toBeInTheDocument());
  fireEvent.click(screen.getByTestId('forward-dialog-close'));
  expect(onClose).toHaveBeenCalledTimes(1);
});
