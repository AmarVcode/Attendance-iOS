import React from 'react';

interface CustomCardProps {
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
}

export const CustomCard: React.FC<CustomCardProps> = ({ children, className = '', onClick }) => {
  return (
    <div
      onClick={onClick}
      className={`bg-white rounded-2xl border border-slate-200/80 shadow-[0_2px_8px_rgba(15,23,42,0.04)] p-4 sm:p-5 transition-all duration-200 ${
        onClick ? 'cursor-pointer hover:border-indigo-200 hover:shadow-md active:scale-[0.99]' : ''
      } ${className}`}
    >
      {children}
    </div>
  );
};
