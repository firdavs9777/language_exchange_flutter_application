// A stand-in for the LiveKit SDK's module namespace, for Jest only.
//
//   jest.mock("../../lib/livekit/livekitLoader", () =>
//     require("../../lib/livekit/testing/fakeLivekit").loaderMock());
//
// Never imported by application code (so never bundled). Mirrors only what
// src/lib/livekit/lkSession.ts touches; event names and enum values are the
// real ones from the SDK, version 2.22.4. (This file must not spell the
// package name: livekitLoader.test.ts allows it in the loader only.)
type Handler = (...args: any[]) => void;

export const RoomEvent = {
  ParticipantConnected: "participantConnected",
  ParticipantDisconnected: "participantDisconnected",
  ActiveSpeakersChanged: "activeSpeakersChanged",
  TrackSubscribed: "trackSubscribed",
  TrackUnsubscribed: "trackUnsubscribed",
  TrackMuted: "trackMuted",
  TrackUnmuted: "trackUnmuted",
  LocalTrackPublished: "localTrackPublished",
  LocalTrackUnpublished: "localTrackUnpublished",
  ParticipantMetadataChanged: "participantMetadataChanged",
  Reconnecting: "reconnecting",
  Reconnected: "reconnected",
  Disconnected: "disconnected",
  AudioPlaybackStatusChanged: "audioPlaybackChanged",
};

export const DisconnectReason = {
  UNKNOWN_REASON: 0,
  CLIENT_INITIATED: 1,
  DUPLICATE_IDENTITY: 2,
  SERVER_SHUTDOWN: 3,
  PARTICIPANT_REMOVED: 4,
  ROOM_DELETED: 5,
  STATE_MISMATCH: 6,
  JOIN_FAILURE: 7,
  MIGRATION: 8,
  SIGNAL_CLOSE: 9,
  ROOM_CLOSED: 10,
  CONNECTION_TIMEOUT: 14,
  MEDIA_FAILURE: 15,
};

export const Track = {
  Source: { Camera: "camera", Microphone: "microphone" },
  Kind: { Audio: "audio", Video: "video" },
};

let defaults: { canPlaybackAudio: boolean; connectError: any } = { canPlaybackAudio: true, connectError: null };
let pendingMediaFailure: string | null = null;
const rooms: FakeRoom[] = [];

export function setFakeDefaults(next: { canPlaybackAudio?: boolean; connectError?: any }): void {
  defaults = Object.assign({}, defaults, next);
}

/** The next setMicrophoneEnabled/setCameraEnabled throws {name}. */
export function failNextMedia(name: string): void {
  pendingMediaFailure = name;
}

export function resetFakeLivekit(): void {
  defaults = { canPlaybackAudio: true, connectError: null };
  pendingMediaFailure = null;
  rooms.length = 0;
}

function takeMediaFailure(): void {
  if (!pendingMediaFailure) return;
  const name = pendingMediaFailure;
  pendingMediaFailure = null;
  const err: any = new Error(name);
  err.name = name;
  throw err;
}

class FakeEmitter {
  private handlers: { [event: string]: Handler[] } = {};
  on(event: string, handler: Handler) {
    (this.handlers[event] = this.handlers[event] || []).push(handler);
    return this;
  }
  off(event: string, handler: Handler) {
    this.handlers[event] = (this.handlers[event] || []).filter((h) => h !== handler);
    return this;
  }
  removeAllListeners() {
    this.handlers = {};
    return this;
  }
  emit(event: string, ...args: any[]) {
    (this.handlers[event] || []).slice().forEach((h) => h(...args));
    return true;
  }
}

export function fakeTrack(kind: "audio" | "video", sid?: string) {
  const elements: HTMLMediaElement[] = [];
  return {
    kind,
    sid: sid || `${kind}-${Math.random().toString(36).slice(2, 8)}`,
    attach: jest.fn((el?: HTMLMediaElement) => {
      const node = el || (document.createElement(kind === "audio" ? "audio" : "video") as HTMLMediaElement);
      elements.push(node);
      return node;
    }),
    detach: jest.fn((el?: HTMLMediaElement) => {
      if (el) return [el];
      return elements.splice(0, elements.length);
    }),
  };
}

export function fakeRemote(identity: string, opts: { name?: string; micOn?: boolean; cameraOn?: boolean; metadata?: string } = {}) {
  return {
    identity,
    name: opts.name || identity,
    metadata: opts.metadata || "",
    isSpeaking: false,
    isMicrophoneEnabled: !!opts.micOn,
    isCameraEnabled: !!opts.cameraOn,
    getTrackPublication: (_source: string): any => undefined,
  };
}

class FakeLocalParticipant {
  identity = "me";
  name = "Me";
  metadata = "";
  isSpeaking = false;
  isMicrophoneEnabled = false;
  isCameraEnabled = false;
  cameraTrack: any = null;
  setMicrophoneEnabled = jest.fn(async (on: boolean) => {
    takeMediaFailure();
    this.isMicrophoneEnabled = on;
    return undefined;
  });
  setCameraEnabled = jest.fn(async (on: boolean) => {
    takeMediaFailure();
    this.isCameraEnabled = on;
    this.cameraTrack = on ? fakeTrack("video", "local-camera") : null;
    return undefined;
  });
  getTrackPublication = (source: string): any =>
    source === Track.Source.Camera && this.cameraTrack ? { videoTrack: this.cameraTrack } : undefined;
}

export class FakeRoom extends FakeEmitter {
  options: any;
  localParticipant = new FakeLocalParticipant();
  remoteParticipants = new Map<string, any>();
  canPlaybackAudio = defaults.canPlaybackAudio;
  connect = jest.fn(async (_url: string, _token: string) => {
    if (defaults.connectError) throw defaults.connectError;
  });
  disconnect = jest.fn(async () => {
    this.emit(RoomEvent.Disconnected, DisconnectReason.CLIENT_INITIATED);
  });
  startAudio = jest.fn(async () => {
    this.canPlaybackAudio = true;
    this.emit(RoomEvent.AudioPlaybackStatusChanged, true);
  });
  constructor(options?: any) {
    super();
    this.options = options;
    rooms.push(this);
  }
  /** Test helper: a remote participant joins. */
  addRemote(p: any) {
    this.remoteParticipants.set(p.identity, p);
    this.emit(RoomEvent.ParticipantConnected, p);
  }
  /** Test helper: a remote participant leaves. */
  removeRemote(identity: string) {
    const p = this.remoteParticipants.get(identity);
    this.remoteParticipants.delete(identity);
    this.emit(RoomEvent.ParticipantDisconnected, p);
  }
}

export const fakeModule = { Room: FakeRoom, RoomEvent, DisconnectReason, Track };

/** The last Room the code under test created. */
export function fakeRoom(): FakeRoom {
  return rooms[rooms.length - 1];
}

/** Module shape of src/lib/livekit/livekitLoader for jest.mock. */
export function loaderMock() {
  if (typeof navigator !== "undefined" && !(navigator as any).mediaDevices) {
    Object.defineProperty(navigator, "mediaDevices", { value: {}, configurable: true });
  }
  return { loadLivekit: () => Promise.resolve(fakeModule) };
}
