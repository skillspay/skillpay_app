'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

export default function UsersControl() {
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
        return <Badge className="bg-green-100 text-green-800 border-none font-semibold">Active</Badge>;
      case 'SUSPENDED':
        return <Badge className="bg-amber-100 text-amber-800 border-none font-semibold">Suspended</Badge>;
      case 'BANNED':
        return <Badge className="bg-red-100 text-red-800 border-none font-semibold">Banned</Badge>;
      default:
        return <Badge className="bg-gray-100 text-gray-800 border-none font-semibold">{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Users Control Center</h1>
        <p className="text-gray-500 mt-1">Manage user roles, statuses, and login permissions.</p>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader className="pb-2">
          <Tabs
            defaultValue="ALL"
            onValueChange={(val) => {
              setRoleFilter(val);
              setPage(1);
            }}
          >
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg font-bold text-gray-900">User List</CardTitle>
              <TabsList className="bg-gray-100 p-1 rounded-xl">
                <TabsTrigger value="ALL" className="rounded-lg text-sm px-3 py-1.5 font-medium">All Users</TabsTrigger>
                <TabsTrigger value="HOMEOWNER" className="rounded-lg text-sm px-3 py-1.5 font-medium">Homeowners</TabsTrigger>
                <TabsTrigger value="ARTISAN" className="rounded-lg text-sm px-3 py-1.5 font-medium">Artisans</TabsTrigger>
                <TabsTrigger value="ADMIN" className="rounded-lg text-sm px-3 py-1.5 font-medium">Admins</TabsTrigger>
              </TabsList>
            </div>
          </Tabs>
        </CardHeader>
        <CardContent>
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
              <div className="border border-gray-100 rounded-xl overflow-hidden">
                <Table>
                  <TableHeader className="bg-gray-50">
                    <TableRow>
                      <TableHead className="font-bold text-gray-700">Email / ID</TableHead>
                      <TableHead className="font-bold text-gray-700">Full Name</TableHead>
                      <TableHead className="font-bold text-gray-700">Role</TableHead>
                      <TableHead className="font-bold text-gray-700">Status</TableHead>
                      <TableHead className="font-bold text-gray-700 text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {users.map((u) => (
                      <TableRow key={u.id} className="hover:bg-gray-50/50">
                        <TableCell>
                          <div className="font-medium text-gray-900">{u.email}</div>
                          <div className="text-[10px] text-gray-400 font-mono mt-0.5">{u.id}</div>
                        </TableCell>
                        <TableCell className="font-medium text-gray-700">
                          {u.role === 'HOMEOWNER' ? u.homeowner?.fullName : u.artisan?.fullName || 'N/A'}
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline" className="font-semibold">{u.role}</Badge>
                        </TableCell>
                        <TableCell>{getStatusBadge(u.status)}</TableCell>
                        <TableCell className="text-right space-x-2">
                          {u.status === 'ACTIVE' ? (
                            <>
                              <Button
                                size="sm"
                                variant="outline"
                                className="text-amber-600 border-amber-200 hover:bg-amber-50 rounded-lg"
                                onClick={() => handleAction(u.id, 'suspend')}
                              >
                                Suspend
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                className="text-red-600 border-red-200 hover:bg-red-50 rounded-lg"
                                onClick={() => handleAction(u.id, 'ban')}
                              >
                                Ban
                              </Button>
                            </>
                          ) : (
                            <Button
                              size="sm"
                              className="bg-green-600 hover:bg-green-700 text-white rounded-lg"
                              onClick={() => handleAction(u.id, 'activate')}
                            >
                              Activate
                            </Button>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Pagination controls */}
              <div className="flex justify-between items-center pt-2">
                <p className="text-sm text-gray-500 font-medium">Page {page} of {totalPages}</p>
                <div className="space-x-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="rounded-lg"
                    disabled={page <= 1}
                    onClick={() => setPage(page - 1)}
                  >
                    Previous
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    className="rounded-lg"
                    disabled={page >= totalPages}
                    onClick={() => setPage(page + 1)}
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
