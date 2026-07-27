'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { supabase } from '../../lib/supabase';
import { api } from '../../lib/api';
import Link from 'next/link';
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
  Search,
  Moon,
} from 'lucide-react';

const navGroups = [
  {
    title: 'MAIN',
    items: [
      { name: 'Dashboard', href: '/dashboard', icon: FolderOpen },
      { name: 'Analytics', href: '/dashboard/analytics', icon: BarChart2 },
    ]
  },
  {
    title: 'USERS & ROLES',
    items: [
      { name: 'Users Control', href: '/dashboard/users', icon: Users },
      { name: 'Homeowners', href: '/dashboard/homeowners', icon: Home },
      { name: 'Artisans', href: '/dashboard/artisans', icon: ShieldCheck },
    ]
  },
  {
    title: 'OPERATIONS & SERVICES',
    items: [
      { name: 'Categories', href: '/dashboard/categories', icon: Layers },
      { name: 'Bookings', href: '/dashboard/bookings', icon: Briefcase },
    ]
  },
  {
    title: 'FINANCIALS',
    items: [
      { name: 'Payments', href: '/dashboard/payments', icon: DollarSign },
    ]
  },
  {
    title: 'SYSTEM & SUPPORT',
    items: [
      { name: 'Reports', href: '/dashboard/reports', icon: AlertOctagon },
      { name: 'Notifications', href: '/dashboard/notifications', icon: Bell },
      { name: 'Settings', href: '/dashboard/settings', icon: Settings },
    ]
  },
];

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
        await supabase.auth.signOut();
        router.push('/');
      }
    }

    checkUser();
    return () => { active = false; };
  }, [router]);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/');
  };

  const getPageTitle = () => {
    if (pathname === '/dashboard') return 'Overview';
    for (const group of navGroups) {
      for (const item of group.items) {
        if (pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href))) {
          return item.name;
        }
      }
    }
    return 'Overview';
  };

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
    <div className="h-screen w-full flex bg-gray-50 overflow-hidden font-sans">
      {/* Sidebar for Desktop */}
      <aside className="hidden md:flex flex-col w-[260px] bg-slate-900 text-white shrink-0 shadow-xl border-r border-slate-800 z-20">
        <div className="h-16 flex items-center px-6 bg-slate-950 gap-3 border-b border-slate-800">
          <div className="w-8 h-8 flex items-center justify-center">
            <img src="/logo.png" alt="Skillpay Logo" className="w-full h-full object-contain" />
          </div>
          <span className="font-bold text-lg tracking-wide text-white">Skillpay</span>
        </div>
        
        <div className="flex-1 overflow-y-auto py-6 px-4 space-y-8 scrollbar-hide">
          {navGroups.map(group => (
            <div key={group.title}>
              <h3 className="px-3 text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-3">
                {group.title}
              </h3>
              <nav className="space-y-1">
                {group.items.map(item => {
                  const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={`flex items-center space-x-3 px-3 py-2.5 rounded-lg transition-colors text-sm ${
                        isActive
                          ? 'bg-amber-400 text-slate-950 font-semibold shadow-sm'
                          : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                      }`}
                    >
                      <item.icon size={18} className={isActive ? 'text-slate-900' : ''} />
                      <span>{item.name}</span>
                    </Link>
                  );
                })}
              </nav>
            </div>
          ))}
        </div>
      </aside>

      {/* Main Content wrapper */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 md:px-8 z-10 shadow-sm">
          <div className="flex items-center gap-4">
            <button onClick={() => setMobileMenuOpen(true)} className="md:hidden text-gray-500 hover:text-gray-700">
              <Menu size={24} />
            </button>
            <h1 className="text-xl font-semibold text-gray-800 hidden md:block tracking-tight">
              {getPageTitle()}
            </h1>
          </div>

          <div className="flex-1 max-w-lg mx-6 hidden md:flex items-center relative">
            <Search className="w-4 h-4 text-gray-400 absolute left-3" />
            <input 
              type="text" 
              placeholder="Search..." 
              className="w-full bg-gray-50/50 border border-gray-200 rounded-lg pl-10 pr-12 py-2 text-sm focus:outline-none focus:border-amber-400 focus:ring-1 focus:ring-amber-400 transition-all text-gray-700 placeholder:text-gray-400" 
            />
            <div className="absolute right-2 flex items-center justify-center border border-gray-200 rounded px-1.5 py-0.5 bg-white text-gray-400 text-[10px] font-mono shadow-sm">
              ⌘K
            </div>
          </div>

          <div className="flex items-center gap-3 md:gap-5 shrink-0">
            <div className="hidden sm:flex items-center gap-2">
              <button className="text-gray-400 hover:text-gray-700 w-9 h-9 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                <Settings size={20} />
              </button>
              <button className="text-gray-400 hover:text-gray-700 w-9 h-9 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors relative">
                <Bell size={20} />
                <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-[1.5px] border-white"></span>
              </button>
              <button className="text-gray-400 hover:text-gray-700 w-9 h-9 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                <Moon size={20} />
              </button>
            </div>
            
            <div className="h-6 w-px bg-gray-200 hidden sm:block"></div>

            {/* Profile Chip */}
            <div 
              className="flex items-center gap-3 bg-gray-50 py-1 px-1.5 md:pr-4 rounded-full border border-gray-200 cursor-pointer hover:bg-gray-100 transition-colors group"
              onClick={handleLogout}
              title="Click to logout"
            >
              <div className="w-8 h-8 rounded-full bg-amber-400 flex items-center justify-center text-slate-950 font-bold text-sm shrink-0 shadow-sm">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </div>
              <div className="hidden lg:flex flex-col items-start justify-center">
                <span className="text-[13px] font-semibold text-gray-800 leading-tight group-hover:text-amber-600 transition-colors">
                  {user?.email?.split('@')[0] || 'Admin User'}
                </span>
                <span className="text-[10px] text-gray-500 font-medium tracking-wide">Personal manager</span>
              </div>
            </div>
          </div>
        </header>

        {/* Main scrollable area */}
        <main className="flex-1 overflow-auto bg-gray-50 p-4 md:p-8">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm flex">
          <div className="w-[260px] bg-slate-900 h-full flex flex-col shadow-2xl">
            <div className="h-16 flex items-center justify-between px-6 bg-slate-950 border-b border-slate-800">
              <span className="font-bold tracking-wide text-white">Skillpay Menu</span>
              <button onClick={() => setMobileMenuOpen(false)} className="text-gray-400 hover:text-white">
                <X size={24} />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto py-6 px-4 space-y-6">
              {navGroups.map(group => (
                <div key={group.title}>
                  <h3 className="px-3 text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-3">
                    {group.title}
                  </h3>
                  <nav className="space-y-1">
                    {group.items.map(item => {
                      const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
                      return (
                        <Link
                          key={item.name}
                          href={item.href}
                          onClick={() => setMobileMenuOpen(false)}
                          className={`flex items-center space-x-3 px-3 py-2.5 rounded-lg transition-colors text-sm ${
                            isActive
                              ? 'bg-amber-400 text-slate-950 font-semibold'
                              : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                          }`}
                        >
                          <item.icon size={18} />
                          <span>{item.name}</span>
                        </Link>
                      );
                    })}
                  </nav>
                </div>
              ))}
              <div className="pt-4 border-t border-slate-800 mt-6">
                <button
                  onClick={handleLogout}
                  className="flex items-center space-x-3 px-3 py-2.5 w-full text-red-400 hover:bg-red-500/10 hover:text-red-300 rounded-lg transition-colors text-sm"
                >
                  <LogOut size={18} />
                  <span>Sign Out</span>
                </button>
              </div>
            </div>
          </div>
          <div className="flex-1" onClick={() => setMobileMenuOpen(false)}></div>
        </div>
      )}
    </div>
  );
}
