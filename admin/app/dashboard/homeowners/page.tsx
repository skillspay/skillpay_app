'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { request } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export default function HomeownersPage() {
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
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Homeowners</h1>
        <p className="text-gray-500 mt-1">Browse all registered homeowners on the platform.</p>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Homeowner Directory</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin" />
            </div>
          ) : homeowners.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">No homeowners found.</div>
          ) : (
            <div className="space-y-4">
              <div className="border border-gray-100 rounded-xl overflow-hidden">
                <Table>
                  <TableHeader className="bg-gray-50">
                    <TableRow>
                      <TableHead className="font-bold text-gray-700">Full Name</TableHead>
                      <TableHead className="font-bold text-gray-700">Email</TableHead>
                      <TableHead className="font-bold text-gray-700">Phone</TableHead>
                      <TableHead className="font-bold text-gray-700">Default Address</TableHead>
                      <TableHead className="font-bold text-gray-700">Status</TableHead>
                      <TableHead className="font-bold text-gray-700">Joined</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {homeowners.map((u) => (
                      <TableRow key={u.id} className="hover:bg-gray-50/50">
                        <TableCell className="font-semibold text-gray-900">
                          {u.homeowner?.fullName || '—'}
                        </TableCell>
                        <TableCell className="text-gray-700 font-medium">{u.email}</TableCell>
                        <TableCell className="text-gray-600">{u.phone || '—'}</TableCell>
                        <TableCell className="text-gray-600 max-w-xs truncate">
                          {u.homeowner?.defaultAddress || '—'}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={
                              u.status === 'ACTIVE'
                                ? 'bg-green-100 text-green-800 border-none font-semibold'
                                : 'bg-red-100 text-red-800 border-none font-semibold'
                            }
                          >
                            {u.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-gray-500 text-sm">
                          {new Date(u.createdAt).toLocaleDateString()}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              <div className="flex justify-between items-center pt-2">
                <p className="text-sm text-gray-500 font-medium">
                  Page {page} of {totalPages}
                </p>
                <div className="space-x-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="rounded-lg"
                    disabled={page <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    Previous
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="rounded-lg"
                    disabled={page >= totalPages}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
