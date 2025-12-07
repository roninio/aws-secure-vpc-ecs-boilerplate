'use client';

import { useState } from 'react';

export default function TextSaver() {
  const [text, setText] = useState('');
  const [message, setMessage] = useState('');

  const handleSave = async () => {
    const response = await fetch('/api/save-text', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text })
    });
    const data = await response.json();
    setMessage(data.message);
    setText('');
  };

  return (
    <div style={{ marginTop: '20px' }}>
      <input
        type="text"
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Enter text to save"
        style={{
          padding: '10px',
          width: '300px',
          marginRight: '10px',
          borderRadius: '4px',
          border: '1px solid #ccc'
        }}
      />
      <button
        onClick={handleSave}
        style={{
          background: '#28a745',
          color: 'white',
          border: 'none',
          padding: '10px 20px',
          borderRadius: '4px',
          cursor: 'pointer'
        }}
      >
        Save to DynamoDB
      </button>
      {message && <p style={{ marginTop: '10px', color: 'green' }}>{message}</p>}
    </div>
  );
}
