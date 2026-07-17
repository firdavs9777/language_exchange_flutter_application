import React from 'react';
import { passwordStrength } from './validators';

const LABELS = ['Weak', 'Weak', 'Fair', 'Strong'];

const PasswordStrengthMeter: React.FC<{ password: string }> = ({ password }) => {
  const s = passwordStrength(password);
  const label = password ? LABELS[s.score] : '';

  // Color mapping for strength score
  const barColors: Record<number, string> = {
    0: 'bg-red-500',
    1: 'bg-orange-500',
    2: 'bg-yellow-500',
    3: 'bg-green-500',
  };

  // Width mapping for strength score (as percentage of max)
  const barWidths: Record<number, string> = {
    0: 'w-1/4',
    1: 'w-1/2',
    2: 'w-3/4',
    3: 'w-full',
  };

  return (
    <div className="space-y-2">
      <div className="h-2 bg-gray-200 rounded overflow-hidden">
        <div
          className={`h-full ${barColors[s.score]} transition-all ${barWidths[s.score]}`}
          aria-hidden
        />
      </div>
      {password && <small className="text-gray-700">{label}</small>}
      {password && !s.valid && (
        <ul className="text-xs text-gray-600 space-y-1">
          {!s.hasMin && <li>At least 8 characters</li>}
          {!s.hasUpper && <li>One uppercase letter</li>}
          {!s.hasLower && <li>One lowercase letter</li>}
          {!s.hasDigit && <li>One number</li>}
        </ul>
      )}
    </div>
  );
};

export default PasswordStrengthMeter;
