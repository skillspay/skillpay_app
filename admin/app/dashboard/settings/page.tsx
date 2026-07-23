'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '../../../lib/supabase';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Shield, User, Key, AlertTriangle } from 'lucide-react';

export default function SettingsPage() {
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [pwResult, setPwResult] = useState<{ success: boolean; message: string } | null>(null);
  const [pwLoading, setPwLoading] = useState(false);

  useEffect(() => {
    async function load() {
      try {
        const p = await api.auth.getProfile();
        setProfile(p);
      } catch (err) {
        console.error('Failed to load profile', err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setPwResult({ success: false, message: 'Passwords do not match.' });
      return;
    }
    if (newPassword.length < 8) {
      setPwResult({ success: false, message: 'Password must be at least 8 characters.' });
      return;
    }

    setPwLoading(true);
    setPwResult(null);
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) throw error;
      setPwResult({ success: true, message: 'Password updated successfully.' });
      setNewPassword('');
      setConfirmPassword('');
    } catch (err: any) {
      setPwResult({ success: false, message: err.message || 'Failed to update password.' });
    } finally {
      setPwLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Settings</h1>
        <p className="text-gray-500 mt-1">Manage your admin account and preferences.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Account Info */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <User size={20} className="text-amber-500" />
              Account Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Email</label>
              <p className="text-gray-900 font-semibold">{profile?.email || '—'}</p>
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Role</label>
              <div>
                <Badge className="bg-amber-100 text-amber-800 border-none font-bold">
                  {profile?.role || 'ADMIN'}
                </Badge>
              </div>
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Status</label>
              <div>
                <Badge className="bg-green-100 text-green-800 border-none font-bold">
                  {profile?.status || 'ACTIVE'}
                </Badge>
              </div>
            </div>
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Last Login</label>
              <p className="text-gray-700 font-medium">
                {profile?.lastLogin
                  ? new Date(profile.lastLogin).toLocaleString()
                  : 'N/A'}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Change Password */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <Key size={20} className="text-amber-500" />
              Change Password
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handlePasswordChange} className="space-y-4">
              {pwResult && (
                <div
                  className={`p-3 rounded-xl text-sm font-medium border ${
                    pwResult.success
                      ? 'bg-green-50 text-green-700 border-green-200'
                      : 'bg-red-50 text-red-700 border-red-200'
                  }`}
                >
                  {pwResult.message}
                </div>
              )}
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">New Password</label>
                <Input
                  type="password"
                  required
                  minLength={8}
                  placeholder="Min 8 characters"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="h-11 rounded-xl border-gray-300 focus:border-amber-400 focus:ring-amber-400"
                />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Confirm Password</label>
                <Input
                  type="password"
                  required
                  placeholder="Repeat new password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="h-11 rounded-xl border-gray-300 focus:border-amber-400 focus:ring-amber-400"
                />
              </div>
              <Button
                type="submit"
                disabled={pwLoading}
                className="w-full h-11 bg-amber-400 hover:bg-amber-500 text-white font-bold rounded-xl"
              >
                {pwLoading ? 'Updating...' : 'Update Password'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>

      {/* Security note */}
      <Card className="border-amber-200 bg-amber-50 shadow-sm rounded-2xl">
        <CardContent className="p-5 flex items-start gap-3">
          <AlertTriangle size={20} className="text-amber-600 mt-0.5 shrink-0" />
          <div>
            <p className="font-bold text-amber-800">Security Reminder</p>
            <p className="text-sm text-amber-700 mt-1">
              Admin accounts have full platform access. Use a strong unique password and never share your credentials.
              All admin actions are logged in the audit trail.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* API config reference */}
      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900 flex items-center gap-2">
            <Shield size={20} className="text-amber-500" />
            API Configuration
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex justify-between items-center py-2 border-b border-gray-100">
            <span className="text-sm font-semibold text-gray-600">API Base URL</span>
            <code className="text-xs bg-gray-100 px-2 py-1 rounded-lg font-mono text-gray-700">
              {process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1'}
            </code>
          </div>
          <div className="flex justify-between items-center py-2">
            <span className="text-sm font-semibold text-gray-600">Auth Provider</span>
            <Badge variant="outline" className="font-semibold">Supabase JWT</Badge>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
