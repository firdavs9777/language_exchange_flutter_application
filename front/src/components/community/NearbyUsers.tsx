import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useGetNearbyUsersQuery } from "../../store/slices/communitySlice";
import {
  ArrowLeft,
  MapPin,
  Loader2,
  Filter,
  Users,
  Navigation,
  AlertCircle,
} from "lucide-react";

interface NearbyUser {
  _id: string;
  name: string;
  imageUrls?: string[];
  bio?: string;
  distance: number;
  nativeLanguage?: string;
  learningLanguage?: string;
  isOnline?: boolean;
}

const NearbyUsers: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [radius, setRadius] = useState(10);
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const [isRequestingLocation, setIsRequestingLocation] = useState(false);

  const { data, isLoading, refetch } = useGetNearbyUsersQuery(
    { lat: location?.lat || 0, lng: location?.lng || 0, radius },
    { skip: !location }
  );

  const nearbyUsers: NearbyUser[] = data?.data || [];

  useEffect(() => {
    requestLocation();
  }, []);

  const requestLocation = () => {
    setIsRequestingLocation(true);
    setLocationError(null);

    if (!navigator.geolocation) {
      setLocationError(t("community.nearby.geolocationNotSupported") || "Geolocation is not supported");
      setIsRequestingLocation(false);
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
        setIsRequestingLocation(false);
      },
      (error) => {
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setLocationError(t("community.nearby.permissionDenied") || "Location permission denied");
            break;
          case error.POSITION_UNAVAILABLE:
            setLocationError(t("community.nearby.positionUnavailable") || "Location unavailable");
            break;
          case error.TIMEOUT:
            setLocationError(t("community.nearby.timeout") || "Location request timed out");
            break;
          default:
            setLocationError(t("community.nearby.unknownError") || "An error occurred");
        }
        setIsRequestingLocation(false);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  };

  const formatDistance = (km: number) => {
    if (km < 1) {
      return `${Math.round(km * 1000)}m`;
    }
    return `${km.toFixed(1)}km`;
  };

  const radiusOptions = [5, 10, 25, 50, 100];

  if (isRequestingLocation) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50 flex flex-col items-center justify-center p-6">
        <Loader2 className="w-12 h-12 text-teal-500 animate-spin mb-4" />
        <p className="text-gray-600">{t("community.nearby.gettingLocation") || "Getting your location..."}</p>
      </div>
    );
  }

  if (locationError) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
        <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-6 h-6" />
            </button>
            <div>
              <h1 className="text-xl font-bold">
                {t("community.nearby.title") || "Nearby Users"}
              </h1>
              <p className="text-teal-100 text-sm">
                {t("community.nearby.subtitle") || "Find people around you"}
              </p>
            </div>
          </div>
        </div>

        <div className="flex flex-col items-center justify-center p-8 mt-20">
          <div className="p-6 rounded-full bg-red-100 mb-6">
            <AlertCircle className="w-12 h-12 text-red-500" />
          </div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">
            {t("community.nearby.locationRequired") || "Location Required"}
          </h2>
          <p className="text-gray-500 text-center mb-6 max-w-md">{locationError}</p>
          <button
            onClick={requestLocation}
            className="px-6 py-3 bg-gradient-to-r from-teal-500 to-blue-500 text-white rounded-xl font-semibold hover:shadow-lg transition-all"
          >
            {t("community.nearby.tryAgain") || "Try Again"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-teal-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-teal-500 to-blue-500 text-white p-6 pb-8">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-xl font-bold">
              {t("community.nearby.title") || "Nearby Users"}
            </h1>
            <p className="text-teal-100 text-sm">
              {t("community.nearby.subtitle") || "Find people around you"}
            </p>
          </div>
        </div>

        {/* Radius Filter */}
        <div className="bg-white/20 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <Filter className="w-5 h-5" />
            <span className="font-medium">{t("community.nearby.searchRadius") || "Search Radius"}</span>
          </div>
          <div className="flex gap-2">
            {radiusOptions.map((r) => (
              <button
                key={r}
                onClick={() => setRadius(r)}
                className={`flex-1 py-2 rounded-lg font-medium transition-colors ${
                  radius === r
                    ? "bg-white text-teal-600"
                    : "bg-white/20 text-white hover:bg-white/30"
                }`}
              >
                {r}km
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 max-w-2xl mx-auto">
        {/* Stats */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-2 text-gray-600">
            <Users className="w-5 h-5" />
            <span>{nearbyUsers.length} {t("community.nearby.usersFound") || "users found"}</span>
          </div>
          <button
            onClick={() => refetch()}
            className="flex items-center gap-2 text-teal-600 font-medium"
          >
            <Navigation className="w-4 h-4" />
            {t("community.nearby.refresh") || "Refresh"}
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
            <p className="text-gray-500">
              {t("community.nearby.noUsers") || "No users found nearby"}
            </p>
            <p className="text-gray-400 text-sm mt-2">
              {t("community.nearby.tryIncreaseRadius") || "Try increasing the search radius"}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {nearbyUsers.map((user) => (
              <button
                key={user._id}
                onClick={() => navigate(`/user/${user._id}`)}
                className="w-full flex items-center gap-4 p-4 bg-white/60 backdrop-blur-sm rounded-xl border border-white/30 hover:bg-white/80 hover:shadow-lg transition-all"
              >
                <div className="relative">
                  <div className="w-14 h-14 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 overflow-hidden">
                    {user.imageUrls?.[0] ? (
                      <img
                        src={user.imageUrls[0]}
                        alt={user.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-white text-xl font-bold">
                        {user.name?.[0]}
                      </div>
                    )}
                  </div>
                  {user.isOnline && (
                    <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-500 border-2 border-white rounded-full" />
                  )}
                </div>

                <div className="flex-1 text-left">
                  <h3 className="font-semibold text-gray-800">{user.name}</h3>
                  {user.bio && (
                    <p className="text-sm text-gray-500 line-clamp-1">{user.bio}</p>
                  )}
                  <div className="flex items-center gap-2 mt-1">
                    {user.nativeLanguage && (
                      <span className="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded-full">
                        {user.nativeLanguage}
                      </span>
                    )}
                    {user.learningLanguage && (
                      <span className="text-xs bg-green-100 text-green-600 px-2 py-0.5 rounded-full">
                        Learning: {user.learningLanguage}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-1 text-teal-600 font-medium">
                  <MapPin className="w-4 h-4" />
                  {formatDistance(user.distance)}
                </div>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default NearbyUsers;
