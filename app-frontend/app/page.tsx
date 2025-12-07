import LogoutButton from './components/LogoutButton';
import UserInfo from './components/UserInfo';
import TextSaver from './components/TextSaver';

export default function Home() {
  return (
    <main style={{ padding: '40px', maxWidth: '1200px', margin: '0 auto' }}>
      <div style={{
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '60px',
        borderRadius: '10px',
        color: 'white',
        marginBottom: '30px',
        boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
        textAlign: 'center'
      }}>
        <h1 style={{ margin: 0, fontSize: '3em', marginBottom: '20px' }}>🚀 App Frontend</h1>
        <p style={{ fontSize: '1.5em', margin: 0 }}>
          Welcome to the Next.js Application Frontend
        </p>
        <UserInfo />
        <TextSaver />
        <div style={{ marginTop: '30px' }}>
          <LogoutButton />
        </div>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
        gap: '20px',
        marginTop: '30px'
      }}>
        <div style={{
          background: 'white',
          padding: '30px',
          borderRadius: '10px',
          boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ marginTop: 0, color: '#333' }}>Features</h2>
          <ul style={{ color: '#666', lineHeight: '1.8' }}>
            <li>Next.js 14 with App Router</li>
            <li>TypeScript Support</li>
            <li>Server Components</li>
            <li>Optimized Performance</li>
          </ul>
        </div>

        <div style={{
          background: 'white',
          padding: '30px',
          borderRadius: '10px',
          boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
        }}>
          <h2 style={{ marginTop: 0, color: '#333' }}>Status</h2>
          <p style={{ color: '#666', fontSize: '1.1em' }}>
            ✅ Application is running
          </p>
          <p style={{ color: '#666', fontSize: '1.1em' }}>
            ✅ Connected to AWS ECS
          </p>
          <p style={{ color: '#666', fontSize: '1.1em' }}>
            ✅ Load balanced via ALB
          </p>
        </div>
      </div>
    </main>
  )
}


