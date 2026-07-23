'use client';

import React, { useState, useEffect } from 'react';
import { api, request } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Users,
  Briefcase,
  DollarSign,
  Star,
  TrendingUp,
  CheckCircle,
  Clock,
  XCircle,
} from 'lucide-react';

interface PlatformStats {
  users: any;
  payments: any;
  jobs: any;
}

export default function AnalyticsPage() {
  const [stats, setStats] = useState<PlatformStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [users, payments, jobs] = await Promise.all([
          api.users.getStats(),
          api.payments.getStats(),
          request('/admin/bookings').then((res: any[]) => ({
            total: res?.length ?? 0,
            confirmed: res?.filter((b: any) => b.status === 'CONFIRMED').length ?? 0,
            completed: res?.filter((b: any) => b.status === 'COMPLETED').length ?? 0,
            cancelled: res?.filter((b: any) => b.status === 'CANCELLED').length ?? 0,
          })),
        ]);
        setStats({ users, payments, jobs });
      } catch (err) {
        console.error('Failed to load analytics', err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin" />
      </div>
    );
  }

  const topStats = [
    {
      label: 'Total Users',
      value: stats?.users?.total ?? 0,
      sub: `${stats?.users?.homeowners ?? 0} homeowners · ${stats?.users?.artisans ?? 0} artisans`,
      icon: Users,
      color: 'text-blue-600 bg-blue-50',
    },
    {
      label: 'Total Revenue',
      value: `$${(stats?.payments?.totalVolume ?? 0).toFixed(2)}`,
      sub: `Stripe $${(stats?.payments?.stripeVolume ?? 0).toFixed(2)} · PayPal $${(stats?.payments?.paypalVolume ?? 0).toFixed(2)}`,
      icon: DollarSign,
      color: 'text-green-600 bg-green-50',
    },
    {
      label: 'Total Bookings',
      value: stats?.jobs?.total ?? 0,
      sub: `${stats?.jobs?.completed ?? 0} completed`,
      icon: Briefcase,
      color: 'text-amber-600 bg-amber-50',
    },
    {
      label: 'Active Users',
      value: stats?.users?.active ?? 0,
      sub: `${stats?.users?.suspended ?? 0} suspended · ${stats?.users?.banned ?? 0} banned`,
      icon: TrendingUp,
      color: 'text-purple-600 bg-purple-50',
    },
  ];

  const bookingBreakdown = [
    { label: 'Confirmed', value: stats?.jobs?.confirmed ?? 0, icon: CheckCircle, color: 'text-blue-600' },
    { label: 'Completed', value: stats?.jobs?.completed ?? 0, icon: Star, color: 'text-green-600' },
    { label: 'Cancelled', value: stats?.jobs?.cancelled ?? 0, icon: XCircle, color: 'text-red-600' },
    { label: 'In Progress', value: Math.max(0, (stats?.jobs?.total ?? 0) - (stats?.jobs?.confirmed ?? 0) - (stats?.jobs?.completed ?? 0) - (stats?.jobs?.cancelled ?? 0)), icon: Clock, color: 'text-amber-600' },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Analytics</h1>
        <p className="text-gray-500 mt-1">Platform-wide performance metrics and growth indicators.</p>
      </div>

      {/* Top KPI cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {topStats.map((s) => {
          const Icon = s.icon;
          return (
            <Card key={s.label} className="border-gray-200 shadow-sm rounded-2xl bg-white hover:shadow-md transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-xs font-bold text-gray-500 uppercase tracking-wider">
                  {s.label}
                </CardTitle>
                <div className={`p-2.5 rounded-xl ${s.color}`}>
                  <Icon size={18} />
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-black text-gray-900">{s.value}</div>
                <p className="text-xs text-gray-400 mt-1">{s.sub}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Booking breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Booking Status Breakdown</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {bookingBreakdown.map((item) => {
              const Icon = item.icon;
              const total = stats?.jobs?.total || 1;
              const pct = Math.round((item.value / total) * 100);
              return (
                <div key={item.label}>
                  <div className="flex items-center justify-between mb-1.5">
                    <div className="flex items-center gap-2">
                      <Icon size={16} className={item.color} />
                      <span className="text-sm font-semibold text-gray-700">{item.label}</span>
                    </div>
                    <span className="text-sm font-bold text-gray-900">{item.value}</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div
                      className="h-2 rounded-full bg-amber-400 transition-all duration-500"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>

        {/* Revenue breakdown */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Revenue by Gateway</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {[
              { label: 'Stripe', value: stats?.payments?.stripeVolume ?? 0, color: 'bg-indigo-400' },
              { label: 'PayPal', value: stats?.payments?.paypalVolume ?? 0, color: 'bg-blue-400' },
            ].map((g) => {
              const total = stats?.payments?.totalVolume || 1;
              const pct = Math.round((g.value / total) * 100);
              return (
                <div key={g.label}>
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-sm font-semibold text-gray-700">{g.label}</span>
                    <span className="text-sm font-bold text-gray-900">${g.value.toFixed(2)}</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-3">
                    <div
                      className={`h-3 rounded-full ${g.color} transition-all duration-500`}
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400 mt-1">{pct}% of total volume</p>
                </div>
              );
            })}

            <div className="pt-4 border-t border-gray-100">
              <div className="flex justify-between items-center">
                <span className="font-bold text-gray-700">Total Platform Revenue</span>
                <span className="text-2xl font-black text-gray-900">
                  ${(stats?.payments?.totalVolume ?? 0).toFixed(2)}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* User distribution */}
      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">User Distribution</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            {[
              { label: 'Homeowners', value: stats?.users?.homeowners ?? 0, color: 'bg-blue-50 text-blue-700' },
              { label: 'Artisans', value: stats?.users?.artisans ?? 0, color: 'bg-amber-50 text-amber-700' },
              { label: 'Admins', value: stats?.users?.admins ?? 0, color: 'bg-purple-50 text-purple-700' },
              { label: 'Total', value: stats?.users?.total ?? 0, color: 'bg-gray-50 text-gray-700' },
            ].map((item) => (
              <div key={item.label} className={`rounded-2xl p-5 ${item.color}`}>
                <div className="text-3xl font-black">{item.value}</div>
                <div className="text-sm font-semibold mt-1">{item.label}</div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
