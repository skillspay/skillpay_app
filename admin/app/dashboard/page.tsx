'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Users, ShieldAlert, Award, FileText } from 'lucide-react';
import Link from 'next/link';

export default function DashboardOverview() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadStats() {
      try {
        const userStats = await api.users.getStats();
        setStats(userStats);
      } catch (err) {
        console.error('Failed to load dashboard stats', err);
      } finally {
        setLoading(false);
      }
    }
    loadStats();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Platform Users',
      value: stats?.total ?? 0,
      description: 'Total accounts registered in system',
      icon: Users,
      color: 'text-blue-600 bg-blue-50',
    },
    {
      title: 'Homeowners',
      value: stats?.homeowners ?? 0,
      description: 'Active client users seeking services',
      icon: Award,
      color: 'text-green-600 bg-green-50',
    },
    {
      title: 'Artisans',
      value: stats?.artisans ?? 0,
      description: 'Skilled professionals offering services',
      icon: ShieldAlert,
      color: 'text-amber-600 bg-amber-50',
    },
    {
      title: 'Admins & Managers',
      value: stats?.admins ?? 0,
      description: 'Admin portal access accounts',
      icon: FileText,
      color: 'text-purple-600 bg-purple-50',
    },
  ];

  return (
    <div className="space-y-8">
      {/* Welcome banner */}
      <div>
        <h1 className="text-3xl font-extrabold tracking-tight text-gray-900">Dashboard Overview</h1>
        <p className="text-gray-500 mt-1">Real-time statistics and system logs for the Skillpay platform.</p>
      </div>

      {/* Grid of stats */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <Card key={card.title} className="border-gray-200 shadow-sm rounded-2xl bg-white hover:shadow-md transition-shadow duration-200">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-semibold text-gray-500 uppercase tracking-wider">{card.title}</CardTitle>
                <div className={`p-2.5 rounded-xl ${card.color}`}>
                  <Icon size={20} />
                </div>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-black text-gray-900">{card.value}</div>
                <p className="text-xs text-gray-400 mt-1">{card.description}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Quick shortcuts & System status */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Quick actions */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Administrative Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Link href="/dashboard/artisans" className="p-4 rounded-xl border border-gray-200 hover:border-amber-400 hover:bg-amber-50/20 transition-all text-center block">
                <p className="font-semibold text-gray-900">Verify Artisans</p>
                <p className="text-xs text-gray-400 mt-1">Review credentials & IDs</p>
              </Link>
              <Link href="/dashboard/categories" className="p-4 rounded-xl border border-gray-200 hover:border-amber-400 hover:bg-amber-50/20 transition-all text-center block">
                <p className="font-semibold text-gray-900">Manage Categories</p>
                <p className="text-xs text-gray-400 mt-1">Add or edit services</p>
              </Link>
              <Link href="/dashboard/users" className="p-4 rounded-xl border border-gray-200 hover:border-amber-400 hover:bg-amber-50/20 transition-all text-center block">
                <p className="font-semibold text-gray-900">User Moderation</p>
                <p className="text-xs text-gray-400 mt-1">Suspend/Activate accounts</p>
              </Link>
              <Link href="/dashboard/reports" className="p-4 rounded-xl border border-gray-200 hover:border-amber-400 hover:bg-amber-50/20 transition-all text-center block">
                <p className="font-semibold text-gray-900">Dispute Center</p>
                <p className="text-xs text-gray-400 mt-1">Resolve user reports</p>
              </Link>
            </div>
          </CardContent>
        </Card>

        {/* Status table */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Account Distribution Status</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between items-center py-2 border-b border-gray-100">
              <span className="font-medium text-gray-600">Active Accounts</span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-green-100 text-green-800">{stats?.active ?? 0}</span>
            </div>
            <div className="flex justify-between items-center py-2 border-b border-gray-100">
              <span className="font-medium text-gray-600">Suspended Accounts</span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800">{stats?.suspended ?? 0}</span>
            </div>
            <div className="flex justify-between items-center py-2">
              <span className="font-medium text-gray-600">Banned Accounts</span>
              <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-red-100 text-red-800">{stats?.banned ?? 0}</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
