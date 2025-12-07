'use client';

import { useEffect, useState } from 'react';

export default function UserInfo() {
  const [email, setEmail] = useState('Loading...');

  useEffect(() => {
    fetch('/api/user')
      .then(res => res.json())
      .then(data => setEmail(data.email || 'Unknown'))
      .catch(() => setEmail('Unknown'));
  }, []);

  return (
    <div style={{
      background: 'rgba(255,255,255,0.2)',
      padding: '15px 25px',
      borderRadius: '8px',
      display: 'inline-block',
      marginTop: '20px'
    }}>
      <span style={{ fontSize: '1.1em' }}>👤 Logged in as: <strong>{email}</strong></span>
    </div>
  );
}
