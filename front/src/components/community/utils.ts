
import { useEffect, useState } from 'react';
import { languageFlag } from '../../utils/languages';

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
export const getLanguageFlag = (language: string): string => languageFlag(language);

