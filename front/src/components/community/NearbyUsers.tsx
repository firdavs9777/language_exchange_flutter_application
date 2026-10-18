import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetNearbyUsersQuery } from "../../store/slices/communitySlice";
import { userAvatarUrl } from "../../utils/photoUrl";
import {
  ArrowLeft,
  MapPin,
  Loader2,
  Filter,
  Users,
  Navigation,
  AlertCircle,
  Lock,
} from "lucide-react";
import { VIP_PATH } from "../vip/vipStatus";

/**
 * One row of GET /api/v1/community/nearby (controllers/community.js
 * getNearbyUsers). The server projects raw `images` (storage paths, no
 * `imageUrls`), snake_case language fields and the six public privacy
 * toggles, and has already redacted what those toggles hide. They are
 * honoured here as well, as the app's nearby_tab.dart does, so a cached or
 * older payload never shows what the person chose to hide.
 */
export interface NearbyUser {
  _id: string;
  name: string;
  images?: string[];
  imageUrls?: string[];
  bio?: string;
  distance?: number;
  native_language?: string;
  language_to_learn?: string;
  isOnline?: boolean;
  location?: { city?: string; country?: string };
  privacySettings?: {
    showCity?: boolean;
    showCountryRegion?: boolean;
    showOnlineStatus?: boolean;
  };
}

/** Online dot only when the person is online AND shows it (nearby_tab.dart:784). */
export function nearbyIsOnline(user: NearbyUser): boolean {
  const ps = user.privacySettings || {};
  return Boolean(user.isOnline) && ps.showOnlineStatus !== false;
}

/** "City, Country" with each part dropped when hidden (nearby_tab.dart:998). */
export function nearbyPlace(user: NearbyUser): string {
  const ps = user.privacySettings || {};
  const loc = user.location || {};
  const city = ps.showCity === false ? "" : loc.city || "";
  const country = ps.showCountryRegion === false ? "" : loc.country || "";
  return [city, country].filter((part) => typeof part === "string" && part.trim()).join(", ");
}

/** The app's _formatDistance: metres under 1 km, one decimal under 10 km, whole km above. */
export function formatNearbyDistance(km?: number): string {
  if (typeof km !== "number" || !isFinite(km)) return "";
  if (km < 1) return `${Math.round(km * 1000)}m`;
  if (km < 10) return `${km.toFixed(1)}km`;
  return `${Math.round(km)}km`;
}

export const RADIUS_OPTIONS = [5, 10, 25, 50, 100, 200];

/**
 * Free accounts are capped at 50 km server-side (VIP 500); the response says
 * so in `search.maxRadiusKm`. Until it answers, assume the free cap.
 */
export const DEFAULT_MAX_RADIUS_KM = 50;

/** A radius above the account's cap is a VIP upsell, not a search. */
export function isRadiusLocked(radiusKm: number, maxRadiusKm?: number): boolean {
  return radiusKm > (maxRadiusKm || DEFAULT_MAX_RADIUS_KM);
}

const NearbyUsers: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [radius, setRadius] = useState(10);
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [isRequestingLocation, setIsRequestingLocation] = useState(false);

  const { data, isLoading, refetch } = useGetNearbyUsersQuery(
    {
      latitude: location ? location.lat : 0,
      longitude: location ? location.lng : 0,
      radius,
    },
    // Re-read on tab return so the list (and the VIP cap) is not stale.
    { skip: !location, refetchOnFocus: true }
  );

  const nearbyUsers: NearbyUser[] = (data && Array.isArray(data.data) && data.data) || [];
  const maxRadiusKm: number | undefined =
    data && data.search && typeof data.search.maxRadiusKm === "number"
      ? data.search.maxRadiusKm
      : undefined;
  const capKm = maxRadiusKm || DEFAULT_MAX_RADIUS_KM;
  const anyLocked = RADIUS_OPTIONS.some((r) => isRadiusLocked(r, maxRadiusKm));

  const handleRadiusClick = (r: number) => {
    if (isRadiusLocked(r, maxRadiusKm)) {
      navigate(VIP_PATH);
      return;
    }
    setRadius(r);
  };

  const requestLocation = () => {
    setIsRequestingLocation(true);
    setLocationError(null);

    if (!navigator.geolocation) {
      setLocationError(
        t("communityNearby.geolocationNotSupported") || "Geolocation is not supported"
      );
      setIsRequestingLocation(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({ lat: position.coords.latitude, lng: position.coords.longitude });
        setIsRequestingLocation(false);
      },
      (error) => {
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setLocationError(t("communityNearby.permissionDenied") || "Location permission denied");
            break;
          case error.POSITION_UNAVAILABLE:
            setLocationError(t("communityNearby.positionUnavailable") || "Location unavailable");
            break;
          case error.TIMEOUT:
            setLocationError(t("communityNearby.timeout") || "Location request timed out");
            break;
          default:
            setLocationError(t("communityNearby.unknownError") || "An error occurred");
        }
        setIsRequestingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  };

  useEffect(() => {
    requestLocation();
    // Once on mount; the Try again button asks again.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const header = (
    <div className="flex items-center gap-4">
      <button
        type="button"
        onClick={() => navigate(-1)}
        aria-label={t("communityNearby.back") || "Back"}
        className="p-2 hover:bg-white/10 rounded-lg transition-colors"
      >
        <ArrowLeft className="w-6 h-6 rtl:rotate-180" />
      </button>
      <div>
        <h1 className="text-xl font-bold">{t("communityNearby.title") || "Nearby Users"}</h1>
        <p className="text-teal-100 text-sm">
          {t("communityNearby.subtitle") || "Find people around you"}
        </p>
      </div>
    </div>
  );

  if (isRequestingLocation) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50 flex flex-col items-center justify-center p-6">
        <Loader2 className="w-12 h-12 text-teal-500 animate-spin mb-4" />
        <p className="text-gray-600">
          {t("communityNearby.gettingLocation") || "Getting your location..."}
        </p>
      </div>
    );
  }

  if (locationError) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
        <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6">{header}</div>
        <div className="flex flex-col items-center justify-center p-8 mt-20">
          <div className="p-6 rounded-full bg-red-100 mb-6">
            <AlertCircle className="w-12 h-12 text-red-500" />
          </div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            {t("communityNearby.locationRequired") || "Location Required"}
          </h2>
          <p className="text-gray-500 text-center mb-6 max-w-md">{locationError}</p>
          <button
            type="button"
            onClick={requestLocation}
            className="px-6 py-3 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
          >
            {t("communityNearby.tryAgain") || "Try Again"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
      <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6 pb-8">
        <div className="mb-4">{header}</div>

        <div className="bg-white/20 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Filter className="w-5 h-5" />
            <span className="font-medium">
              {t("communityNearby.searchRadius") || "Search Radius"}
            </span>
          </div>
          <div className="flex flex-wrap gap-2">
            {RADIUS_OPTIONS.map((r) => {
              const locked = isRadiusLocked(r, maxRadiusKm);
              return (
                <button
                  key={r}
                  type="button"
                  data-testid={`nearby-radius-${r}`}
                  onClick={() => handleRadiusClick(r)}
                  aria-pressed={radius === r}
                  aria-label={locked ? `${r}km VIP` : undefined}
                  className={`flex-1 min-w-[56px] py-2 rounded-lg font-medium transition-colors inline-flex items-center justify-center gap-1 ${
                    radius === r
                      ? "bg-white text-teal-600"
                      : locked
                      ? "bg-white/10 text-white/70 hover:bg-white/20"
                      : "bg-white/20 text-white hover:bg-white/30"
                  }`}
                >
                  {locked && <Lock data-testid="nearby-radius-lock" className="w-3.5 h-3.5" aria-hidden />}
                  {r}km
                </button>
              );
            })}
          </div>
          {anyLocked && (
            <p className="text-xs text-white/80 mt-2">
              {t("communityNearby.radiusLimit", { km: capKm }) ||
                `Free accounts search up to ${capKm} km. Upgrade to VIP to search further.`}
            </p>
          )}
        </div>
      </div>

      <div className="px-4 py-6 max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2 text-gray-600">
            <Users className="w-5 h-5" />
            <span data-testid="nearby-count">
              {t("communityNearby.usersFound", { count: nearbyUsers.length }) ||
                `${nearbyUsers.length} users found`}
            </span>
          </div>
          <button
            type="button"
            onClick={() => refetch()}
            className="flex items-center gap-2 text-teal-600 font-medium"
          >
            <Navigation className="w-4 h-4" />
            {t("communityNearby.refresh") || "Refresh"}
          </button>
        </div>

        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-10 h-10 text-teal-500 animate-spin" />
          </div>
        ) : nearbyUsers.length === 0 ? (
          <div className="text-center py-12">
            <div className="p-4 rounded-full bg-gray-100 w-fit mx-auto mb-4">
              <MapPin className="w-8 h-8 text-gray-400" />
            </div>
            <p className="text-gray-500">{t("communityNearby.noUsers") || "No users found nearby"}</p>
            <p className="text-gray-400 text-sm mt-2">
              {t("communityNearby.tryIncreaseRadius") || "Try increasing the search radius"}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {nearbyUsers.map((user) => {
              const avatar = userAvatarUrl(user);
              const place = nearbyPlace(user);
              return (
                <button
                  key={user._id}
                  type="button"
                  data-testid="nearby-user"
                  onClick={() => navigate(`/community/${user._id}`)}
                  className="w-full flex items-center gap-4 p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 hover:shadow-lg transition-all"
                >
                  <div className="relative">
                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                      {avatar ? (
                        <img src={avatar} alt={user.name} className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-white text-xl font-bold">
                          {user.name ? user.name[0] : "?"}
                        </div>
                      )}
                    </div>
                    {nearbyIsOnline(user) && (
                      <div
                        data-testid="nearby-online-dot"
                        className="absolute bottom-0 end-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full"
                      />
                    )}
                  </div>

                  <div className="flex-1 min-w-0 text-start">
                    <h3 className="font-semibold text-gray-800">{user.name}</h3>
                    {place && (
                      <p data-testid="nearby-place" className="text-xs text-gray-500">
                        {place}
                      </p>
                    )}
                    {user.bio && <p className="text-sm text-gray-500 line-clamp-1">{user.bio}</p>}
                    <div className="flex flex-wrap items-center gap-2 mt-1">
                      {user.native_language && (
                        <span
                          data-testid="nearby-native"
                          className="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full"
                        >
                          {user.native_language}
                        </span>
                      )}
                      {user.language_to_learn && (
                        <span
                          data-testid="nearby-learning"
                          className="text-xs bg-green-100 text-green-600 px-2 py-0.5 rounded-full"
                        >
                          {t("communityNearby.learning", { language: user.language_to_learn }) ||
                            `Learning: ${user.language_to_learn}`}
                        </span>
                      )}
                    </div>
                  </div>

                  {formatNearbyDistance(user.distance) && (
                    <div className="flex items-center gap-1 text-teal-600 font-medium">
                      <MapPin className="w-4 h-4" />
                      {formatNearbyDistance(user.distance)}
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default NearbyUsers;
