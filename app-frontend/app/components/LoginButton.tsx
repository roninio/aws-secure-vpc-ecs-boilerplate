'use client';

export default function LoginButton() {
  const handleLogin = async () => {
    const response = await fetch('/api/login-url');
    const data = await response.json();
    if (data.loginUrl) {
      window.location.href = data.loginUrl;
    }
  };

  return (
    <button 
      onClick={handleLogin}
      style={{
        background: '#28a745',
        color: 'white',
        border: 'none',
        padding: '12px 24px',
        borderRadius: '6px',
        fontSize: '16px',
        fontWeight: 'bold',
        cursor: 'pointer',
        boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
        transition: 'background 0.2s'
      }}
      onMouseOver={(e) => e.currentTarget.style.background = '#218838'}
      onMouseOut={(e) => e.currentTarget.style.background = '#28a745'}
    >
      Login
    </button>
  );
}
