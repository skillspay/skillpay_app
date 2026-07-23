'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';

export default function CategoriesControl() {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [icon, setIcon] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const res = await api.categories.list();
      setCategories(res || []);
    } catch (err) {
      console.error('Failed to load categories', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    try {
      await api.categories.create({ name, description, icon });
      setName('');
      setDescription('');
      setIcon('');
      setDialogOpen(false);
      fetchCategories();
    } catch (err) {
      console.error('Failed to create category', err);
    }
  };

  const handleToggleActive = async (id: string, currentStatus: boolean) => {
    try {
      await api.categories.update(id, { isActive: !currentStatus });
      fetchCategories();
    } catch (err) {
      console.error('Failed to update category', err);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Service Categories</h1>
          <p className="text-gray-500 mt-1">Manage categories available for job postings and artisan listings.</p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger>
            <Button className="bg-amber-400 hover:bg-amber-500 text-white rounded-xl shadow-md font-bold">
              Add Service Category
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md rounded-2xl bg-white border border-gray-100 p-6">
            <DialogHeader>
              <DialogTitle className="text-xl font-bold text-gray-900">New Category</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleCreate} className="space-y-4 my-4">
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Category Name</label>
                <Input
                  required
                  placeholder="e.g. Plumber, Electrician"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300"
                />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Description</label>
                <Input
                  placeholder="Service description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300"
                />
              </div>
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Icon Tag / Unicode</label>
                <Input
                  placeholder="e.g. build, electrical_services"
                  value={icon}
                  onChange={(e) => setIcon(e.target.value)}
                  className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300"
                />
              </div>
              <DialogFooter className="pt-4">
                <Button
                  type="submit"
                  className="w-full bg-amber-400 hover:bg-amber-500 text-white font-bold h-11 rounded-xl"
                >
                  Create Category
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Category Directory</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
            </div>
          ) : categories.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No categories configured yet.
            </div>
          ) : (
            <div className="border border-gray-100 rounded-xl overflow-hidden">
              <Table>
                <TableHeader className="bg-gray-50">
                  <TableRow>
                    <TableHead className="font-bold text-gray-700">Name</TableHead>
                    <TableHead className="font-bold text-gray-700">Description</TableHead>
                    <TableHead className="font-bold text-gray-700">Icon</TableHead>
                    <TableHead className="font-bold text-gray-700">Status</TableHead>
                    <TableHead className="font-bold text-gray-700 text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {categories.map((c) => (
                    <TableRow key={c.id} className="hover:bg-gray-50/50">
                      <TableCell className="font-semibold text-gray-900">{c.name}</TableCell>
                      <TableCell className="text-gray-600 font-medium">{c.description || '—'}</TableCell>
                      <TableCell className="font-mono text-xs text-gray-400">{c.icon || '—'}</TableCell>
                      <TableCell>
                        {c.isActive ? (
                          <Badge className="bg-green-100 text-green-800 border-none font-semibold">Active</Badge>
                        ) : (
                          <Badge className="bg-gray-100 text-gray-500 border-none font-semibold">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          variant="outline"
                          className={`${
                            c.isActive
                              ? 'text-red-600 border-red-200 hover:bg-red-50'
                              : 'text-green-600 border-green-200 hover:bg-green-50'
                          } rounded-lg font-semibold`}
                          onClick={() => handleToggleActive(c.id, c.isActive)}
                        >
                          {c.isActive ? 'Deactivate' : 'Activate'}
                        </Button>
                      </TableCell>
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
