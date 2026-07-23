'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';

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
        return <Badge className="bg-blue-100 text-blue-800 border-none font-semibold">Confirmed</Badge>;
      case 'IN_PROGRESS':
        return <Badge className="bg-amber-100 text-amber-800 border-none font-semibold">In Progress</Badge>;
      case 'COMPLETED':
        return <Badge className="bg-green-100 text-green-800 border-none font-semibold">Completed</Badge>;
      case 'CANCELLED':
        return <Badge className="bg-red-100 text-red-800 border-none font-semibold">Cancelled</Badge>;
      case 'DISPUTED':
        return <Badge className="bg-purple-100 text-purple-800 border-none font-semibold">Disputed</Badge>;
      default:
        return <Badge className="bg-gray-100 text-gray-800 border-none font-semibold">{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Bookings & Jobs</h1>
        <p className="text-gray-500 mt-1">Review active work contracts, agreements, and execution logs.</p>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Platform Bookings</CardTitle>
        </CardHeader>
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
            <div className="border border-gray-100 rounded-xl overflow-hidden">
              <Table>
                <TableHeader className="bg-gray-50">
                  <TableRow>
                    <TableHead className="font-bold text-gray-700">Booking ID</TableHead>
                    <TableHead className="font-bold text-gray-700">Homeowner</TableHead>
                    <TableHead className="font-bold text-gray-700">Artisan</TableHead>
                    <TableHead className="font-bold text-gray-700">Date Initiated</TableHead>
                    <TableHead className="font-bold text-gray-700">Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {bookings.map((b) => (
                    <TableRow key={b.id} className="hover:bg-gray-50/50">
                      <TableCell className="font-mono text-xs font-semibold text-gray-900">{b.id}</TableCell>
                      <TableCell className="font-medium text-gray-700">
                        {b.homeowner?.fullName}
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{b.homeowner?.id}</div>
                      </TableCell>
                      <TableCell className="font-medium text-gray-700">
                        {b.artisan?.fullName}
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{b.artisan?.id}</div>
                      </TableCell>
                      <TableCell className="text-gray-600 font-medium">
                        {new Date(b.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>{getStatusBadge(b.status)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
