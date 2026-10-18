import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { MapPin } from "lucide-react";
import ConfirmDialog from "../../../design/ConfirmDialog";
import notify from "../../../design/notify";
import { useSendLocationMessageMutation } from "../../../store/slices/chatSlice";
import { useLazyReverseGeocodeQuery } from "../../../store/slices/usersSlice";

interface PendingLocation {
  latitude: number;
  longitude: number;
  placeName?: string;
  address?: string;
}

interface LocationShareButtonProps {
  receiverId: string;
  disabled?: boolean;
}

/** Six decimals (~10 cm) is everything a phone fix carries; more is noise. */
const round = (value: number): number => Math.round(value * 1e6) / 1e6;

/**
 * Share the current location in the chat, the way the app's location option
 * does: the browser's fix, an optional place name from our own reverse
 * geocoder, then a confirmation that shows what will be sent. Nothing goes
 * out without the explicit Send.
 */
const LocationShareButton: React.FC<LocationShareButtonProps> = ({ receiverId, disabled }) => {
  const { t } = useTranslation();
  const [sendLocation, { isLoading }] = useSendLocationMessageMutation();
  const [reverseGeocode] = useLazyReverseGeocodeQuery();
  const [locating, setLocating] = useState(false);
  const [pending, setPending] = useState<PendingLocation | null>(null);
  const [error, setError] = useState("");

  const locate = (): void => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      notify.error(t("chatPage.location.unsupported") || "This browser can't share a location");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const next: PendingLocation = {
          latitude: round(pos.coords.latitude),
          longitude: round(pos.coords.longitude),
        };
        try {
          const res: any = await reverseGeocode({ lat: next.latitude, lng: next.longitude }).unwrap();
          const place = res && res.data;
          if (place) {
            const name = [place.city, place.country].filter(Boolean).join(", ");
            if (name) next.placeName = name;
            if (place.formattedAddress) next.address = place.formattedAddress;
          }
        } catch (lookupError) {
          // The pin alone is a complete location message.
        }
        setLocating(false);
        setPending(next);
      },
      (positionError) => {
        setLocating(false);
        notify.error(
          positionError && positionError.code === 1
            ? t("chatPage.location.denied") || "Location permission was denied"
            : t("chatPage.location.failed") || "Couldn't get your location"
        );
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
    );
  };

  const confirm = async (): Promise<void> => {
    if (!pending) return;
    setError("");
    try {
      await sendLocation({ receiver: receiverId, ...pending }).unwrap();
      setPending(null);
    } catch (sendError) {
      const data: any = sendError && (sendError as any).data;
      setError(
        (data && (data.error || data.message)) ||
          t("chatPage.location.sendFailed") ||
          "Couldn't send your location"
      );
    }
  };

  const label = t("chatPage.location.share") || "Share location";
  return (
    <React.Fragment>
      <button
        type="button"
        className="attachment-btn"
        data-testid="share-location"
        title={label}
        aria-label={label}
        onClick={locate}
        disabled={disabled || locating || isLoading}
      >
        {locating ? <span className="spinner spinner--sm" /> : <MapPin size={20} />}
      </button>
      <ConfirmDialog
        open={!!pending}
        title={t("chatPage.location.confirmTitle") || "Share your location?"}
        body={
          pending
            ? pending.placeName || pending.address || `${pending.latitude}, ${pending.longitude}`
            : undefined
        }
        confirmLabel={t("chatPage.location.send") || "Send"}
        cancelLabel={t("chatPage.location.cancel") || "Cancel"}
        busy={isLoading}
        error={error || undefined}
        onConfirm={confirm}
        onCancel={() => {
          setPending(null);
          setError("");
        }}
      />
    </React.Fragment>
  );
};

export default LocationShareButton;
