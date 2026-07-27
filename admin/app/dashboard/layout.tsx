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
  ChevronRight,
  ChevronDown,
  Plus,
  ChevronLeft,
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
      <aside className="hidden md:flex flex-col w-[260px] bg-white text-gray-700 shrink-0 border-r border-gray-200 z-20">
        {/* Profile Header */}
        <div className="p-4 border-b border-gray-100 flex items-center justify-between cursor-pointer group">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-black text-white flex items-center justify-center font-bold text-lg shadow-sm">
              <span>S</span>
            </div>
            <div className="flex flex-col">
              <h1 className="font-bold text-sm tracking-tight text-gray-900 group-hover:text-amber-600 transition-colors">
                helpdesk
              </h1>
              <p className="text-[11px] text-gray-500 font-medium">skillspays.com</p>
            </div>
          </div>
          <ChevronRight size={16} className="text-gray-400 group-hover:text-amber-500 transition-colors" />
        </div>
        
        <div className="flex-1 overflow-y-auto py-5 px-3 space-y-5 scrollbar-hide">
          {navGroups.map(group => (
            <div key={group.title}>
              <h3 className="px-3 text-[11px] font-semibold text-gray-400 uppercase tracking-wider mb-2 flex items-center gap-2">
                {group.title}
              </h3>
              <nav className="space-y-0.5">
                {group.items.map(item => {
                  const isActive = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={`flex items-center justify-between px-3 py-2 rounded-lg transition-colors text-[14px] font-medium ${
                        isActive
                          ? 'bg-amber-50 text-amber-600'
                          : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <item.icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                        <span>{item.name}</span>
                      </div>
                      <ChevronRight size={14} className={isActive ? 'text-amber-500' : 'text-gray-400 opacity-0 group-hover:opacity-100'} />
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
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-4 z-10">
          <div className="flex items-center gap-4">
            <button className="hidden md:flex items-center justify-center w-8 h-8 rounded-full border border-gray-200 text-gray-500 hover:bg-gray-50 hover:text-gray-800 transition-colors shrink-0">
              <ChevronLeft size={16} />
            </button>
            <button onClick={() => setMobileMenuOpen(true)} className="md:hidden text-gray-500 hover:text-gray-700">
              <Menu size={24} />
            </button>
            
            <div className="flex items-center relative w-64 md:w-80">
              <Search className="w-4 h-4 text-gray-400 absolute left-3" />
              <input 
                type="text" 
                placeholder="Search" 
                className="w-full bg-white border-none focus:ring-0 pl-10 py-2 text-sm text-gray-700 placeholder:text-gray-400" 
              />
            </div>
          </div>

          <div className="flex items-center gap-5 shrink-0 pr-4">
            <div className="hidden md:flex items-center gap-1 text-sm font-medium text-gray-600 cursor-pointer hover:text-gray-900">
              EN <ChevronDown size={14} className="ml-0.5" />
            </div>
            <button className="text-gray-400 hover:text-gray-700 w-8 h-8 flex items-center justify-center rounded border border-gray-200 hover:bg-gray-50 transition-colors">
              <Plus size={16} />
            </button>
            <button className="text-gray-400 hover:text-gray-700 w-8 h-8 flex items-center justify-center rounded hover:bg-gray-50 transition-colors relative">
              <Bell size={18} />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-amber-500 rounded-full border-[1.5px] border-white"></span>
            </button>

            {/* Simple Avatar Chip */}
            <div 
              className="flex items-center cursor-pointer"
              onClick={handleLogout}
              title="Click to logout"
            >
              <div className="w-8 h-8 rounded-full bg-amber-500 flex items-center justify-center text-white font-bold text-sm shadow-sm">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
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
        <div className="md:hidden fixed inset-0 z-50 bg-gray-900/40 backdrop-blur-sm flex">
          <div className="w-[260px] bg-white h-full flex flex-col shadow-2xl">
            <div className="h-16 flex items-center justify-between px-6 border-b border-gray-100">
              <span className="font-bold tracking-wide text-gray-900">Menu</span>
              <button onClick={() => setMobileMenuOpen(false)} className="text-gray-400 hover:text-gray-900">
                <X size={24} />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto py-6 px-4 space-y-6">
              {navGroups.map(group => (
                <div key={group.title}>
                  <h3 className="px-3 text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
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
                          className={`flex items-center justify-between px-3 py-2.5 rounded-lg transition-colors text-[13px] font-medium ${
                            isActive
                              ? 'bg-amber-50 text-amber-600'
                              : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <item.icon size={18} strokeWidth={isActive ? 2.5 : 2} />
                            <span>{item.name}</span>
                          </div>
                        </Link>
                      );
                    })}
                  </nav>
                </div>
              ))}
              <div className="pt-4 border-t border-gray-100 mt-6">
                <button
                  onClick={handleLogout}
                  className="flex items-center space-x-3 px-3 py-2.5 w-full text-red-500 hover:bg-red-50 hover:text-red-600 rounded-lg transition-colors text-[13px] font-medium"
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
