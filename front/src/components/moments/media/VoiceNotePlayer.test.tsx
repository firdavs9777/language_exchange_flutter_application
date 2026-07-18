import '@testing-library/jest-dom';
import { render, screen, fireEvent } from '@testing-library/react';
import VoiceNotePlayer from './VoiceNotePlayer';

beforeAll(() => {
  // jsdom doesn't implement audio playback; stub it out.
  window.HTMLMediaElement.prototype.play = jest.fn().mockResolvedValue(undefined);
  window.HTMLMediaElement.prototype.pause = jest.fn();
});

describe('VoiceNotePlayer', () => {
  it('renders a play button', () => {
    render(
      <VoiceNotePlayer
        audio={{ url: 'https://example.com/note.webm', duration: 12, waveform: [0.2, 0.5, 0.8, 0.3] }}
      />
    );
    expect(screen.getByTestId('voice-note-play-button')).toBeInTheDocument();
    expect(screen.getByLabelText('Play voice note')).toBeInTheDocument();
  });

  it('renders one waveform bar per sample', () => {
    const waveform = [0.1, 0.4, 0.9, 0.2, 0.6, 0.3];
    render(
      <VoiceNotePlayer audio={{ url: 'https://example.com/note.webm', duration: 8, waveform }} />
    );
    expect(screen.getAllByTestId('voice-note-waveform-bar')).toHaveLength(waveform.length);
  });

  it('shows a flat fallback bar set when waveform is empty', () => {
    render(<VoiceNotePlayer audio={{ url: 'https://example.com/note.webm', duration: 5, waveform: [] }} />);
    const bars = screen.getAllByTestId('voice-note-waveform-bar');
    expect(bars.length).toBeGreaterThan(0);
  });

  it('shows the formatted total duration (mm:ss)', () => {
    render(
      <VoiceNotePlayer audio={{ url: 'https://example.com/note.webm', duration: 75, waveform: [0.5, 0.5] }} />
    );
    // 75s => 1:15
    expect(screen.getByTestId('voice-note-time')).toHaveTextContent('1:15');
  });

  it('toggles to pause after clicking play', () => {
    render(
      <VoiceNotePlayer audio={{ url: 'https://example.com/note.webm', duration: 10, waveform: [0.5, 0.6] }} />
    );
    const button = screen.getByTestId('voice-note-play-button');
    fireEvent.click(button);
    expect(screen.getByLabelText('Pause voice note')).toBeInTheDocument();
    expect(window.HTMLMediaElement.prototype.play).toHaveBeenCalled();
  });
});
