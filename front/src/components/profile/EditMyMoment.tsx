import React, { useState, useEffect, useRef, ChangeEvent, FormEvent } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useSelector } from "react-redux";
import { Bounce, toast } from "react-toastify";
import { ArrowLeft, Loader2, MapPin, Plus, X } from "lucide-react";
import SurfaceCard from "../../design/SurfaceCard";
import {
  useGetMomentDetailsQuery,
  useUpdateMomentMutation,
  useUploadMomentPhotosMutation,
} from "../../store/slices/momentsSlice";
import BackgroundField from "../moments/fields/BackgroundField";
import CategoryField from "../moments/fields/CategoryField";
import LanguageField from "../moments/fields/LanguageField";
import MediaEditor from "../moments/fields/MediaEditor";
import MoodField from "../moments/fields/MoodField";
import PrivacyField from "../moments/fields/PrivacyField";
import ScheduleField from "../moments/fields/ScheduleField";
import TagsField from "../moments/fields/TagsField";
import { useCurrentLocation } from "../moments/fields/useCurrentLocation";
import { EditableMoment, editableFrom, momentEditDiff } from "../moments/lib/momentEditDiff";
import { isFutureInput, isScheduledLater, localInputToIso, toLocalInput } from "../moments/lib/scheduling";
import { useMomentSchedulingEnabled } from "../moments/lib/useMomentSchedulingEnabled";

const MAX_IMAGES = 10;

const PAGE = "min-h-screen bg-canvas dark:bg-canvas-dark";
const COLUMN = "mx-auto w-full max-w-2xl px-3 pb-16 pt-4 sm:px-4 sm:pt-6";

const FIELD = [
  "w-full rounded-chip border border-line bg-surface px-3.5 py-2.5 text-sm",
  "text-ink-900 placeholder:text-ink-400",
  "focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand/[0.35]",
  "dark:border-line-dark dark:bg-cardbg-dark dark:text-ink-50",
].join(" ");

const LABEL =
  "block pb-1 text-xs font-semibold uppercase tracking-wide text-ink-500 dark:text-ink-400";

const REMOVE =
  "absolute right-1.5 top-1.5 rounded-full bg-red-600 p-1.5 text-white opacity-0 transition-opacity focus:opacity-100 group-hover:opacity-100";

const TOAST = { autoClose: 3000, theme: "dark" as "dark", transition: Bounce };

/**
 * The moment editor, on the design system.
 *
 * Same endpoints and same two-step save as before (details first, then any new
 * photos), with react-bootstrap's `Form`/`Card`/`Image` and its inline
 * `style={{ height: "150px" }}` tiles replaced by the grid the rest of the
 * profile uses.
 */
const EditMyMoment: React.FC = () => {
  const { id: momentId } = useParams<{ id: string }>();
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [original, setOriginal] = useState<EditableMoment>(() => editableFrom(null));
  const [draft, setDraft] = useState<EditableMoment>(() => editableFrom(null));
  const [scheduleInput, setScheduleInput] = useState("");
  const [notice, setNotice] = useState("");
  const schedulingEnabled = useMomentSchedulingEnabled();
  const [selectedImages, setSelectedImages] = useState<File[]>([]);
  const [imagePreviews, setImagePreviews] = useState<string[]>([]);
  const [existingImages, setExistingImages] = useState<string[]>([]);

  const { data: momentDetails, isLoading: isLoadingDetails } = useGetMomentDetailsQuery(
    momentId as string
  );
  const [updateMoment, { isLoading: isUpdating }] = useUpdateMomentMutation();
  const [uploadMomentPhotos, { isLoading: isUploading }] = useUploadMomentPhotosMutation();

  const fileInputRef = useRef<HTMLInputElement>(null);
  const user = useSelector((state: any) => state.auth.userInfo?.user?._id);

  const moment = momentDetails && (momentDetails as any).data;

  // Seeded once per moment. A media replace/remove invalidates the detail
  // query and refetches a new object; re-seeding then would throw away
  // whatever the reader had typed.
  const seededFor = useRef<string | null>(null);
  const [seededSchedule, setSeededSchedule] = useState("");
  useEffect(() => {
    if (!moment) return;
    setExistingImages(Array.isArray(moment.imageUrls) ? moment.imageUrls : []);
    if (seededFor.current === moment._id) return;
    seededFor.current = moment._id;
    const editable = editableFrom(moment);
    setOriginal(editable);
    setDraft(editable);
    const scheduleText = editable.scheduledFor ? toLocalInput(editable.scheduledFor) : "";
    setScheduleInput(scheduleText);
    setSeededSchedule(scheduleText);
  }, [moment]);

  const set = <K extends keyof EditableMoment>(key: K, value: EditableMoment[K]) => {
    setNotice("");
    setDraft((previous) => ({ ...previous, [key]: value }));
  };
  const setLocation = React.useCallback((location: any) => {
    setNotice("");
    setDraft((previous) => ({ ...previous, location }));
  }, []);
  const addLocation = useCurrentLocation(setLocation);

  // The schedule is editable only while the moment has not gone out, and only
  // while the server enforces scheduling (otherwise it would publish now).
  const canSchedule = schedulingEnabled && isScheduledLater(original);
  // The input shows minutes only; an untouched schedule keeps its exact
  // stored instant (seconds included) and is never re-sent or re-validated.
  const scheduleTouched = scheduleInput !== seededSchedule;
  const scheduleBlocked =
    canSchedule && scheduleTouched && Boolean(scheduleInput) && !isFutureInput(scheduleInput);
  const isTextMoment = moment && moment.mediaType === "text";
  // A moment carries one kind of media: a video or voice note is edited in
  // its own section, and photos cannot be added beside it.
  const hasAvMedia = Boolean(moment && (moment.mediaType === "video" || moment.mediaType === "audio"));

  // Leaving someone else's moment open in an editor they cannot save is worse
  // than bouncing them: the save would 403 after they had typed.
  useEffect(() => {
    if (!moment || !user) return;
    const owner = moment.user && (moment.user._id || moment.user);
    if (owner && owner !== user) {
      toast.error(t("editMoment.toast.notAuthorized"), TOAST);
      navigate("/moments");
    }
  }, [moment, user, navigate, t]);

  useEffect(
    () => () => {
      imagePreviews.forEach((preview) => URL.revokeObjectURL(preview));
    },
    [imagePreviews]
  );

  const total = existingImages.length + imagePreviews.length;
  // A moment is a caption OR media: the caption may be cleared while the
  // moment keeps (or is about to gain) a photo, video or voice note.
  const hasMedia = existingImages.length > 0 || selectedImages.length > 0 || hasAvMedia;
  const canSubmit =
    (draft.description.trim() !== "" || hasMedia) && !scheduleBlocked && !isUpdating && !isUploading;

  const handleImageUpload = (event: ChangeEvent<HTMLInputElement>): void => {
    const files = Array.prototype.slice.call(event.target.files || []) as File[];
    if (files.length === 0) return;
    if (files.length + total > MAX_IMAGES) {
      toast.error(t("editMoment.toast.maxImagesError"), TOAST);
      return;
    }
    setSelectedImages((previous) => previous.concat(files));
    setImagePreviews((previous) =>
      previous.concat(files.map((file) => URL.createObjectURL(file)))
    );
  };

  const handleAddMoreImages = (): void => {
    if (total >= MAX_IMAGES) {
      toast.error(t("editMoment.toast.maxImagesError"), TOAST);
      return;
    }
    if (fileInputRef.current) fileInputRef.current.click();
  };

  const handleRemoveImage = (index: number): void => {
    URL.revokeObjectURL(imagePreviews[index]);
    setSelectedImages((previous) => previous.filter((unused, i) => i !== index));
    setImagePreviews((previous) => previous.filter((unused, i) => i !== index));
  };

  const handleSubmit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    if (!canSubmit) return;

    const next: EditableMoment = {
      ...draft,
      scheduledFor:
        canSchedule && scheduleTouched
          ? scheduleInput
            ? localInputToIso(scheduleInput)
            : null
          : original.scheduledFor,
    };
    const changes = momentEditDiff(original, next);
    if (Object.keys(changes).length === 0 && selectedImages.length === 0) {
      setNotice(t("editMoment.form.nothingToSave") || "Nothing to change yet");
      return;
    }

    const uploadPhotos = async () => {
      if (selectedImages.length === 0) return;
      const upload = new FormData();
      selectedImages.forEach((file) => upload.append("file", file));
      await uploadMomentPhotos({
        momentId: momentId as string,
        imageFiles: upload,
      }).unwrap();
    };

    try {
      // updateMoment checks the photos ALREADY stored when the caption is
      // cleared, so new photos go up first in that case.
      const clearingCaption = changes.description !== undefined && changes.description === "";
      if (clearingCaption) await uploadPhotos();
      if (Object.keys(changes).length > 0) {
        await updateMoment({ id: momentId, momentData: changes }).unwrap();
      }
      if (!clearingCaption) await uploadPhotos();

      toast.success(t("editMoment.toast.updateSuccess"), TOAST);
      navigate("/my-moments");
    } catch (error) {
      toast.error(t("editMoment.toast.updateError"), TOAST);
    }
  };

  if (isLoadingDetails) {
    return (
      <div className={`${PAGE} flex items-center justify-center`}>
        <Loader2
          data-testid="edit-moment-loading"
          className="h-8 w-8 animate-spin text-brand"
          aria-hidden
        />
      </div>
    );
  }

  const tile =
    "group relative aspect-square overflow-hidden rounded-chip bg-ink-100 dark:bg-ink-800";

  return (
    <div className={PAGE}>
      <div className={COLUMN}>
        <div className="flex items-center gap-2 pb-4">
          <button
            type="button"
            data-testid="edit-moment-back"
            onClick={() => navigate(-1)}
            aria-label={t("editMoment.form.cancelButton") || "Cancel"}
            className="rounded-chip p-2 text-ink-600 transition-colors hover:bg-ink-100 dark:text-ink-300 dark:hover:bg-ink-800"
          >
            <ArrowLeft className="h-5 w-5" aria-hidden />
          </button>
          <h1 className="font-display text-xl text-ink-900 dark:text-ink-50">
            {t("editMoment.title") || "Edit moment"}
          </h1>
        </div>

        <form onSubmit={handleSubmit} data-testid="edit-moment-form" className="space-y-4">
          <SurfaceCard padding="lg">
            <div className="space-y-4">
              {/* The app has no title (moments#6). A legacy moment that has
                  one keeps an editable field so its owner can change or clear
                  it; nothing new gets a title from the web. */}
              {original.title.trim() !== "" && (
                <div>
                  <label className={LABEL} htmlFor="moment-title">
                    {t("editMoment.form.titleLabel") || "Title"}
                  </label>
                  <input
                    id="moment-title"
                    data-testid="edit-moment-title"
                    type="text"
                    value={draft.title}
                    maxLength={100}
                    onChange={(event) => set("title", event.target.value)}
                    placeholder={t("editMoment.form.titlePlaceholder") || ""}
                    className={FIELD}
                  />
                </div>
              )}

              <div>
                <label className={LABEL} htmlFor="moment-description">
                  {t("editMoment.form.descriptionLabel") || "Description"}
                </label>
                <textarea
                  id="moment-description"
                  data-testid="edit-moment-description"
                  rows={5}
                  value={draft.description}
                  maxLength={2000}
                  onChange={(event) => set("description", event.target.value)}
                  placeholder={t("editMoment.form.descriptionPlaceholder") || ""}
                  className={`${FIELD} resize-none`}
                  required={!hasMedia}
                />
              </div>
            </div>
          </SurfaceCard>

          <SurfaceCard padding="lg">
            <div className="space-y-4">
              <div>
                <span className={LABEL}>{t("moments_section.filters.mood") || "Mood"}</span>
                <MoodField value={draft.mood} onChange={(value) => set("mood", value)} allowNone plain />
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <CategoryField value={draft.category} onChange={(value) => set("category", value)} />
                <LanguageField value={draft.language} onChange={(value) => set("language", value)} />
              </div>
              <div>
                <span className={LABEL}>{t("moments_section.fields.tags") || "Tags"}</span>
                <TagsField value={draft.tags} onChange={(value) => set("tags", value)} />
              </div>
              <div>
                <span className={LABEL}>{t("moments_section.fields.privacy") || "Who can see it"}</span>
                <PrivacyField value={draft.privacy} onChange={(value) => set("privacy", value)} />
              </div>
              {isTextMoment && (
                <div>
                  <span className={LABEL}>{t("moments_section.fields.background") || "Background"}</span>
                  <BackgroundField value={draft.backgroundColor} onChange={(value) => set("backgroundColor", value)} />
                </div>
              )}
              <div>
                <span className={LABEL}>{t("moments_section.fields.location") || "Location"}</span>
                {draft.location ? (
                  <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-3 py-1 text-sm text-green-800">
                    <MapPin className="h-3 w-3" aria-hidden />
                    {draft.location.formattedAddress}
                    <button
                      type="button"
                      onClick={() => setLocation(null)}
                      aria-label={t("moments_section.fields.removeLocation") || "Remove location"}
                      className="ml-1 hover:text-green-900"
                    >
                      <X className="h-3 w-3" aria-hidden />
                    </button>
                  </span>
                ) : (
                  <button
                    type="button"
                    onClick={addLocation}
                    className="inline-flex items-center gap-1 rounded-chip border border-line px-3 py-1.5 text-sm text-ink-700 hover:bg-ink-100 dark:border-line-dark dark:text-ink-200"
                  >
                    <MapPin className="h-4 w-4" aria-hidden />
                    {t("moments_section.fields.addLocation") || "Add my location"}
                  </button>
                )}
              </div>
              {canSchedule && <ScheduleField value={scheduleInput} onChange={(value) => { setNotice(""); setScheduleInput(value); }} />}
            </div>
          </SurfaceCard>

{hasAvMedia ? (
          <SurfaceCard padding="lg">
            <MediaEditor moment={moment} />
          </SurfaceCard>
          ) : (
          <SurfaceCard padding="lg">
            <h2 className={LABEL}>{t("editMoment.form.imagesLabel") || "Images"}</h2>
            <p className="pb-3 text-xs text-ink-400 dark:text-ink-500">
              {t("editMoment.form.maxImagesText") || ""}
            </p>

            {existingImages.length > 0 && (
              <React.Fragment>
                <h3 className="pb-2 text-xs font-semibold text-ink-600 dark:text-ink-300">
                  {t("editMoment.form.existingImagesLabel") || "Current images"}
                </h3>
                <ul className="grid grid-cols-3 gap-2 pb-4 sm:grid-cols-4">
                  {existingImages.map((url, index) => (
                    <li key={`existing-${index}-${url}`} data-testid="existing-image" className={tile}>
                      {/* No remove: the server keeps stored photos on update. */}
                      <img src={url} alt="" className="h-full w-full object-cover" />
                    </li>
                  ))}
                </ul>
              </React.Fragment>
            )}

            {imagePreviews.length > 0 && (
              <React.Fragment>
                <h3 className="pb-2 text-xs font-semibold text-ink-600 dark:text-ink-300">
                  {t("editMoment.form.newImagesLabel") || "New images"}
                </h3>
                <ul className="grid grid-cols-3 gap-2 pb-4 sm:grid-cols-4">
                  {imagePreviews.map((preview, index) => (
                    <li key={`new-${index}`} data-testid="new-image" className={tile}>
                      <img src={preview} alt="" className="h-full w-full object-cover" />
                      <button
                        type="button"
                        data-testid={`remove-new-${index}`}
                        onClick={() => handleRemoveImage(index)}
                        aria-label={t("editMoment.form.removeImage") || "Remove image"}
                        className={REMOVE}
                      >
                        <X className="h-4 w-4" aria-hidden />
                      </button>
                    </li>
                  ))}
                </ul>
              </React.Fragment>
            )}

            {total < MAX_IMAGES && (
              <button
                type="button"
                data-testid="edit-moment-add-images"
                onClick={handleAddMoreImages}
                className="flex w-full items-center justify-center gap-2 rounded-chip border-2 border-dashed border-line-strong px-4 py-4 text-sm font-semibold text-ink-400 transition-colors hover:border-brand hover:text-brand dark:border-line-dark"
              >
                <Plus className="h-5 w-5" aria-hidden />
                {t("editMoment.form.addMoreText") || "Add more"}
              </button>
            )}

            <input
              ref={fileInputRef}
              type="file"
              multiple
              accept="image/*"
              onChange={handleImageUpload}
              data-testid="edit-moment-file-input"
              className="hidden"
            />
          </SurfaceCard>
          )}

          <div className="flex items-center justify-end gap-2">
            {notice && (
              <p role="status" className="mr-auto text-sm text-ink-500 dark:text-ink-400">
                {notice}
              </p>
            )}
            <button
              type="button"
              data-testid="edit-moment-cancel"
              onClick={() => navigate(-1)}
              className="rounded-chip border border-line px-4 py-2 text-sm font-semibold text-ink-700 transition-colors hover:bg-ink-100 dark:border-line-dark dark:text-ink-200 dark:hover:bg-ink-800"
            >
              {t("editMoment.form.cancelButton") || "Cancel"}
            </button>
            <button
              type="submit"
              data-testid="edit-moment-save"
              disabled={!canSubmit}
              className="inline-flex items-center gap-1.5 rounded-chip bg-brand-deep px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-50"
            >
              {isUpdating || isUploading ? (
                <Loader2 className="h-4 w-4 animate-spin" aria-hidden />
              ) : null}
              {isUpdating || isUploading
                ? t("editMoment.form.updatingButton") || "Updating"
                : t("editMoment.form.updateButton") || "Update moment"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditMyMoment;
