'use client';

export default function LogoutButton() {
  const handleLogout = () => {
    window.location.href = '/api/logout-url';
  };

  return (
    <button 
      onClick={handleLogout}
      style={{
        background: '#dc3545',
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
      onMouseOver={(e) => e.currentTarget.style.background = '#c82333'}
      onMouseOut={(e) => e.currentTarget.style.background = '#dc3545'}
    >
      Logout
    </button>
  );
}
