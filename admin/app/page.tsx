'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '../lib/supabase';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Eye, EyeOff, Lock, Mail } from 'lucide-react';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // Redirect if already logged in
  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      if (data.session) {
        router.push('/dashboard');
      }
    });
  }, [router]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) {
        throw authError;
      }

      if (data.session) {
        // Ping backend to sync user / update last login
        const token = data.session.access_token;
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1'}/auth/login`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        });

        if (!response.ok) {
          // If the database role is not ADMIN or SUPER_ADMIN, the backend guard might reject
          const err = await response.json();
          throw new Error(err.message || 'Access Denied: Admin authorization failed.');
        }

        router.push('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to authenticate');
      // Sign out from supabase to clear any half-logged state
      await supabase.auth.signOut();
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen w-full flex flex-col justify-between items-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="flex-1 flex flex-col justify-center w-full max-w-md">
        {/* Logo Branding */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-24 h-24 flex items-center justify-center transform hover:scale-105 transition-transform duration-300">
            <img src="/logo.png" alt="Skillpay Logo" className="w-full h-full object-contain" />
          </div>
          <h2 className="mt-4 text-center text-3xl font-bold tracking-tight text-gray-900">
            Welcome Back!
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Enter your login credentials to access your account.
          </p>
        </div>

        {/* Login Card */}
        <Card className="border-gray-200 shadow-xl rounded-2xl overflow-hidden bg-white">
          <CardContent className="p-8">
            <form onSubmit={handleLogin} className="space-y-6">
              {error && (
                <div className="p-3 text-sm text-red-600 bg-red-50 rounded-lg border border-red-200">
                  {error}
                </div>
              )}

              {/* Email Address */}
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700 block">
                  Email Address
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                    <Mail size={18} />
                  </span>
                  <Input
                    id="email"
                    type="email"
                    required
                    placeholder="Enter email address"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="pl-10 h-11 border-gray-300 focus:border-amber-400 focus:ring-amber-400 rounded-xl"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700 block">
                  Password
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-gray-400">
                    <Lock size={18} />
                  </span>
                  <Input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    required
                    placeholder="Enter password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="pl-10 pr-10 h-11 border-gray-300 focus:border-amber-400 focus:ring-amber-400 rounded-xl"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              {/* Remember Me / Forgot Password */}
              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center text-gray-600 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="h-4 w-4 text-amber-500 border-gray-300 rounded focus:ring-amber-400"
                  />
                  <span className="ml-2 font-medium">Remember me</span>
                </label>
                <a
                  href="#"
                  className="font-semibold text-amber-500 hover:text-amber-600 transition-colors duration-200"
                >
                  Forgot Password?
                </a>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={loading}
                className="w-full h-11 bg-amber-400 hover:bg-amber-500 text-white font-bold rounded-xl shadow-md transition-colors duration-200 focus:ring-2 focus:ring-offset-2 focus:ring-amber-400"
              >
                {loading ? 'LOGGING IN...' : 'LOG IN'}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>

      {/* Footer copyright */}
      <div className="mt-8 text-center text-xs text-gray-400 tracking-wider uppercase font-semibold">
        CRAFTED BY SKILLPAY DESIGN TEAM
      </div>
    </main>
  );
}
