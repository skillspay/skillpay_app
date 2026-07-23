'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { ExternalLink } from 'lucide-react';

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
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Artisan Verifications</h1>
        <p className="text-gray-500 mt-1">Review documents and verify identity/business qualifications for artisans.</p>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Pending Verification Requests</CardTitle>
        </CardHeader>
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
            <div className="border border-gray-100 rounded-xl overflow-hidden">
              <Table>
                <TableHeader className="bg-gray-50">
                  <TableRow>
                    <TableHead className="font-bold text-gray-700">Artisan Name</TableHead>
                    <TableHead className="font-bold text-gray-700">Document Type</TableHead>
                    <TableHead className="font-bold text-gray-700">Submission Date</TableHead>
                    <TableHead className="font-bold text-gray-700">File Attachment</TableHead>
                    <TableHead className="font-bold text-gray-700 text-right">Review Action</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {verifications.map((v) => (
                    <TableRow key={v.id} className="hover:bg-gray-50/50">
                      <TableCell className="font-medium text-gray-900">
                        {v.artisan?.fullName || 'N/A'}
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{v.artisan?.id}</div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline" className="font-semibold">{v.type}</Badge>
                      </TableCell>
                      <TableCell className="text-gray-600 font-medium">
                        {new Date(v.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        <a
                          href={v.fileUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center space-x-1.5 text-amber-500 hover:text-amber-600 font-bold transition-colors"
                        >
                          <span>View Doc</span>
                          <ExternalLink size={14} />
                        </a>
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          className="bg-amber-400 hover:bg-amber-500 text-white rounded-lg font-semibold"
                          onClick={() => openDecisionDialog(v)}
                        >
                          Review & Decide
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
