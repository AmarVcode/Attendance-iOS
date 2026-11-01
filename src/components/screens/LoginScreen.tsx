import React, { useState } from 'react';
import { Mail, Lock, Eye, EyeOff, ShieldCheck, Cpu, ArrowRight, AlertCircle, Wifi, WifiOff } from 'lucide-react';
import { apiService } from '../../services/api';
import { StorageService } from '../../services/storage';

interface LoginScreenProps {
  onNavigateToHome: () => void;
  onNavigateToPending: () => void;
  onNavigateToSignup: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({
  onNavigateToHome,
  onNavigateToPending,
  onNavigateToSignup,
}) => {
  const [email, setEmail] = useState('test@mnitsolutions.in');
  const [password, setPassword] = useState('password123');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const deviceUid = StorageService.getOrGenerateDeviceUID();
  const [isOfflineForced, setIsOfflineForced] = useState(StorageService.isOfflineForced());

  const handleToggleOffline = () => {
    const next = !isOfflineForced;
    setIsOfflineForced(next);
    StorageService.setOfflineForced(next);
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!email.trim()) {
      setErrorMessage('Please enter your employee email address.');
      return;
    }
    if (!password.trim()) {
      setErrorMessage('Please enter your password.');
      return;
    }

    setIsLoading(true);
    try {
      const response = await apiService.login({
        email: email.trim(),
        password: password.trim(),
        deviceUid,
      });

      if (response.success) {
        const status = response.status?.toLowerCase();
        if (status === 'approved' || status === 'active') {
          onNavigateToHome();
        } else {
          onNavigateToPending();
        }
      } else {
        setErrorMessage(response.message || 'Authentication failed. Please verify credentials.');
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to authenticate. Server connection timeout.');
    } finally {
      setIsLoading(false);
    }
  };

  const fillDemoAccount = () => {
    setEmail('test@mnitsolutions.in');
    setPassword('password123');
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-center items-center py-10 px-4 sm:px-6">
      <div className="w-full max-w-md">
        {/* Offline Mode Banner Toggle */}
        <div className="flex items-center justify-between mb-4 px-1">
          <div className="flex items-center gap-2">
            <span
              className={`w-2.5 h-2.5 rounded-full ${
                isOfflineForced ? 'bg-amber-500' : 'bg-emerald-500'
              }`}
            />
            <span className="text-xs font-semibold text-slate-600">
              {isOfflineForced ? 'Offline Mode (Local Storage)' : 'Network Mode (Proxy/Live)'}
            </span>
          </div>

          <button
            type="button"
            onClick={handleToggleOffline}
            className="text-xs font-medium text-indigo-600 hover:text-indigo-800 bg-indigo-50 hover:bg-indigo-100 px-2.5 py-1 rounded-full transition flex items-center gap-1"
          >
            {isOfflineForced ? <WifiOff size={12} /> : <Wifi size={12} />}
            Toggle Offline Mode
          </button>
        </div>

        {/* Branding Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-white shadow-md border border-slate-200/80 p-3 mb-4">
            <img
              src="/ic_logo.png"
              alt="MNIT Attendance"
              className="w-full h-full object-contain"
              onError={(e) => {
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            MNIT Attendance
          </h1>
          <p className="text-sm text-slate-500 mt-1 font-medium">
            Secure Employee Verification Portal
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="mb-5 p-3.5 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs sm:text-sm flex items-start gap-2.5 animate-in fade-in duration-150">
            <AlertCircle size={18} className="shrink-0 mt-0.5" />
            <div className="flex-1 font-medium">{errorMessage}</div>
          </div>
        )}

        {/* Login Card */}
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xl shadow-slate-200/50 p-6 sm:p-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-xl font-bold text-slate-900">Sign In</h2>
              <p className="text-xs text-slate-500 mt-0.5">Enter registered employee credentials</p>
            </div>
            <span className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
              <ShieldCheck size={20} />
            </span>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                Email Address
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <Mail size={17} />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="employee@mnitsolutions.in"
                  className="w-full pl-10 pr-3.5 py-3 bg-slate-50/50 border border-slate-200 rounded-xl text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
                  required
                />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider">
                  Password
                </label>
              </div>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <Lock size={17} />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full pl-10 pr-11 py-3 bg-slate-50/50 border border-slate-200 rounded-xl text-slate-900 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3.5 flex items-center text-slate-400 hover:text-slate-600 transition"
                >
                  {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                </button>
              </div>
            </div>

            {/* Device Hardware UID info pill */}
            <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200/80 flex items-center gap-2 text-slate-500 text-[11px]">
              <Cpu size={14} className="text-indigo-600 shrink-0" />
              <div className="truncate">
                <span className="font-semibold text-slate-700">Device UID:</span>{' '}
                <span className="font-mono text-slate-600">{deviceUid}</span>
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3.5 px-4 bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-500 hover:to-indigo-600 active:scale-[0.99] text-white font-bold text-sm rounded-xl shadow-lg shadow-indigo-600/25 transition flex items-center justify-center gap-2 disabled:opacity-60"
            >
              {isLoading ? (
                <>
                  <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  <span>Verifying Device & Credentials...</span>
                </>
              ) : (
                <>
                  <span>SIGN IN</span>
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </form>

          {/* Quick Demo Credentials shortcut */}
          <div className="mt-5 pt-4 border-t border-slate-100">
            <button
              type="button"
              onClick={fillDemoAccount}
              className="w-full py-2 px-3 text-xs font-semibold text-indigo-700 hover:text-indigo-900 bg-indigo-50/70 hover:bg-indigo-100/70 rounded-lg transition text-center"
            >
              Fill Sample Credentials (test@mnitsolutions.in / password123)
            </button>
          </div>
        </div>

        {/* Footer Link to Signup */}
        <div className="text-center mt-6">
          <p className="text-sm text-slate-600">
            New employee at MNIT?{' '}
            <button
              type="button"
              onClick={onNavigateToSignup}
              className="font-bold text-indigo-600 hover:text-indigo-800 transition"
            >
              Register your device
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};
