'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { supabase } from '../../lib/supabase';
import { api } from '../../lib/api';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import {
  Users,
  Briefcase,
  Layers,
  FolderOpen,
  DollarSign,
  AlertOctagon,
  LogOut,
  Menu,
  X,
  ShieldCheck,
  Home,
  Bell,
  BarChart2,
  Settings,
} from 'lucide-react';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    let active = true;

    async function checkUser() {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
          router.push('/');
          return;
        }

        const profile = await api.auth.getProfile();
        if (active) {
          setUser(profile);
          setLoading(false);
        }
      } catch (err) {
        console.error('Error fetching admin profile', err);
        // Clear session and redirect to login
        await supabase.auth.signOut();
        router.push('/');
      }
    }

    checkUser();

    return () => {
      active = false;
    };
  }, [router]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/');
  };

  const navItems = [
    { name: 'Dashboard Overview', href: '/dashboard', icon: FolderOpen },
    { name: 'Users Control', href: '/dashboard/users', icon: Users },
    { name: 'Homeowners', href: '/dashboard/homeowners', icon: Home },
    { name: 'Artisan Verification', href: '/dashboard/artisans', icon: ShieldCheck },
    { name: 'Service Categories', href: '/dashboard/categories', icon: Layers },
    { name: 'Bookings & Jobs', href: '/dashboard/bookings', icon: Briefcase },
    { name: 'Payments & Revenue', href: '/dashboard/payments', icon: DollarSign },
    { name: 'Disputes & Reports', href: '/dashboard/reports', icon: AlertOctagon },
    { name: 'Notifications', href: '/dashboard/notifications', icon: Bell },
    { name: 'Analytics', href: '/dashboard/analytics', icon: BarChart2 },
    { name: 'Settings', href: '/dashboard/settings', icon: Settings },
  ];

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="flex flex-col items-center space-y-4">
          <div className="w-12 h-12 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
          <p className="text-gray-600 font-semibold">Verifying secure admin session...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col md:flex-row">
      {/* Sidebar for Desktop */}
      <aside className="hidden md:flex flex-col w-64 bg-slate-900 text-white shrink-0 shadow-lg justify-between">
        <div>
          {/* Logo Header */}
          <div className="h-16 flex items-center px-6 bg-slate-950 gap-3">
            <div className="w-10 h-10 flex items-center justify-center">
              <img src="/logo.png" alt="Skillpay Logo" className="w-full h-full object-contain" />
            </div>
            <div>
              <h1 className="font-bold text-sm tracking-wide">SKILLPAY</h1>
              <p className="text-[10px] text-amber-400 font-bold uppercase tracking-wider">Admin Portal</p>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="mt-6 px-4 space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center space-x-3 px-3 py-3 rounded-xl transition-all duration-200 ${
                    isActive
                      ? 'bg-amber-400 text-slate-950 font-bold shadow-md'
                      : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                  }`}
                >
                  <Icon size={18} />
                  <span className="text-sm">{item.name}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        {/* User profile / Log out */}
        <div className="p-4 border-t border-slate-800 bg-slate-950">
          <div className="flex items-center space-x-3 mb-4">
            <div className="w-9 h-9 rounded-full bg-amber-400 flex items-center justify-center text-slate-950 font-bold text-sm">
              {user?.email?.charAt(0).toUpperCase() || 'A'}
            </div>
            <div className="overflow-hidden">
              <p className="text-xs font-semibold truncate">{user?.email}</p>
              <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wide">{user?.role}</p>
            </div>
          </div>
          <Button
            onClick={handleLogout}
            variant="outline"
            className="w-full flex items-center justify-center space-x-2 text-red-400 hover:text-white border-slate-800 hover:bg-red-600 rounded-xl transition-colors duration-200"
          >
            <LogOut size={16} />
            <span>Sign Out</span>
          </Button>
        </div>
      </aside>

      {/* Mobile Header */}
      <header className="md:hidden h-16 bg-slate-900 text-white flex items-center justify-between px-4 shadow">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 flex items-center justify-center">
            <img src="/logo.png" alt="Skillpay Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="font-bold text-sm tracking-wide">SKILLPAY</h1>
            <p className="text-[10px] text-amber-400 font-bold uppercase">Admin</p>
          </div>
        </div>
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="p-2 rounded hover:bg-slate-800 focus:outline-none"
        >
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </header>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed inset-0 z-50 bg-slate-900/90 backdrop-blur-sm flex flex-col p-6 space-y-6">
          <div className="flex justify-between items-center">
            <span className="text-white font-bold tracking-wide">Menu Navigation</span>
            <button onClick={() => setMobileMenuOpen(false)} className="text-white">
              <X size={24} />
            </button>
          </div>
          <nav className="flex-1 space-y-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                    isActive
                      ? 'bg-amber-400 text-slate-950 font-bold shadow'
                      : 'text-slate-300 hover:bg-slate-800'
                  }`}
                >
                  <Icon size={18} />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>
          <div className="border-t border-slate-800 pt-4">
            <div className="flex items-center space-x-3 mb-4">
              <div className="w-9 h-9 rounded-full bg-amber-400 flex items-center justify-center text-slate-950 font-bold">
                {user?.email?.charAt(0).toUpperCase()}
              </div>
              <p className="text-xs text-white font-semibold truncate">{user?.email}</p>
            </div>
            <Button
              onClick={handleLogout}
              className="w-full bg-red-600 hover:bg-red-700 text-white rounded-xl"
            >
              <LogOut size={16} className="mr-2" />
              Sign Out
            </Button>
          </div>
        </div>
      )}

      {/* Main Content Area */}
      <main className="flex-1 overflow-y-auto p-6 md:p-10">
        <div className="max-w-7xl mx-auto space-y-6">
          {children}
        </div>
      </main>
    </div>
  );
}
