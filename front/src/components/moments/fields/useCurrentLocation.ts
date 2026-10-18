import { useCallback } from "react";
import { toast } from "react-toastify";

export interface MomentLocation {
  formattedAddress: string;
  type: "Point";
  coordinates: [number, number];
}

/** Reads the browser's position and names it "City, Country" (OpenStreetMap). */
export function useCurrentLocation(onLocated: (location: MomentLocation) => void) {
  return useCallback(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const lat = position.coords.latitude;
        const lng = position.coords.longitude;
        try {
          const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`);
          const data = await res.json();
          const address = data.address;
          const city = address.city || address.town || address.village || "";
          const country = address.country || "";
          onLocated({ formattedAddress: `${city}, ${country}`, type: "Point", coordinates: [lng, lat] });
          toast.success("Location added!", { autoClose: 2000 });
        } catch (err) {
          toast.error("Could not fetch address", { autoClose: 2000 });
        }
      },
      () => toast.error("Could not get location", { autoClose: 2000 })
    );
  }, [onLocated]);
}
