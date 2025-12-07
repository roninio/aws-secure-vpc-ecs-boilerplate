'use client';

import { useEffect } from 'react';

export default function LogoutSuccess() {
  useEffect(() => {
    localStorage.clear();
    sessionStorage.clear();
    setTimeout(() => window.location.href = '/', 2000);
  }, []);

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column',
      alignItems: 'center', 
      justifyContent: 'center', 
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    }}>
      <h1 style={{ color: 'white', fontSize: '2rem', marginBottom: '1rem' }}>
        Logged Out Successfully
      </h1>
      <p style={{ color: 'white', fontSize: '1.2rem' }}>
        Redirecting to home page...
      </p>
    </div>
  );
}
