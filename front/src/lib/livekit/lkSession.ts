import { loadLivekit } from "./livekitLoader";

/**
 * The typed facade over LiveKit that voice rooms (P4-ROOM) and calls
 * (P4-CALL) share. Nothing outside src/lib/livekit touches the SDK: its
 * typings need TS >= 3.8, and every SDK quirk (autoplay, remote audio
 * elements, disconnect reasons) is handled once, here.
 */
export type LkMediaResult = "ok" | "denied" | "unavailable" | "error";

export interface LkPeer {
  identity: string;
  name: string;
  isLocal: boolean;
  isSpeaking: boolean;
  micOn: boolean;
  cameraOn: boolean;
  metadata: string;
}

export interface LkVideoTrack {
  attach(el: HTMLVideoElement): void;
  detach(el?: HTMLVideoElement): void;
}

export interface LkEvents {
  onPeers?(peers: LkPeer[]): void;
  onState?(s: "connecting" | "connected" | "reconnecting" | "disconnected"): void;
  onDisconnected?(reason: string): void;
  onAudioBlocked?(blocked: boolean): void;
  onRemoteVideo?(identity: string, track: LkVideoTrack | null): void;
}

export interface LkSession {
  connect(url: string, token: string, opts: { mic: boolean; camera: boolean }): Promise<LkMediaResult>;
  setMic(on: boolean): Promise<LkMediaResult>;
  setCamera(on: boolean): Promise<LkMediaResult>;
  localVideo(): LkVideoTrack | null;
  startAudio(): Promise<boolean>;
  peers(): LkPeer[];
  disconnect(): Promise<void>;
}

const DENIED = ["NotAllowedError", "SecurityError", "PermissionDeniedError"];
const UNAVAILABLE = ["NotFoundError", "DevicesNotFoundError", "OverconstrainedError", "NotReadableError", "TrackStartError"];

/** getUserMedia failures, by what the member can do about them. */
export function mediaErrorKind(err: any): LkMediaResult {
  const name = String((err && (err.name || (err.error && err.error.name))) || "");
  if (DENIED.indexOf(name) > -1) return "denied";
  if (UNAVAILABLE.indexOf(name) > -1) return "unavailable";
  return "error";
}

function hasMediaDevices(): boolean {
  return typeof navigator !== "undefined" && !!(navigator as any).mediaDevices;
}

export function createLkSession(events: LkEvents): LkSession {
  let lk: any = null;
  let room: any = null;
  let closedByClient = false;
  let finished = false;
  const audioEls: { [sid: string]: HTMLMediaElement[] } = {};

  const toPeer = (p: any, isLocal: boolean): LkPeer => ({
    identity: String((p && p.identity) || ""),
    name: String((p && p.name) || ""),
    isLocal,
    isSpeaking: !!(p && p.isSpeaking),
    micOn: !!(p && p.isMicrophoneEnabled),
    cameraOn: !!(p && p.isCameraEnabled),
    metadata: String((p && p.metadata) || ""),
  });

  const peers = (): LkPeer[] => {
    if (!room) return [];
    const out: LkPeer[] = [toPeer(room.localParticipant, true)];
    room.remoteParticipants.forEach((p: any) => out.push(toPeer(p, false)));
    return out;
  };
  const emitPeers = () => {
    if (events.onPeers) events.onPeers(peers());
  };
  const wrapTrack = (track: any): LkVideoTrack => ({
    attach: (el: HTMLVideoElement) => {
      track.attach(el);
    },
    detach: (el?: HTMLVideoElement) => {
      if (el) track.detach(el);
      else track.detach();
    },
  });

  const reasonName = (reason: any): string => {
    if (closedByClient) return "client";
    const R = (lk && lk.DisconnectReason) || {};
    if (reason === undefined || reason === null) return "unknown";
    if (reason === R.CLIENT_INITIATED) return "client";
    if (reason === R.DUPLICATE_IDENTITY) return "duplicate_identity";
    if (reason === R.ROOM_DELETED || reason === R.ROOM_CLOSED) return "room_deleted";
    if (reason === R.PARTICIPANT_REMOVED) return "participant_removed";
    if (reason === R.SERVER_SHUTDOWN) return "server_shutdown";
    if (
      reason === R.JOIN_FAILURE ||
      reason === R.SIGNAL_CLOSE ||
      reason === R.CONNECTION_TIMEOUT ||
      reason === R.MEDIA_FAILURE ||
      reason === R.STATE_MISMATCH
    ) {
      return "network";
    }
    return "unknown";
  };

  const removeAudio = (sid?: string) => {
    const keys = sid ? [sid] : Object.keys(audioEls);
    keys.forEach((k) => {
      (audioEls[k] || []).forEach((el) => {
        if (el.parentNode) el.parentNode.removeChild(el);
      });
      delete audioEls[k];
    });
  };

  const finish = (reason: any) => {
    if (finished) return;
    finished = true;
    removeAudio();
    const name = reasonName(reason);
    room = null;
    if (events.onState) events.onState("disconnected");
    if (events.onDisconnected) events.onDisconnected(name);
  };

  const wire = (r: any) => {
    const E = lk.RoomEvent;
    [
      E.ParticipantConnected,
      E.ParticipantDisconnected,
      E.ActiveSpeakersChanged,
      E.TrackMuted,
      E.TrackUnmuted,
      E.LocalTrackPublished,
      E.LocalTrackUnpublished,
      E.ParticipantMetadataChanged,
    ].forEach((ev: string) => r.on(ev, emitPeers));

    r.on(E.TrackSubscribed, (track: any, _pub: any, participant: any) => {
      if (track && track.kind === "audio") {
        const el = track.attach() as HTMLMediaElement;
        el.setAttribute("data-lk-audio", "1");
        el.style.display = "none";
        document.body.appendChild(el);
        audioEls[track.sid] = (audioEls[track.sid] || []).concat([el]);
      } else if (track && track.kind === "video" && events.onRemoteVideo) {
        events.onRemoteVideo(String(participant && participant.identity), wrapTrack(track));
      }
      emitPeers();
    });
    r.on(E.TrackUnsubscribed, (track: any, _pub: any, participant: any) => {
      if (track && track.kind === "audio") {
        track.detach();
        removeAudio(track.sid);
      } else if (track && track.kind === "video" && events.onRemoteVideo) {
        events.onRemoteVideo(String(participant && participant.identity), null);
      }
      emitPeers();
    });
    r.on(E.Reconnecting, () => {
      if (events.onState) events.onState("reconnecting");
    });
    r.on(E.Reconnected, () => {
      if (events.onState) events.onState("connected");
      emitPeers();
    });
    r.on(E.AudioPlaybackStatusChanged, () => {
      if (events.onAudioBlocked && room) events.onAudioBlocked(!room.canPlaybackAudio);
    });
    r.on(E.Disconnected, (reason: any) => finish(reason));
  };

  const setMic = async (on: boolean): Promise<LkMediaResult> => {
    if (!room) return "error";
    if (on && !hasMediaDevices()) return "unavailable";
    try {
      await room.localParticipant.setMicrophoneEnabled(on);
      emitPeers();
      return "ok";
    } catch (err) {
      emitPeers();
      return mediaErrorKind(err);
    }
  };

  const setCamera = async (on: boolean): Promise<LkMediaResult> => {
    if (!room) return "error";
    if (on && !hasMediaDevices()) return "unavailable";
    try {
      await room.localParticipant.setCameraEnabled(on);
      emitPeers();
      return "ok";
    } catch (err) {
      emitPeers();
      return mediaErrorKind(err);
    }
  };

  return {
    async connect(url, token, opts) {
      lk = await loadLivekit();
      closedByClient = false;
      finished = false;
      const r = new lk.Room({ adaptiveStream: true, dynacast: true });
      room = r;
      wire(r);
      if (events.onState) events.onState("connecting");
      try {
        await r.connect(url, token);
      } catch (err) {
        room = null;
        finished = true;
        if (events.onState) events.onState("disconnected");
        throw err;
      }
      if (events.onState) events.onState("connected");
      if (!r.canPlaybackAudio && events.onAudioBlocked) events.onAudioBlocked(true);
      emitPeers();
      let result: LkMediaResult = "ok";
      if (opts.mic) result = await setMic(true);
      if (opts.camera) {
        const cam = await setCamera(true);
        if (result === "ok") result = cam;
      }
      return result;
    },
    setMic,
    setCamera,
    localVideo() {
      if (!room || !lk) return null;
      const pub = room.localParticipant.getTrackPublication(lk.Track.Source.Camera);
      const track = pub && pub.videoTrack;
      return track ? wrapTrack(track) : null;
    },
    async startAudio() {
      if (!room) return false;
      try {
        await room.startAudio();
      } catch (err) {
        return false;
      }
      const ok = !!(room && room.canPlaybackAudio);
      if (events.onAudioBlocked) events.onAudioBlocked(!ok);
      return ok;
    },
    peers,
    async disconnect() {
      if (!room || finished) return;
      closedByClient = true;
      const r = room;
      try {
        await r.disconnect();
      } finally {
        // LiveKit emits Disconnected itself; this covers an SDK that did not.
        finish(undefined);
      }
    },
  };
}
