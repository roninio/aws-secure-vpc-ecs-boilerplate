import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function GET() {
  const cognitoDomain = process.env.COGNITO_DOMAIN;
  const clientId = process.env.COGNITO_CLIENT_ID;
  const albDns = process.env.ALB_DNS;
  
  const logoutUri = `https://${albDns}/logout-success`;
  const logoutUrl = `https://${cognitoDomain}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
  
  const response = NextResponse.redirect(logoutUrl);
  
  // Expire ALB auth session cookies (0 and 1 are the standard cookie names)
  ['AWSELBAuthSessionCookie-0', 'AWSELBAuthSessionCookie-1'].forEach(cookieName => {
    response.cookies.set(cookieName, '', {
      maxAge: 0,
      path: '/',
      expires: new Date(0),
      httpOnly: true,
      secure: true
    });
  });
  
  return response;
}
