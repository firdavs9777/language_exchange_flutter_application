/** The app's capacity stepper (create_gathering_form.dart: min 2, max 20). The model allows 50. */
export const MIN_CAPACITY = 2;
export const MAX_CAPACITY = 20;
export const MIN_QUORUM = 2;
/** The app's date picker: lastDate = now + 90 days. */
export const MAX_DAYS_AHEAD = 90;
/** Fixed in the app (`static const int _duration = 60`). */
export const DURATION_MINUTES = 60;
export const TITLE_MAX = 120;
export const DESCRIPTION_MAX = 2000;

export interface GatheringFormValues {
  title: string;
  description: string;
  language: string;
  level: string;
  topic: string;
  /** UTC ISO. */
  startsAt: string;
  durationMinutes: number;
  capacity: number;
  quorum: number;
  joinMode: "open" | "approval";
}

/** Tomorrow 19:00 in the viewer's zone, six seats, quorum three -- the app's pre-filled draft. */
export function defaultGatheringValues(now: Date, language: string): GatheringFormValues {
  const start = new Date(now.getTime());
  start.setDate(start.getDate() + 1);
  start.setHours(19, 0, 0, 0);
  return {
    title: "",
    description: "",
    language: language || "",
    level: "",
    topic: "",
    startsAt: start.toISOString(),
    durationMinutes: DURATION_MINUTES,
    capacity: 6,
    quorum: 3,
    joinMode: "open",
  };
}

export function validateGatheringForm(
  v: GatheringFormValues,
  ctx: { mode: "create" | "edit"; now: Date; going?: number; originalStartsAt?: string }
): { [field: string]: string } {
  const errors: { [field: string]: string } = {};
  const title = (v.title || "").trim();
  if (!title) errors.title = "titleRequired";
  else if (title.length > TITLE_MAX) errors.title = "titleTooLong";
  if ((v.description || "").length > DESCRIPTION_MAX) errors.description = "descriptionTooLong";
  if (!v.language) errors.language = "languageRequired";

  const start = v.startsAt ? new Date(v.startsAt).getTime() : NaN;
  // An edit that leaves the time alone does not send it (gatheringEditBody),
  // so the server does not re-check it -- neither does the form.
  const unchangedStart =
    ctx.mode === "edit" && !!ctx.originalStartsAt && new Date(ctx.originalStartsAt).getTime() === start;
  if (unchangedStart) {
    // nothing to check
  } else if (!v.startsAt || Number.isNaN(start)) errors.startsAt = "startRequired";
  else if (start <= ctx.now.getTime()) errors.startsAt = "startInPast";
  else if (start > ctx.now.getTime() + MAX_DAYS_AHEAD * 24 * 3600 * 1000) errors.startsAt = "startTooFar";

  const capacity = Number(v.capacity);
  if (!Number.isFinite(capacity) || capacity < MIN_CAPACITY || capacity > MAX_CAPACITY) {
    errors.capacity = "capacityRange";
  } else if (ctx.mode === "edit" && typeof ctx.going === "number" && capacity < ctx.going) {
    errors.capacity = "capacityBelowGoing";
  }

  if (ctx.mode === "create") {
    const quorum = Number(v.quorum);
    if (!Number.isFinite(quorum) || quorum < MIN_QUORUM || (!errors.capacity && quorum > capacity)) {
      errors.quorum = "quorumRange";
    }
  }
  return errors;
}
