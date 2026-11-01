import React, { useState } from 'react';
import { SplashScreen } from './components/screens/SplashScreen';
import { LoginScreen } from './components/screens/LoginScreen';
import { SignupScreen } from './components/screens/SignupScreen';
import { PendingApprovalScreen } from './components/screens/PendingApprovalScreen';
import { HomeScreen } from './components/screens/HomeScreen';

type ScreenState = 'SPLASH' | 'LOGIN' | 'SIGNUP' | 'PENDING' | 'HOME';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<ScreenState>('SPLASH');

  return (
    <div className="min-h-screen bg-slate-100 font-sans text-slate-900">
      {currentScreen === 'SPLASH' && (
        <SplashScreen
          onNavigate={(target) => setCurrentScreen(target)}
        />
      )}

      {currentScreen === 'LOGIN' && (
        <LoginScreen
          onNavigateToHome={() => setCurrentScreen('HOME')}
          onNavigateToPending={() => setCurrentScreen('PENDING')}
          onNavigateToSignup={() => setCurrentScreen('SIGNUP')}
        />
      )}

      {currentScreen === 'SIGNUP' && (
        <SignupScreen
          onNavigateToLogin={() => setCurrentScreen('LOGIN')}
          onNavigateToPending={() => setCurrentScreen('PENDING')}
        />
      )}

      {currentScreen === 'PENDING' && (
        <PendingApprovalScreen
          onNavigateToHome={() => setCurrentScreen('HOME')}
          onNavigateToLogin={() => setCurrentScreen('LOGIN')}
        />
      )}

      {currentScreen === 'HOME' && (
        <HomeScreen
          onNavigateToLogin={() => setCurrentScreen('LOGIN')}
        />
      )}
    </div>
  );
}
