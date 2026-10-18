import React from 'react';
import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { getDailyLimitMessage, DailyLimitToastContent } from './dailyLimit';

it('recognises the daily-limit 429 body from formatLimitError', () => {
  const err = {
    status: 429,
    data: {
      success: false,
      error: 'Daily moments limit exceeded. You have used 10 of 10 moments today.',
      message: 'Daily moments limit exceeded. You have used 10 of 10 moments today.',
    },
  };
  expect(getDailyLimitMessage(err)).toMatch(/Daily moments limit/);
});

it('recognises the translation limit (403 TRANSLATION_LIMIT_REACHED)', () => {
  const err = {
    status: 403,
    data: { error: 'TRANSLATION_LIMIT_REACHED', message: 'You have reached your daily translation limit.' },
  };
  expect(getDailyLimitMessage(err)).toMatch(/translation limit/);
});

it('ignores IP rate limiting and other errors', () => {
  expect(
    getDailyLimitMessage({ status: 429, data: { message: 'Too many requests from this IP, please try again later.' } })
  ).toBeNull();
  expect(getDailyLimitMessage({ status: 400, data: { error: 'Daily limit' } })).toBeNull();
  expect(getDailyLimitMessage(undefined)).toBeNull();
});

it('the toast links to the VIP page', () => {
  render(
    <MemoryRouter initialEntries={['/moments']}>
      <Routes>
        <Route path="/moments" element={<DailyLimitToastContent message="Daily limit" />} />
        <Route path="/settings/vip" element={<div>VIP PAGE</div>} />
      </Routes>
    </MemoryRouter>
  );
  fireEvent.click(screen.getByRole('button'));
  expect(screen.getByText('VIP PAGE')).toBeInTheDocument();
});
