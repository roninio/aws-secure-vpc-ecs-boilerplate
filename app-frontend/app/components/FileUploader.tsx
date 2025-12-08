'use client';

import { useState, useEffect } from 'react';

interface FileItem {
    file_id: string;
    filename: string;
    size: number;
    uploaded_at: string;
}

export default function FileUploader() {
    const [files, setFiles] = useState<FileItem[]>([]);
    const [isUploading, setIsUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    const MAX_FILE_SIZE_MB = 40;
    const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024;

    // Fetch user's files on component mount
    useEffect(() => {
        fetchFiles();
    }, []);

    const fetchFiles = async () => {
        try {
            setIsLoading(true);
            const response = await fetch(`/api/files`, {
                method: 'GET',
                credentials: 'include',
            });

            if (response.ok) {
                const data = await response.json();
                setFiles(data.files || []);
            } else if (response.status === 401) {
                setError('Not authenticated. Please log in.');
            } else {
                setError('Failed to fetch files');
            }
        } catch (err) {
            console.error('Error fetching files:', err);
            setError('Failed to load files');
        } finally {
            setIsLoading(false);
        }
    };

    const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const selectedFile = event.target.files?.[0];
        if (!selectedFile) return;

        // Validate file size
        if (selectedFile.size > MAX_FILE_SIZE_BYTES) {
            setError(`File size exceeds ${MAX_FILE_SIZE_MB}MB limit`);
            return;
        }

        setError(null);
        setSuccess(null);
        setIsUploading(true);
        setUploadProgress(0);

        try {
            const formData = new FormData();
            formData.append('file', selectedFile);

            const xhr = new XMLHttpRequest();

            // Track upload progress
            xhr.upload.addEventListener('progress', (e) => {
                if (e.lengthComputable) {
                    const percentComplete = (e.loaded / e.total) * 100;
                    setUploadProgress(percentComplete);
                }
            });

            // Handle completion
            xhr.addEventListener('load', () => {
                if (xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText);
                    setSuccess(`File "${selectedFile.name}" uploaded successfully!`);
                    setUploadProgress(0);
                    setIsUploading(false);
                    // Refresh file list
                    fetchFiles();
                    // Reset input
                    event.target.value = '';
                } else {
                    const response = JSON.parse(xhr.responseText);
                    setError(response.detail || 'Upload failed');
                    setIsUploading(false);
                }
            });

            // Handle error
            xhr.addEventListener('error', () => {
                setError('Upload failed');
                setIsUploading(false);
            });

            const uploadUrl = '/api/upload';
            xhr.open('POST', uploadUrl);
            xhr.send(formData);
        } catch (err) {
            console.error('Error uploading file:', err);
            setError('Upload failed');
            setIsUploading(false);
        }
    };

    const handleDownload = async (fileId: string, filename: string) => {
        try {
            const response = await fetch(
                `/api/files/${fileId}`,
                {
                    method: 'GET',
                    credentials: 'include',
                }
            );

            if (response.ok) {
                const data = await response.json();
                // Open the presigned URL in a new tab
                window.open(data.download_url, '_blank');
            } else if (response.status === 403) {
                setError('You do not have access to this file');
            } else if (response.status === 404) {
                setError('File not found');
            } else {
                setError('Failed to download file');
            }
        } catch (err) {
            console.error('Error downloading file:', err);
            setError('Failed to download file');
        }
    };

    const handleDelete = async (fileId: string) => {
        if (!confirm('Are you sure you want to delete this file?')) return;

        try {
            const response = await fetch(
                `/api/files/${fileId}`,
                {
                    method: 'DELETE',
                    credentials: 'include',
                }
            );

            if (response.ok) {
                setSuccess('File deleted successfully');
                fetchFiles();
            } else if (response.status === 403) {
                setError('You do not have permission to delete this file');
            } else if (response.status === 404) {
                setError('File not found');
            } else {
                setError('Failed to delete file');
            }
        } catch (err) {
            console.error('Error deleting file:', err);
            setError('Failed to delete file');
        }
    };

    const formatFileSize = (bytes: number) => {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString() + ' ' + new Date(dateString).toLocaleTimeString();
    };

    return (
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
            <h2 className="text-2xl font-bold text-gray-800 mb-6">File Storage</h2>

            {/* Upload Section */}
            <div className="mb-8">
                <label className="block text-sm font-medium text-gray-700 mb-4">
                    Upload File (Max {MAX_FILE_SIZE_MB}MB)
                </label>
                <div className="flex items-center gap-4">
                    <input
                        type="file"
                        onChange={handleFileUpload}
                        disabled={isUploading}
                        className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                    />
                    {isUploading && (
                        <div className="flex-1">
                            <div className="w-full bg-gray-200 rounded-full h-2">
                                <div
                                    className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                                    style={{ width: `${uploadProgress}%` }}
                                />
                            </div>
                            <p className="text-sm text-gray-600 mt-1">{Math.round(uploadProgress)}%</p>
                        </div>
                    )}
                </div>
            </div>

            {/* Messages */}
            {error && (
                <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
                    {error}
                </div>
            )}
            {success && (
                <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
                    {success}
                </div>
            )}

            {/* Files List */}
            <div>
                <h3 className="text-lg font-semibold text-gray-800 mb-4">Your Files</h3>
                {isLoading ? (
                    <p className="text-gray-600">Loading files...</p>
                ) : files.length === 0 ? (
                    <p className="text-gray-600">No files uploaded yet</p>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                            <thead className="bg-gray-50 border-b">
                                <tr>
                                    <th className="text-left px-4 py-2 font-semibold text-gray-700">Filename</th>
                                    <th className="text-left px-4 py-2 font-semibold text-gray-700">Size</th>
                                    <th className="text-left px-4 py-2 font-semibold text-gray-700">Uploaded</th>
                                    <th className="text-left px-4 py-2 font-semibold text-gray-700">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {files.map((file) => (
                                    <tr key={file.file_id} className="border-b hover:bg-gray-50">
                                        <td className="px-4 py-3 text-gray-800">{file.filename}</td>
                                        <td className="px-4 py-3 text-gray-600">{formatFileSize(file.size)}</td>
                                        <td className="px-4 py-3 text-gray-600">{formatDate(file.uploaded_at)}</td>
                                        <td className="px-4 py-3">
                                            <button
                                                onClick={() => handleDownload(file.file_id, file.filename)}
                                                className="text-blue-500 hover:text-blue-700 font-medium mr-3"
                                            >
                                                Download
                                            </button>
                                            <button
                                                onClick={() => handleDelete(file.file_id)}
                                                className="text-red-500 hover:text-red-700 font-medium"
                                            >
                                                Delete
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
}
