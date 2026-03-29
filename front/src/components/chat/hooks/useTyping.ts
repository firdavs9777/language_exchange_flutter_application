import { useState, useRef, useCallback } from 'react';

export const useTyping = (
  onTypingChange: (isTyping: boolean) => void,
  debounceMs: number = 1000
) => {
  const [isTyping, setIsTyping] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout>();

  const startTyping = useCallback(() => {
    if (!isTyping) {
      setIsTyping(true);
      onTypingChange(true);
    }

    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    // Set new timeout
    timeoutRef.current = setTimeout(() => {
      setIsTyping(false);
      onTypingChange(false);
    }, debounceMs);
  }, [isTyping, onTypingChange, debounceMs]);

  const stopTyping = useCallback(() => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }
    setIsTyping(false);
    onTypingChange(false);
  }, [onTypingChange]);

  return { isTyping, startTyping, stopTyping };
};

export default useTyping;
