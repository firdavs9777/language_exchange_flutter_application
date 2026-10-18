import React from "react";
import { useTranslation } from "react-i18next";
import { MapPin } from "lucide-react";

export interface MessageLocation {
  latitude?: number | null;
  longitude?: number | null;
  address?: string | null;
  placeName?: string | null;
}

/** The URL the app opens for a location message (widgets/media_message_widget.dart). */
export function mapsUrl(latitude: number, longitude: number): string {
  return `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;
}

function hasCoordinates(location: MessageLocation | null | undefined): boolean {
  if (!location) return false;
  const lat = Number(location.latitude);
  const lng = Number(location.longitude);
  return location.latitude !== null && location.longitude !== null && isFinite(lat) && isFinite(lng);
}

/**
 * A location message (media.type 'location'): a pin, the place name (or the
 * address, or "Location"), the address under a place name, and a link that
 * opens the pin in Maps. Nothing is fetched to draw it.
 */
const LocationMessageCard: React.FC<{ location?: MessageLocation | null }> = ({ location }) => {
  const { t } = useTranslation();
  const generic = t("chatPage.location.title") || "Location";
  const title = (location && (location.placeName || location.address)) || generic;
  const subtitle = location && location.placeName && location.address ? location.address : null;
  const body = (
    <React.Fragment>
      <MapPin size={20} className="location-card-pin" aria-hidden="true" />
      <span className="location-card-text">
        <span className="location-card-title">{title}</span>
        {subtitle ? <span className="location-card-sub">{subtitle}</span> : null}
        <span className="location-card-open">{t("chatPage.location.open") || "Open in Maps"}</span>
      </span>
    </React.Fragment>
  );

  if (!hasCoordinates(location)) {
    return (
      <div className="location-card location-card--empty" data-testid="location-card">
        {body}
      </div>
    );
  }
  const loc = location as MessageLocation;
  return (
    <a
      className="location-card"
      data-testid="location-card"
      href={mapsUrl(Number(loc.latitude), Number(loc.longitude))}
      target="_blank"
      rel="noopener noreferrer"
      onClick={(e) => e.stopPropagation()}
    >
      {body}
    </a>
  );
};

export default LocationMessageCard;
