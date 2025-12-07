import { headers } from 'next/headers';
import { NextResponse } from 'next/server';

export async function GET() {
  const headersList = await headers();
  const oidcData = headersList.get('x-amzn-oidc-data');
  const oidcIdentity = headersList.get('x-amzn-oidc-identity');
  
  let email = 'Unknown';
  
  if (oidcData) {
    try {
      const payload = oidcData.split('.')[1];
      const decoded = JSON.parse(Buffer.from(payload, 'base64').toString());
      email = decoded.email || oidcIdentity || 'Unknown';
    } catch {
      email = oidcIdentity || 'Unknown';
    }
  }

  return NextResponse.json({ email });
}
