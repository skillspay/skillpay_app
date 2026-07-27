'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';
import { Button } from '@/components/ui/button';

export default function BookingsOverview() {
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadBookings() {
      try {
        const res = await api.bookings.list();
        setBookings(res || []);
      } catch (err) {
        console.error('Failed to load bookings', err);
      } finally {
        setLoading(false);
      }
    }
    loadBookings();
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return <span className="px-2 py-0.5 rounded border border-blue-400 text-[10px] font-bold text-blue-600 uppercase">Confirmed</span>;
      case 'IN_PROGRESS':
        return <span className="px-2 py-0.5 rounded border border-amber-400 text-[10px] font-bold text-amber-600 uppercase">In Progress</span>;
      case 'COMPLETED':
        return <span className="px-2 py-0.5 rounded border border-green-400 text-[10px] font-bold text-green-600 uppercase">Completed</span>;
      case 'CANCELLED':
        return <span className="px-2 py-0.5 rounded border border-red-400 text-[10px] font-bold text-red-600 uppercase">Cancelled</span>;
      case 'DISPUTED':
        return <span className="px-2 py-0.5 rounded border border-purple-400 text-[10px] font-bold text-purple-600 uppercase">Disputed</span>;
      default:
        return <span className="px-2 py-0.5 rounded border border-gray-300 text-[10px] font-bold text-gray-500 uppercase">{status}</span>;
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Bookings & Jobs</h2>
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
          Export Bookings
        </Button>
      </div>
      {/* Main Content */}
      <div className="flex-1 p-0 overflow-auto">
        <CardContent>
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
            </div>
          ) : bookings.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No bookings active in the system yet.
            </div>
          ) : (
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Booking ID <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Homeowner</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Artisan</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Date Initiated</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {bookings.map((b) => (
                    <TableRow key={b.id} className="hover:bg-gray-50 border-b border-gray-50">
                      <TableCell className="px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell className="font-mono text-[11px] font-medium text-gray-900">{b.id}</TableCell>
                      <TableCell>
                        <div className="text-[13px] font-medium text-gray-900">{b.homeowner?.fullName}</div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{b.homeowner?.id}</div>
                      </TableCell>
                      <TableCell>
                        <div className="text-[13px] font-medium text-gray-900">{b.artisan?.fullName}</div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{b.artisan?.id}</div>
                      </TableCell>
                      <TableCell className="text-[13px] text-gray-600 font-medium">
                        {new Date(b.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>{getStatusBadge(b.status)}</TableCell>
                      <TableCell className="text-right pr-6">
                        <button className="text-gray-400 hover:text-gray-600">
                          <MoreVertical size={16} />
                        </button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </div>

      {/* Pagination */}
      <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
        <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{bookings.length}</span> of {bookings.length}</p>
        <div className="flex items-center gap-1">
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&lt;</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium bg-amber-500 text-white">1</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&gt;</button>
        </div>
      </div>
    </div>
  );
}
