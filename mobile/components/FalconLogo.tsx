import React from 'react';
import Svg, { Path, G, Circle } from 'react-native-svg';

interface FalconLogoProps {
  size?: number;
  color?: string;
  showText?: boolean;
}

const FalconLogo: React.FC<FalconLogoProps> = ({ size = 40, color = '#E8A020' }) => {
  return (
    <Svg width={size} height={size} viewBox="0 0 100 100" fill="none">
      {/* Falcon body */}
      <G>
        {/* Head */}
        <Circle cx="62" cy="22" r="10" fill={color} />
        {/* Beak */}
        <Path
          d="M70 19 L82 22 L70 26 Z"
          fill={color}
        />
        {/* Eye */}
        <Circle cx="64" cy="20" r="2.5" fill="#000" />
        <Circle cx="65" cy="19.5" r="0.8" fill="#fff" />
        {/* Head stripe/mask */}
        <Path
          d="M54 26 Q58 30 66 28 Q62 35 54 26 Z"
          fill="#1A1A1A"
          opacity="0.6"
        />

        {/* Body */}
        <Path
          d="M30 45 Q45 30 62 32 Q70 35 68 45 Q65 58 55 65 Q45 70 35 62 Q25 55 30 45 Z"
          fill={color}
        />

        {/* Chest highlight */}
        <Path
          d="M38 48 Q48 40 60 44 Q58 56 50 62 Q42 65 38 58 Q34 52 38 48 Z"
          fill="#F5C060"
          opacity="0.4"
        />

        {/* Left wing */}
        <Path
          d="M30 45 Q15 35 5 50 Q10 55 20 52 Q15 60 12 70 Q20 65 28 58 Q22 65 25 72 Q35 62 35 55 Z"
          fill={color}
        />

        {/* Right wing (tucked) */}
        <Path
          d="M62 40 Q75 38 85 48 Q80 52 72 50 Q78 58 80 65 Q70 60 65 52 Z"
          fill={color}
          opacity="0.85"
        />

        {/* Tail feathers */}
        <Path
          d="M40 65 Q35 80 30 90 Q40 85 48 78"
          stroke={color}
          strokeWidth="5"
          strokeLinecap="round"
          fill="none"
        />
        <Path
          d="M48 67 Q46 82 44 92 Q52 86 56 78"
          stroke={color}
          strokeWidth="5"
          strokeLinecap="round"
          fill="none"
        />
        <Path
          d="M55 65 Q57 80 58 88 Q64 82 64 74"
          stroke={color}
          strokeWidth="4"
          strokeLinecap="round"
          fill="none"
        />

        {/* Talons */}
        <Path
          d="M35 72 Q30 78 26 82 M35 72 Q32 80 31 85 M35 72 Q38 78 38 83"
          stroke={color}
          strokeWidth="3"
          strokeLinecap="round"
          fill="none"
        />
      </G>
    </Svg>
  );
};

export default FalconLogo;
