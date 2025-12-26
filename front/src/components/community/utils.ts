
import { useEffect, useState } from 'react';
import {LANGUAGE_CODES} from './type'

export const getLanguageCode = (language: string): string => {
  if (!language?.trim()) return "";
  return LANGUAGE_CODES[language] || language.slice(0, 2).toLowerCase();
};

export const generateRandomStats = () => ({
  rating: (Math.random() * 2 + 3).toFixed(1),
  sessions: Math.floor(Math.random() * 100) + 1
});
export const useDebounce = <T,>(value: T, delay: number): T => {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);

  return debouncedValue;
};
export const getLanguageFlag = (language: string): string => {
  const flagMap: Record<string, string> = {
    English: "🇺🇸",
    Spanish: "🇪🇸",
    French: "🇫🇷",
    German: "🇩🇪",
    Italian: "🇮🇹",
    Portuguese: "🇵🇹",
    Russian: "🇷🇺",
    Japanese: "🇯🇵",
    Korean: "🇰🇷",
    Chinese: "🇨🇳",
  };
  return flagMap[language] || "🌐";
};

