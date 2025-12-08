import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { fileId: string } }
) {
  try {
    const oidcIdentity = request.headers.get('x-amzn-oidc-identity');

    if (!oidcIdentity) {
      return NextResponse.json(
        { detail: 'Not authenticated' },
        { status: 401 }
      );
    }

    const backendUrl = process.env.BACKEND_URL || 'http://backend.my-secure-app.local:3000';
    const fileId = params.fileId;

    const response = await fetch(`${backendUrl}/download/${fileId}`, {
      method: 'GET',
      headers: {
        'x-amzn-oidc-identity': oidcIdentity,
      },
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Error generating download URL:', error);
    return NextResponse.json(
      { detail: 'Failed to generate download URL' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { fileId: string } }
) {
  try {
    const oidcIdentity = request.headers.get('x-amzn-oidc-identity');

    if (!oidcIdentity) {
      return NextResponse.json(
        { detail: 'Not authenticated' },
        { status: 401 }
      );
    }

    const backendUrl = process.env.BACKEND_URL || 'http://backend.my-secure-app.local:3000';
    const fileId = params.fileId;

    const response = await fetch(`${backendUrl}/files/${fileId}`, {
      method: 'DELETE',
      headers: {
        'x-amzn-oidc-identity': oidcIdentity,
      },
    });

    const data = await response.json();
    return NextResponse.json(data, { status: response.status });
  } catch (error) {
    console.error('Error deleting file:', error);
    return NextResponse.json(
      { detail: 'Failed to delete file' },
      { status: 500 }
    );
  }
}
