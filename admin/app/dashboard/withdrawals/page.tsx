'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Check, X } from 'lucide-react';

export default function WithdrawalsControl() {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedRequest, setSelectedRequest] = useState<any | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [actionType, setActionType] = useState<'APPROVED' | 'REJECTED'>('APPROVED');

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const res = await api.withdrawals.list();
      setRequests(res || []);
    } catch (err) {
      console.error('Failed to fetch withdrawals', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  const openDecisionDialog = (req: any, action: 'APPROVED' | 'REJECTED') => {
    setSelectedRequest(req);
    setActionType(action);
    setAdminNote('');
    setDialogOpen(true);
  };

  const handleDecision = async () => {
    if (!selectedRequest) return;
    try {
      if (actionType === 'APPROVED') {
        await api.withdrawals.approve(selectedRequest.id, adminNote);
      } else {
        await api.withdrawals.reject(selectedRequest.id, adminNote);
      }
      setDialogOpen(false);
      fetchRequests();
    } catch (err) {
      console.error('Failed to resolve request', err);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium">Pending</span>;
      case 'APPROVED':
        return <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium">Approved</span>;
      case 'REJECTED':
        return <span className="px-2 py-1 bg-red-100 text-red-800 rounded-full text-xs font-medium">Rejected</span>;
      default:
        return <span className="px-2 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-medium">{status}</span>;
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden">
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
        <div>
          <h2 className="text-xl font-bold text-gray-800 tracking-tight">Withdrawal Requests</h2>
          <p className="text-sm text-gray-500 mt-1">Approve or reject artisan payout requests</p>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        <div className="min-w-full inline-block align-middle">
          <Table>
            <TableHeader className="bg-gray-50/50 sticky top-0 z-10 backdrop-blur-sm">
              <TableRow className="border-b border-gray-100">
                <TableHead className="font-semibold text-gray-600">Date</TableHead>
                <TableHead className="font-semibold text-gray-600">User</TableHead>
                <TableHead className="font-semibold text-gray-600">Amount</TableHead>
                <TableHead className="font-semibold text-gray-600">Bank Details</TableHead>
                <TableHead className="font-semibold text-gray-600">Status</TableHead>
                <TableHead className="text-right font-semibold text-gray-600">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                    Loading...
                  </TableCell>
                </TableRow>
              ) : requests.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                    No withdrawal requests found.
                  </TableCell>
                </TableRow>
              ) : (
                requests.map((req) => (
                  <TableRow key={req.id} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                    <TableCell className="text-gray-600">
                      {new Date(req.createdAt).toLocaleDateString()}
                    </TableCell>
                    <TableCell className="font-medium text-gray-800">
                      {req.user?.artisan?.fullName || req.user?.email || 'Unknown'}
                    </TableCell>
                    <TableCell className="font-medium text-gray-800">
                      ${Number(req.amount).toFixed(2)}
                    </TableCell>
                    <TableCell>
                      <div className="text-sm">
                        <div className="font-medium">{req.bankName}</div>
                        <div className="text-gray-500">{req.accountNumber} ({req.accountName})</div>
                      </div>
                    </TableCell>
                    <TableCell>
                      {getStatusBadge(req.status)}
                    </TableCell>
                    <TableCell className="text-right">
                      {req.status === 'PENDING' && (
                        <div className="flex justify-end gap-2">
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => openDecisionDialog(req, 'APPROVED')}
                            className="bg-green-50 text-green-600 hover:bg-green-100 hover:text-green-700 border-green-200"
                          >
                            <Check className="h-4 w-4 mr-1" /> Approve
                          </Button>
                          <Button 
                            variant="outline" 
                            size="sm"
                            onClick={() => openDecisionDialog(req, 'REJECTED')}
                            className="bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700 border-red-200"
                          >
                            <X className="h-4 w-4 mr-1" /> Reject
                          </Button>
                        </div>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      </div>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionType === 'APPROVED' ? 'Approve Withdrawal' : 'Reject Withdrawal'}
            </DialogTitle>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm text-gray-500 mb-4">
              {actionType === 'APPROVED' 
                ? 'Are you sure you want to approve this withdrawal request? This will deduct the amount from the artisan\'s wallet.' 
                : 'Please provide a reason for rejecting this withdrawal request.'}
            </p>
            <Input 
              placeholder={actionType === 'APPROVED' ? "Add a note (optional)" : "Reason for rejection (required)"}
              value={adminNote}
              onChange={(e) => setAdminNote(e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
            <Button 
              onClick={handleDecision}
              className={actionType === 'APPROVED' ? 'bg-[#5F1ED9] hover:bg-[#5F1ED9]/90 text-white' : 'bg-red-600 hover:bg-red-700 text-white'}
              disabled={actionType === 'REJECTED' && !adminNote.trim()}
            >
              {actionType === 'APPROVED' ? 'Approve' : 'Reject'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
