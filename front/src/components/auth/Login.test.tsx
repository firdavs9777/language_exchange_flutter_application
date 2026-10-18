import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useNavigate } from 'react-router-dom';
import Login from './Login';

jest.mock('react-redux', () => ({
  useDispatch: () => jest.fn(),
  useSelector: (sel: any) => sel({ auth: { userInfo: { _id: 'u1' } } }),
}));
jest.mock('../../store/slices/usersSlice', () => ({
  useLoginUserMutation: () => [jest.fn(), { isLoading: false }],
}));
// Login mounts the Apple button (P4-APPLE-5), which reads app-config.
jest.mock('../../store/slices/appConfigSlice', () => require('../../utils/testing/mockWebFlags').appConfigSliceMock());
jest.mock('../../store/slices/appleAuthSlice', () => ({
  useAppleWebLoginMutation: () => [jest.fn(), { isLoading: false }],
}));
jest.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string) => k }),
}));

const Back = ({ label }: { label: string }) => {
  const navigate = useNavigate();
  return <button onClick={() => navigate(-1)}>{label}</button>;
};

it('replaces /login in history after redirecting, so Back skips the login page', () => {
  render(
    <MemoryRouter
      initialEntries={['/home', '/login?redirect=/announcement/a1']}
      initialIndex={1}
    >
      <Routes>
        <Route path="/home" element={<p>home page</p>} />
        <Route path="/login" element={<Login />} />
        <Route path="/announcement/:id" element={<Back label="back" />} />
      </Routes>
    </MemoryRouter>
  );

  fireEvent.click(screen.getByRole('button', { name: 'back' }));
  expect(screen.getByText('home page')).toBeInTheDocument();
});
