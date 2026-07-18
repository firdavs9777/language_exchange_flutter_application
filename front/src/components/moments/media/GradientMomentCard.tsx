import React from 'react';
import { gradientFor } from './momentGradients';

interface GradientMomentCardProps {
  text: string;
  backgroundColor?: string;
  className?: string;
}

/**
 * Renders a "text moment" — a caption centered over a gradient background,
 * matching the Flutter app's text/gradient moment style.
 */
const GradientMomentCard: React.FC<GradientMomentCardProps> = ({
  text,
  backgroundColor,
  className = '',
}) => {
  return (
    <div
      data-testid="gradient-moment-card"
      className={
        'flex min-h-[250px] w-full items-center justify-center rounded-2xl p-6 ' +
        className
      }
      style={{ background: gradientFor(backgroundColor) }}
    >
      <p className="max-w-full break-words text-center text-2xl font-bold leading-snug text-white drop-shadow-sm sm:text-3xl">
        {text}
      </p>
    </div>
  );
};

export default GradientMomentCard;
