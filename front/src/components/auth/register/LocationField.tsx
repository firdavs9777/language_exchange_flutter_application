import React, { useState } from 'react';
import { MapPin, Loader2 } from 'lucide-react';
import { useLazyReverseGeocodeQuery, useLazyForwardGeocodeQuery } from '../../../store/slices/usersSlice';
import { LocationInput } from './buildRegisterPayload';
import { normalizeLocationResult } from './resolveLocation';

interface Props {
  value: LocationInput | null;
  onChange: (v: LocationInput | null) => void;
}

const LocationField: React.FC<Props> = ({ value, onChange }) => {
  const [busy, setBusy] = useState(false);
  const [reverse] = useLazyReverseGeocodeQuery();
  const [forward] = useLazyForwardGeocodeQuery();
  const [city, setCity] = useState(value?.city || '');
  const [country, setCountry] = useState(value?.country || '');

  const detect = () => {
    if (!navigator.geolocation) return;
    setBusy(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const res: any = await reverse({ lat: pos.coords.latitude, lng: pos.coords.longitude });
          const norm = normalizeLocationResult(res?.data?.data);
          if (norm) {
            setCity(norm.city);
            setCountry(norm.country);
            onChange(norm);
          }
        } finally {
          setBusy(false);
        }
      },
      () => setBusy(false),
      { timeout: 10000 }
    );
  };

  const manualBlur = async () => {
    if (!city || !country) {
      onChange(city || country ? { city, country } : null);
      return;
    }
    try {
      const res: any = await forward({ city, country });
      onChange(normalizeLocationResult(res?.data?.data) || { city, country });
    } catch {
      onChange({ city, country });
    }
  };

  return (
    <div className="space-y-3">
      <button
        type="button"
        onClick={detect}
        disabled={busy}
        className="w-full flex items-center justify-center gap-2 py-3 rounded-xl font-medium bg-teal-50 text-teal-600 hover:bg-teal-100 transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
      >
        {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <MapPin className="w-4 h-4" />}
        {busy ? 'Detecting…' : 'Use my location'}
      </button>

      <div className="grid grid-cols-2 gap-3">
        <input
          type="text"
          aria-label="country"
          placeholder="Country"
          value={country}
          onChange={(e) => setCountry(e.target.value)}
          onBlur={manualBlur}
          className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent transition-all"
        />
        <input
          type="text"
          aria-label="city"
          placeholder="City"
          value={city}
          onChange={(e) => setCity(e.target.value)}
          onBlur={manualBlur}
          className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent transition-all"
        />
      </div>
    </div>
  );
};

export default LocationField;
