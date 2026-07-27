'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function UsersControl() {
  const router = useRouter();
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [roleFilter, setRoleFilter] = useState<string>('ALL');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const role = roleFilter === 'ALL' ? undefined : roleFilter;
      const res = await api.users.list(page, 10, role);
      setUsers(res.data || []);
      setTotalPages(res.meta?.totalPages || 1);
    } catch (err) {
      console.error('Error fetching users', err);
    } finally {
      setLoading(false);
    }
  }, [roleFilter, page]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleAction = async (id: string, action: 'suspend' | 'ban' | 'activate') => {
    try {
      if (action === 'suspend') await api.users.suspend(id);
      else if (action === 'ban') await api.users.ban(id);
      else if (action === 'activate') await api.users.activate(id);
      fetchUsers(); // reload list
    } catch (err) {
      console.error(`Failed to perform action ${action} on user ${id}`, err);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'ACTIVE':
        return <span className="px-2 py-0.5 rounded border border-green-400 text-[10px] font-bold text-green-600 uppercase">Active</span>;
      case 'SUSPENDED':
        return <span className="px-2 py-0.5 rounded border border-amber-400 text-[10px] font-bold text-amber-600 uppercase">Suspended</span>;
      case 'BANNED':
        return <span className="px-2 py-0.5 rounded border border-red-400 text-[10px] font-bold text-red-600 uppercase">Banned</span>;
      default:
        return <span className="px-2 py-0.5 rounded border border-gray-300 text-[10px] font-bold text-gray-500 uppercase">{status}</span>;
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Tabs Header */}
      <div className="flex items-center gap-6 px-6 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900 py-4 mr-4">Users List</h2>
        
        <div className="flex items-center gap-6">
          <button 
            onClick={() => { setRoleFilter('ALL'); setPage(1); }}
            className={`py-4 text-[13px] font-semibold border-b-2 transition-colors ${roleFilter === 'ALL' ? 'border-amber-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            All Users
          </button>
          <button 
            onClick={() => { setRoleFilter('HOMEOWNER'); setPage(1); }}
            className={`py-4 text-[13px] font-semibold border-b-2 transition-colors ${roleFilter === 'HOMEOWNER' ? 'border-amber-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            Homeowners
          </button>
          <button 
            onClick={() => { setRoleFilter('ARTISAN'); setPage(1); }}
            className={`py-4 text-[13px] font-semibold border-b-2 transition-colors ${roleFilter === 'ARTISAN' ? 'border-amber-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            Artisans
          </button>
          <button 
            onClick={() => { setRoleFilter('ADMIN'); setPage(1); }}
            className={`py-4 text-[13px] font-semibold border-b-2 transition-colors ${roleFilter === 'ADMIN' ? 'border-amber-500 text-gray-900' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            Admins
          </button>
        </div>
      </div>

      {/* Table Control Bar */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2 text-gray-600 hover:text-gray-900 cursor-pointer">
            <Search size={16} />
            <span className="text-[13px] font-medium">Search</span>
          </div>
          <div className="flex items-center gap-2 text-gray-600 hover:text-gray-900 cursor-pointer">
            <Filter size={16} />
            <span className="text-[13px] font-medium">Filters</span>
          </div>
          <div className="flex items-center gap-2 text-gray-600 hover:text-gray-900 cursor-pointer">
            <GripHorizontal size={16} />
            <span className="text-[13px] font-medium">Group by</span>
          </div>
        </div>
        
        <button className="flex items-center gap-2 bg-amber-500 hover:bg-amber-600 text-white px-4 py-2 rounded shadow-sm transition-colors text-[13px] font-semibold">
          <Plus size={16} />
          Add User
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 p-0 overflow-auto">
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
            </div>
          ) : users.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No users found matching the filter.
            </div>
          ) : (
            <div className="space-y-4">
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Email / ID <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Full Name</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Role</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {users.map((u) => (
                    <TableRow 
                      key={u.id} 
                      className="hover:bg-gray-50 border-b border-gray-50 cursor-pointer"
                      onClick={() => router.push(`/dashboard/users/${u.id}`)}
                    >
                      <TableCell className="px-6" onClick={(e) => e.stopPropagation()}><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell>
                        <div className="text-[13px] font-medium text-gray-900">{u.email}</div>
                        <div className="text-[10px] text-gray-400 font-mono">{u.id}</div>
                      </TableCell>
                      <TableCell className="text-[13px] font-medium text-gray-700">
                        <div className="flex items-center gap-2">
                          {u.role === 'HOMEOWNER' ? u.homeowner?.fullName : u.artisan?.fullName || 'N/A'}
                          {u.isVerified && (
                            <svg className="w-3.5 h-3.5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                            </svg>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-[12px] text-gray-600">{u.role}</span>
                      </TableCell>
                      <TableCell>{getStatusBadge(u.status)}</TableCell>
                      <TableCell className="text-right pr-6" onClick={(e) => e.stopPropagation()}>
                        <div className="flex items-center justify-end gap-3">
                          {/* Simplified actions for tabular view */}
                          {u.status === 'ACTIVE' ? (
                            <button 
                              className="w-8 h-4 rounded-full bg-amber-500 flex items-center p-0.5 justify-end"
                              onClick={() => handleAction(u.id, 'suspend')}
                              title="Suspend user"
                            >
                              <div className="w-3 h-3 bg-white rounded-full"></div>
                            </button>
                          ) : (
                            <button 
                              className="w-8 h-4 rounded-full bg-gray-200 flex items-center p-0.5"
                              onClick={() => handleAction(u.id, 'activate')}
                              title="Activate user"
                            >
                              <div className="w-3 h-3 bg-white rounded-full"></div>
                            </button>
                          )}
                          <button className="text-gray-400 hover:text-gray-600">
                            <MoreVertical size={16} />
                          </button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>

            {/* Pagination controls */}
            <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
              <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{users.length}</span> of 50</p>
              
              <div className="flex items-center gap-1">
                <button 
                  className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50"
                  disabled={page <= 1}
                  onClick={() => setPage(page - 1)}
                >
                  &lt;
                </button>
                {Array.from({ length: totalPages }).map((_, i) => {
                  const p = i + 1;
                  return (
                    <button 
                      key={p}
                      onClick={() => setPage(p)}
                      className={`w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium transition-colors ${
                        page === p ? 'bg-amber-500 text-white' : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900'
                      }`}
                    >
                      {p}
                    </button>
                  );
                })}
                <button 
                  className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50"
                  disabled={page >= totalPages}
                  onClick={() => setPage(page + 1)}
                >
                  &gt;
                </button>
              </div>
            </div>
            </div>
          )}
      </div>
    </div>
  );
}
