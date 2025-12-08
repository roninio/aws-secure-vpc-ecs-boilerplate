import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
    try {
        // ALB forwards x-amzn-oidc-identity header (case-insensitive)
        // Next.js normalizes headers to lowercase
        let oidcIdentity = request.headers.get('x-amzn-oidc-identity');

        // Fallback: check multiple header variations
        if (!oidcIdentity) {
            oidcIdentity = request.headers.get('x-amzn-oidc-identity');
        }

        // Debug log to help troubleshoot
        console.log('Available headers:', Array.from(request.headers.entries()));
        console.log('OIDC Identity:', oidcIdentity);

        if (!oidcIdentity) {
            return NextResponse.json(
                { detail: 'Not authenticated - missing x-amzn-oidc-identity header' },
                { status: 401 }
            );
        }

        const backendUrl = process.env.BACKEND_URL || 'http://backend.my-secure-app.local:3000';

        const response = await fetch(`${backendUrl}/files`, {
            method: 'GET',
            headers: {
                'x-amzn-oidc-identity': oidcIdentity,
            },
        });

        const data = await response.json();
        return NextResponse.json(data, { status: response.status });
    } catch (error) {
        console.error('Error fetching files:', error);
        return NextResponse.json(
            { detail: 'Failed to fetch files' },
            { status: 500 }
        );
    }
}

