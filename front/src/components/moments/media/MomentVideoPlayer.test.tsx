import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import MomentVideoPlayer from './MomentVideoPlayer';

beforeAll(() => {
  window.HTMLMediaElement.prototype.play = jest.fn().mockResolvedValue(undefined);
  window.HTMLMediaElement.prototype.pause = jest.fn();
});

const video = {
  url: 'https://example.com/video.mp4',
  thumbnail: 'https://example.com/thumb.jpg',
  duration: 125,
  width: 1280,
  height: 720,
};

it('renders a video element with the given src and poster', () => {
  render(<MomentVideoPlayer video={video} />);

  const videoEl = screen.getByTestId('moment-video-element');
  expect(videoEl.tagName).toBe('VIDEO');
  expect(videoEl).toHaveAttribute('src', video.url);
  expect(videoEl).toHaveAttribute('poster', video.thumbnail);
});

it('shows the formatted duration badge (mm:ss)', () => {
  render(<MomentVideoPlayer video={video} />);

  expect(screen.getByTestId('moment-video-duration-badge')).toHaveTextContent('2:05');
});

it('shows the center play overlay before first play', () => {
  render(<MomentVideoPlayer video={video} />);

  expect(screen.getByTestId('moment-video-play-overlay')).toBeInTheDocument();
});

it('renders gracefully when thumbnail and duration are absent', () => {
  render(<MomentVideoPlayer video={{ url: video.url }} />);

  const videoEl = screen.getByTestId('moment-video-element');
  expect(videoEl).not.toHaveAttribute('poster');
  expect(screen.queryByTestId('moment-video-duration-badge')).not.toBeInTheDocument();
  expect(screen.getByTestId('moment-video-play-overlay')).toBeInTheDocument();
});
