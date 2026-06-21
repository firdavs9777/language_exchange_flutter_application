import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { X, Search } from "lucide-react";
import "./GifPickerPanel.scss";

// GIPHY public-beta key. Works without registration but is rate-limited; for
// production set REACT_APP_GIPHY_API_KEY to your own key.
const FALLBACK_KEY = "dc6zaTOxFJmzC";
const API_KEY = process.env.REACT_APP_GIPHY_API_KEY || FALLBACK_KEY;
const API_BASE = "https://api.giphy.com/v1/gifs";

interface GiphyImage {
  url: string;
  width: string;
  height: string;
}

interface GiphyGif {
  id: string;
  title: string;
  images: {
    fixed_width: GiphyImage;
    original: GiphyImage;
    fixed_width_small?: GiphyImage;
  };
}

interface GifPickerPanelProps {
  onSelectGif: (gifUrl: string) => void;
  onClose: () => void;
}

const GifPickerPanel: React.FC<GifPickerPanelProps> = ({
  onSelectGif,
  onClose,
}) => {
  const { t } = useTranslation();
  const [query, setQuery] = useState("");
  const [gifs, setGifs] = useState<GiphyGif[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const fetchGifs = useCallback(async (q: string, signal: AbortSignal) => {
    setIsLoading(true);
    setError(null);
    try {
      const endpoint = q.trim() ? "search" : "trending";
      const url = new URL(`${API_BASE}/${endpoint}`);
      url.searchParams.set("api_key", API_KEY);
      url.searchParams.set("limit", "24");
      url.searchParams.set("rating", "g");
      if (q.trim()) url.searchParams.set("q", q.trim());

      const res = await fetch(url.toString(), { signal });
      if (!res.ok) throw new Error(`GIPHY ${res.status}`);
      const json = await res.json();
      setGifs((json.data || []) as GiphyGif[]);
    } catch (e: any) {
      if (e.name === "AbortError") return;
      setError(e?.message || "Failed to load GIFs");
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Initial trending load + debounced search
  useEffect(() => {
    const controller = new AbortController();
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      fetchGifs(query, controller.signal);
    }, query ? 300 : 0);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
      controller.abort();
    };
  }, [query, fetchGifs]);

  // Esc to close
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const handleSelect = (gif: GiphyGif) => {
    const url = gif.images.original?.url || gif.images.fixed_width?.url;
    if (url) onSelectGif(url);
  };

  return (
    <div className="gif-picker">
      <div className="gif-picker__header">
        <span className="gif-picker__title">
          {t("chatPage.gif.title") || "GIFs"}
        </span>
        <button
          type="button"
          className="gif-picker__close"
          onClick={onClose}
          aria-label={t("chatPage.gif.close") || "Close GIF picker"}
        >
          <X size={16} />
        </button>
      </div>

      <div className="gif-picker__search">
        <Search size={14} className="gif-picker__search-icon" />
        <input
          type="text"
          placeholder={t("chatPage.gif.searchPlaceholder") || "Search GIFs..."}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          autoFocus
        />
      </div>

      <div className="gif-picker__body">
        {isLoading && gifs.length === 0 && (
          <div className="gif-picker__state">
            {t("chatPage.gif.loading") || "Loading GIFs..."}
          </div>
        )}
        {error && (
          <div className="gif-picker__state gif-picker__state--error">
            {error}
          </div>
        )}
        {!isLoading && !error && gifs.length === 0 && (
          <div className="gif-picker__state">
            {t("chatPage.gif.noResults") || "No GIFs found"}
          </div>
        )}

        <div className="gif-picker__grid">
          {gifs.map((gif) => (
            <button
              key={gif.id}
              type="button"
              className="gif-picker__tile"
              onClick={() => handleSelect(gif)}
              title={gif.title}
              aria-label={gif.title || "GIF"}
            >
              <img
                src={gif.images.fixed_width.url}
                alt={gif.title || "GIF"}
                loading="lazy"
              />
            </button>
          ))}
        </div>
      </div>

      <div className="gif-picker__footer">
        {t("chatPage.gif.poweredBy") || "Powered by GIPHY"}
      </div>
    </div>
  );
};

export default GifPickerPanel;
