import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const cognitoDomain = process.env.COGNITO_DOMAIN;
  const clientId = process.env.COGNITO_CLIENT_ID;
  const albDns = process.env.ALB_DNS;
  
  const redirectUri = `https://${albDns}/oauth2/idpresponse`;
  const loginUrl = `https://${cognitoDomain}/login?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code`;
  
  return NextResponse.json({ loginUrl });
}
