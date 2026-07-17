import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import UsernameAvailabilityField from './UsernameAvailabilityField';

const mockTrigger = jest.fn();
jest.mock('../../../store/slices/usersSlice', () => ({
  useLazyCheckUsernameQuery: () => [mockTrigger, {}],
}));

it('reports available:false for invalid format without calling API', async () => {
  const onAvail = jest.fn();
  render(<UsernameAvailabilityField value="" onChange={() => {}} onAvailabilityChange={onAvail} />);
  fireEvent.change(screen.getByRole('textbox'), { target: { value: 'ab' } });
  await waitFor(() => expect(onAvail).toHaveBeenCalledWith(false));
  expect(mockTrigger).not.toHaveBeenCalled();
});
it('empty value is treated as available (optional)', async () => {
  const onAvail = jest.fn();
  render(<UsernameAvailabilityField value="x" onChange={() => {}} onAvailabilityChange={onAvail} />);
  fireEvent.change(screen.getByRole('textbox'), { target: { value: '' } });
  await waitFor(() => expect(onAvail).toHaveBeenCalledWith(true));
});
