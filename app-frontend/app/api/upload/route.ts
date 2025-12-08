import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
    try {
        // ALB forwards x-amzn-oidc-identity header (case-insensitive)
        // Next.js normalizes headers to lowercase
        let oidcIdentity = request.headers.get('x-amzn-oidc-identity');

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
        const formData = await request.formData();

        // Forward the request to backend with auth header
        const response = await fetch(`${backendUrl}/upload`, {
            method: 'POST',
            body: formData,
            headers: {
                'x-amzn-oidc-identity': oidcIdentity,
            },
        });

        const data = await response.json();
        return NextResponse.json(data, { status: response.status });
    } catch (error) {
        console.error('Error uploading file:', error);
        return NextResponse.json(
            { detail: 'Upload failed' },
            { status: 500 }
        );
    }
}
