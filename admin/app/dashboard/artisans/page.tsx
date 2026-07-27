'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { ExternalLink, Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function ArtisanVerification() {
  const [verifications, setVerifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDoc, setSelectedDoc] = useState<any | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);

  const fetchVerifications = async () => {
    setLoading(true);
    try {
      const res = await api.artisans.listPendingVerifications();
      setVerifications(res || []);
    } catch (err) {
      console.error('Failed to fetch verifications', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVerifications();
  }, []);

  const openDecisionDialog = (doc: any) => {
    setSelectedDoc(doc);
    setAdminNote('');
    setDialogOpen(true);
  };

  const handleDecision = async (status: 'VERIFIED' | 'REJECTED') => {
    if (!selectedDoc) return;
    try {
      await api.artisans.verifyDocument(selectedDoc.id, status, adminNote);
      setDialogOpen(false);
      fetchVerifications();
    } catch (err) {
      console.error('Failed to process document verification', err);
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Artisan Verifications</h2>
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
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
            </div>
          ) : verifications.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No pending verifications at this time.
            </div>
          ) : (
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Artisan Name <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Document Type</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Submission Date</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">File Attachment</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Review Action</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {verifications.map((v) => (
                    <TableRow key={v.id} className="hover:bg-gray-50 border-b border-gray-50">
                      <TableCell className="px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell>
                        <div className="text-[13px] font-medium text-gray-900">
                          {v.artisan?.userId ? (
                            <a href={`/dashboard/users/${v.artisan.userId}`} className="hover:underline hover:text-amber-600 transition-colors">
                              {v.artisan?.fullName || 'N/A'}
                            </a>
                          ) : (
                            v.artisan?.fullName || 'N/A'
                          )}
                        </div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{v.artisan?.id}</div>
                      </TableCell>
                      <TableCell>
                        <span className="px-2 py-0.5 rounded border border-gray-300 text-[10px] font-bold text-gray-600 uppercase">{v.type}</span>
                      </TableCell>
                      <TableCell className="text-[13px] text-gray-600 font-medium">
                        {new Date(v.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        <a
                          href={v.fileUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center space-x-1.5 text-amber-500 hover:text-amber-600 font-bold transition-colors text-[12px]"
                        >
                          <span>View Doc</span>
                          <ExternalLink size={14} />
                        </a>
                      </TableCell>
                      <TableCell className="text-right pr-6">
                        <div className="flex items-center justify-end gap-3">
                          <Button
                            size="sm"
                            className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-7 px-3 text-[11px]"
                            onClick={() => openDecisionDialog(v)}
                          >
                            Review & Decide
                          </Button>
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

      {/* Pagination (Static for now) */}
      <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
        <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{verifications.length}</span> of {verifications.length}</p>
        <div className="flex items-center gap-1">
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&lt;</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium bg-amber-500 text-white">1</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&gt;</button>
        </div>
      </div>

      {/* Decision Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md rounded-2xl bg-white border border-gray-100 p-6">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-gray-900">Verify Credentials</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 my-4">
            <p className="text-sm text-gray-600">
              Please review the document submitted by <span className="font-bold text-gray-900">{selectedDoc?.artisan?.fullName}</span>.
            </p>
            <div className="space-y-1">
              <label className="text-sm font-semibold text-gray-700">Administrator Review Note (Optional)</label>
              <Input
                placeholder="Explain approval or rejection reason"
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300"
              />
            </div>
          </div>
          <DialogFooter className="flex space-x-2 justify-end">
            <Button
              variant="outline"
              className="text-red-600 border-red-200 hover:bg-red-50 rounded-xl"
              onClick={() => handleDecision('REJECTED')}
            >
              Reject Document
            </Button>
            <Button
              className="bg-green-600 hover:bg-green-700 text-white rounded-xl"
              onClick={() => handleDecision('VERIFIED')}
            >
              Approve Document
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
