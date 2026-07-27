'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogTrigger } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function CategoriesControl() {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [icon, setIcon] = useState('');
  const [image, setImage] = useState('');
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
      await api.categories.create({ name, description, icon, image });
      setName('');
      setDescription('');
      setIcon('');
      setImage('');
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
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Service Categories</h2>
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
        
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger>
            <Button className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-9 px-4 text-[13px]">
              <Plus size={16} className="mr-2" />
              Add Category
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
              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Image (Upload or URL)</label>
                <div className="flex gap-2">
                  <Input
                    placeholder="https://example.com/image.png"
                    value={image}
                    onChange={(e) => setImage(e.target.value)}
                    className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300 flex-1"
                  />
                  <Input
                    type="file"
                    accept="image/*"
                    onChange={async (e) => {
                      if (e.target.files && e.target.files[0]) {
                        try {
                          const res = await api.storage.uploadCategory(e.target.files[0]);
                          if (res?.url) setImage(res.url);
                        } catch (err) {
                          console.error('Failed to upload image', err);
                          alert('Failed to upload image. Does the "categories" bucket exist in Supabase?');
                        }
                      }
                    }}
                    className="w-[110px] text-xs pt-3 h-11 file:mr-2 file:py-1 file:px-2 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-amber-50 file:text-amber-700 hover:file:bg-amber-100 rounded-xl border-gray-300"
                  />
                </div>
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
      {/* Main Content */}
      <div className="flex-1 p-0 overflow-auto">
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
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 w-16">Image</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Name <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Description</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Icon</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {categories.map((c) => (
                    <TableRow key={c.id} className="hover:bg-gray-50 border-b border-gray-50">
                      <TableCell className="px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell>
                        {c.image ? (
                          <img src={c.image} alt={c.name} className="w-8 h-8 rounded-lg object-cover bg-gray-100" />
                        ) : (
                          <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center">
                            <span className="text-[10px] text-gray-400">No Img</span>
                          </div>
                        )}
                      </TableCell>
                      <TableCell className="text-[13px] font-medium text-gray-900">{c.name}</TableCell>
                      <TableCell className="text-[13px] text-gray-600 truncate max-w-[200px]">{c.description || '—'}</TableCell>
                      <TableCell className="font-mono text-[11px] text-gray-400">{c.icon || '—'}</TableCell>
                      <TableCell>
                        {c.isActive ? (
                          <span className="px-2 py-0.5 rounded border border-green-400 text-[10px] font-bold text-green-600 uppercase">Active</span>
                        ) : (
                          <span className="px-2 py-0.5 rounded border border-amber-400 text-[10px] font-bold text-amber-600 uppercase">Inactive</span>
                        )}
                      </TableCell>
                      <TableCell className="text-right pr-6">
                        <div className="flex items-center justify-end gap-3">
                          <button 
                            className={`w-8 h-4 rounded-full flex items-center p-0.5 transition-colors ${c.isActive ? 'bg-amber-500 justify-end' : 'bg-gray-200 justify-start'}`}
                            onClick={() => handleToggleActive(c.id, c.isActive)}
                            title="Toggle active status"
                          >
                            <div className="w-3 h-3 bg-white rounded-full shadow-sm"></div>
                          </button>
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
          )}
        </CardContent>
      </div>

      {/* Pagination (Static footer for categories as it's a short list) */}
      <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
        <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{categories.length}</span> of {categories.length}</p>
        <div className="flex items-center gap-1">
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&lt;</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium bg-amber-500 text-white">1</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&gt;</button>
        </div>
      </div>
    </div>
  );
}
