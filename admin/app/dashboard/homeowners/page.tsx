'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { request } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function HomeownersPage() {
  const router = useRouter();
  const [homeowners, setHomeowners] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const fetchHomeowners = useCallback(async () => {
    setLoading(true);
    try {
      const res = await request(`/users?role=HOMEOWNER&page=${page}&limit=15`);
      setHomeowners(res?.data || []);
      setTotalPages(res?.meta?.totalPages || 1);
    } catch (err) {
      console.error('Failed to load homeowners', err);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    fetchHomeowners();
  }, [fetchHomeowners]);

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Homeowners</h2>
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
        
        <Button className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-9 px-4 text-[13px]">
          <Plus size={16} className="mr-2" />
          Export Data
        </Button>
      </div>

      {/* Main Content */}
      <div className="flex-1 p-0 overflow-auto">
        <CardContent>
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin" />
            </div>
          ) : homeowners.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">No homeowners found.</div>
          ) : (
            <>
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Full Name <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Email / Phone</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Default Address</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Joined</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {homeowners.map((u) => (
                    <TableRow 
                      key={u.id} 
                      className="hover:bg-gray-50 border-b border-gray-50 cursor-pointer"
                      onClick={() => router.push(`/dashboard/users/${u.id}`)}
                    >
                      <TableCell className="px-6" onClick={(e) => e.stopPropagation()}><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell className="font-semibold text-[13px] text-gray-900">
                        <div className="flex items-center gap-2">
                          {u.homeowner?.fullName || '—'}
                          {u.isVerified && (
                            <svg className="w-3.5 h-3.5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                            </svg>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="text-[13px] text-gray-700 font-medium">{u.email}</div>
                        <div className="text-[11px] text-gray-500">{u.phone || '—'}</div>
                      </TableCell>
                      <TableCell className="text-[13px] text-gray-600 max-w-[200px] truncate">
                        {u.homeowner?.defaultAddress || '—'}
                      </TableCell>
                      <TableCell>
                        <span className={`px-2 py-0.5 rounded border text-[10px] font-bold uppercase ${
                          u.status === 'ACTIVE'
                            ? 'border-green-400 text-green-600'
                            : 'border-red-400 text-red-600'
                        }`}>
                          {u.status}
                        </span>
                      </TableCell>
                      <TableCell className="text-gray-500 text-[12px]">
                        {new Date(u.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right pr-6" onClick={(e) => e.stopPropagation()}>
                        <button className="text-gray-400 hover:text-gray-600">
                          <MoreVertical size={16} />
                        </button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
              <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
                <p className="text-[13px] text-gray-500">
                  Showing <span className="font-medium text-gray-900">{homeowners.length}</span> results
                </p>
                <div className="flex items-center gap-1">
                  <button
                    className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50"
                    disabled={page <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    &lt;
                  </button>
                  <button className="w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium bg-amber-500 text-white">
                    {page}
                  </button>
                  <button
                    className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50"
                    disabled={page >= totalPages}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    &gt;
                  </button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </div>
    </div>
  );
}
