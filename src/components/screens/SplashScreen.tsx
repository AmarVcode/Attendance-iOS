import React, { useEffect } from 'react';
import { StorageService } from '../../services/storage';

interface SplashScreenProps {
  onNavigate: (screen: 'LOGIN' | 'PENDING' | 'HOME') => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onNavigate }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      const token = StorageService.getAuthToken();
      const user = StorageService.getUser();

      if (token && user) {
        const status = user.status?.toLowerCase();
        if (status === 'approved' || status === 'active') {
          onNavigate('HOME');
        } else {
          onNavigate('PENDING');
        }
      } else {
        onNavigate('LOGIN');
      }
    }, 1200);

    return () => clearTimeout(timer);
  }, [onNavigate]);

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center p-6 text-white select-none">
      <div className="flex flex-col items-center max-w-sm text-center">
        {/* Logo Card */}
        <div className="relative mb-6">
          <div className="w-28 h-28 rounded-3xl bg-white/10 backdrop-blur-xl border border-white/20 p-4 shadow-2xl flex items-center justify-center">
            <img
              src="/ic_logo.png"
              alt="MNIT Attendance Logo"
              className="w-full h-full object-contain drop-shadow"
              onError={(e) => {
                // Fallback to text if missing
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
          </div>
          <div className="absolute -inset-1 rounded-3xl bg-gradient-to-r from-indigo-500 to-purple-600 opacity-30 blur-lg -z-10" />
        </div>

        <h1 className="text-3xl font-extrabold tracking-tight text-white mb-2">
          MNIT Attendance
        </h1>
        <p className="text-sm font-medium text-indigo-200/80 mb-10 tracking-wide uppercase">
          Secure Employee Verification Portal
        </p>

        {/* Pulse Loader */}
        <div className="flex items-center gap-2 mb-12">
          <span className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-bounce" style={{ animationDelay: '0ms' }} />
          <span className="w-2.5 h-2.5 rounded-full bg-indigo-400 animate-bounce" style={{ animationDelay: '150ms' }} />
          <span className="w-2.5 h-2.5 rounded-full bg-indigo-300 animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>

        <div className="text-xs text-slate-400 font-mono tracking-wider">
          VERSION 1.0 (IOS NATIVE PARITY)
        </div>
      </div>
    </div>
  );
};
