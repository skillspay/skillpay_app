'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '../../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ArrowLeft, CheckCircle } from 'lucide-react';

export default function UserProfilePage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [verifying, setVerifying] = useState(false);

  const fetchUser = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.users.get(params.id);
      setUser(res);
    } catch (err) {
      console.error('Failed to load user', err);
    } finally {
      setLoading(false);
    }
  }, [params.id]);

  useEffect(() => {
    fetchUser();
  }, [fetchUser]);

  const handleVerify = async () => {
    setVerifying(true);
    try {
      await api.users.update(params.id, { isVerified: true });
      await fetchUser();
    } catch (err) {
      console.error('Failed to verify user', err);
    } finally {
      setVerifying(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center py-20">
        <div className="w-10 h-10 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="text-center py-20">
        <h2 className="text-xl font-bold text-gray-900">User not found</h2>
        <Button onClick={() => router.back()} className="mt-4" variant="outline">Go Back</Button>
      </div>
    );
  }

  const profile = user.role === 'HOMEOWNER' ? user.homeowner : user.artisan;
  const fullName = profile?.fullName || 'N/A';

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div className="flex items-center space-x-4">
        <Button variant="ghost" onClick={() => router.back()} className="p-2 -ml-2 rounded-full hover:bg-gray-100">
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </Button>
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">{fullName}</h1>
          <p className="text-gray-500 mt-1">User ID: <span className="font-mono">{user.id}</span></p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="md:col-span-2 border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Account Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500 font-medium">Email Address</p>
                <p className="font-semibold text-gray-900 mt-1">{user.email}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500 font-medium">Phone Number</p>
                <p className="font-semibold text-gray-900 mt-1">{user.phone || 'Not Provided'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500 font-medium">Role</p>
                <Badge variant="outline" className="mt-1 font-bold">{user.role}</Badge>
              </div>
              <div>
                <p className="text-sm text-gray-500 font-medium">Status</p>
                <Badge className={`mt-1 font-bold border-none ${
                  user.status === 'ACTIVE' ? 'bg-green-100 text-green-800' : 
                  user.status === 'SUSPENDED' ? 'bg-amber-100 text-amber-800' : 'bg-red-100 text-red-800'
                }`}>
                  {user.status}
                </Badge>
              </div>
              <div>
                <p className="text-sm text-gray-500 font-medium">Joined Date</p>
                <p className="font-semibold text-gray-900 mt-1">{new Date(user.createdAt).toLocaleDateString()}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500 font-medium">Verification Status</p>
                <div className="flex items-center space-x-2 mt-1">
                  {user.isVerified ? (
                    <Badge className="bg-blue-100 text-blue-800 border-none font-bold">Verified</Badge>
                  ) : (
                    <Badge className="bg-gray-100 text-gray-800 border-none font-bold">Unverified</Badge>
                  )}
                </div>
              </div>
            </div>

            <hr className="border-gray-100" />
            
            <div>
              <h3 className="font-bold text-gray-900 mb-4">Profile Specific Details</h3>
              {user.role === 'HOMEOWNER' ? (
                <div className="space-y-4">
                  <div>
                    <p className="text-sm text-gray-500 font-medium">Default Address</p>
                    <p className="font-semibold text-gray-900 mt-1">{profile?.defaultAddress || 'Not Provided'}</p>
                  </div>
                </div>
              ) : user.role === 'ARTISAN' ? (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500 font-medium">Availability Status</p>
                    <Badge className="mt-1 font-semibold" variant="outline">{profile?.availabilityStatus || 'Unknown'}</Badge>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 font-medium">Rating</p>
                    <p className="font-semibold text-gray-900 mt-1">⭐ {profile?.averageRating || '0.0'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 font-medium">Completed Jobs</p>
                    <p className="font-semibold text-gray-900 mt-1">{profile?.completedJobs || 0}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500 font-medium">Verification State</p>
                    <p className="font-semibold text-gray-900 mt-1">{profile?.verificationStatus || 'N/A'}</p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-500">No additional details available for this role.</p>
              )}
            </div>
          </CardContent>
        </Card>

        <div className="space-y-6">
          <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
            <CardHeader>
              <CardTitle className="text-lg font-bold text-gray-900">Admin Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {!user.isVerified && (
                <Button 
                  className="w-full bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold flex items-center justify-center space-x-2" 
                  onClick={handleVerify}
                  disabled={verifying}
                >
                  <CheckCircle className="w-4 h-4" />
                  <span>{verifying ? 'Verifying...' : 'Manually Verify User'}</span>
                </Button>
              )}
              {user.isVerified && (
                <div className="p-4 bg-green-50 border border-green-100 rounded-xl text-center text-sm font-semibold text-green-800">
                  This user account is verified.
                </div>
              )}
              {user.role === 'ARTISAN' && !user.isVerified && (
                <p className="text-xs text-amber-600 bg-amber-50 p-3 rounded-lg border border-amber-100 mt-4">
                  Note: Manually verifying an Artisan bypasses the Document Verification flow. Their documents will remain pending.
                </p>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
