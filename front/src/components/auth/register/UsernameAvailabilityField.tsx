import React, { useEffect, useRef, useState } from 'react';
import { useLazyCheckUsernameQuery } from '../../../store/slices/usersSlice';
import { usernameFormatValid } from './validators';

interface Props {
  value: string;
  onChange: (v: string) => void;
  onAvailabilityChange: (ok: boolean) => void;
}

type Status = 'idle' | 'checking' | 'available' | 'taken' | 'invalid';

const UsernameAvailabilityField: React.FC<Props> = ({ value, onChange, onAvailabilityChange }) => {
  const [status, setStatus] = useState<Status>('idle');
  // Internal mirror of `value`. Driving the debounce/validation logic off this
  // local echo (kept in sync with the `value` prop, but updated immediately on
  // every keystroke) rather than off the prop directly means the field still
  // behaves correctly even if the parent's `onChange` doesn't synchronously
  // reflect the new value back down as a prop (e.g. async form state).
  const [internal, setInternal] = useState(value);
  const [trigger] = useLazyCheckUsernameQuery();
  const timer = useRef<ReturnType<typeof setTimeout>>();

  useEffect(() => {
    setInternal(value);
  }, [value]);

  useEffect(() => {
    const v = internal.trim().toLowerCase();
    if (timer.current) clearTimeout(timer.current);
    if (v === '') {
      setStatus('idle');
      onAvailabilityChange(true);
      return;
    }
    if (!usernameFormatValid(v)) {
      setStatus('invalid');
      onAvailabilityChange(false);
      return;
    }
    setStatus('checking');
    timer.current = setTimeout(async () => {
      try {
        const res: any = await trigger(v);
        const ok = !!res?.data?.data?.available;
        setStatus(ok ? 'available' : 'taken');
        onAvailabilityChange(ok);
      } catch {
        setStatus('taken');
        onAvailabilityChange(false);
      }
    }, 500);
    return () => {
      if (timer.current) clearTimeout(timer.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [internal]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = e.target.value;
    setInternal(v);
    onChange(v);
  };

  return (
    <div className="w-full">
      <input
        type="text"
        value={internal}
        placeholder="username (optional)"
        onChange={handleChange}
        aria-label="username"
        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400 focus:border-transparent transition-all"
      />
      {status === 'invalid' && (
        <small className="block text-xs text-red-500 mt-1">3–20 chars: a–z, 0–9, _</small>
      )}
      {status === 'checking' && (
        <small className="block text-xs text-gray-400 mt-1">Checking…</small>
      )}
      {status === 'available' && (
        <small className="block text-xs text-green-600 mt-1">Available</small>
      )}
      {status === 'taken' && (
        <small className="block text-xs text-red-500 mt-1">Taken</small>
      )}
    </div>
  );
};

export default UsernameAvailabilityField;
