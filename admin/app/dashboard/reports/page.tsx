'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';

export default function ReportsControl() {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReport, setSelectedReport] = useState<any | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [actionType, setActionType] = useState<'RESOLVED' | 'DISMISSED'>('RESOLVED');

  const fetchReports = async () => {
    setLoading(true);
    try {
      const res = await api.reports.list();
      setReports(res || []);
    } catch (err) {
      console.error('Failed to fetch reports', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const openDecisionDialog = (report: any, action: 'RESOLVED' | 'DISMISSED') => {
    setSelectedReport(report);
    setActionType(action);
    setAdminNote('');
    setDialogOpen(true);
  };

  const handleDecision = async () => {
    if (!selectedReport) return;
    try {
      if (actionType === 'RESOLVED') {
        await api.reports.resolve(selectedReport.id, adminNote);
      } else {
        await api.reports.dismiss(selectedReport.id, adminNote);
      }
      setDialogOpen(false);
      fetchReports();
    } catch (err) {
      console.error('Failed to resolve report', err);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'OPEN':
        return <Badge className="bg-amber-100 text-amber-800 border-none font-semibold">Open</Badge>;
      case 'UNDER_REVIEW':
        return <Badge className="bg-blue-100 text-blue-800 border-none font-semibold">Under Review</Badge>;
      case 'RESOLVED':
        return <Badge className="bg-green-100 text-green-800 border-none font-semibold">Resolved</Badge>;
      case 'DISMISSED':
        return <Badge className="bg-gray-100 text-gray-500 border-none font-semibold">Dismissed</Badge>;
      default:
        return <Badge className="bg-gray-100 text-gray-800 border-none font-semibold">{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Disputes & Reports</h1>
        <p className="text-gray-500 mt-1">Investigate and settle user disputes, reviews flaggings, and behavioral reports.</p>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Active Reports List</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center items-center py-12">
              <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
            </div>
          ) : reports.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No reports active or pending resolution.
            </div>
          ) : (
            <div className="border border-gray-100 rounded-xl overflow-hidden">
              <Table>
                <TableHeader className="bg-gray-50">
                  <TableRow>
                    <TableHead className="font-bold text-gray-700">Reporter</TableHead>
                    <TableHead className="font-bold text-gray-700">Reported User</TableHead>
                    <TableHead className="font-bold text-gray-700">Reason</TableHead>
                    <TableHead className="font-bold text-gray-700">Status</TableHead>
                    <TableHead className="font-bold text-gray-700 text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {reports.map((r) => (
                    <TableRow key={r.id} className="hover:bg-gray-50/50">
                      <TableCell className="font-medium text-gray-900">
                        {r.reportedBy?.email}
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{r.reportedBy?.id}</div>
                      </TableCell>
                      <TableCell className="font-medium text-gray-900">
                        {r.reportedUser?.email}
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{r.reportedUser?.id}</div>
                      </TableCell>
                      <TableCell className="text-gray-600 font-medium max-w-xs truncate">{r.reason}</TableCell>
                      <TableCell>{getStatusBadge(r.status)}</TableCell>
                      <TableCell className="text-right space-x-2">
                        {r.status === 'OPEN' && (
                          <>
                            <Button
                              size="sm"
                              className="bg-green-600 hover:bg-green-700 text-white rounded-lg"
                              onClick={() => openDecisionDialog(r, 'RESOLVED')}
                            >
                              Resolve
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="text-red-600 border-red-200 hover:bg-red-50 rounded-lg"
                              onClick={() => openDecisionDialog(r, 'DISMISSED')}
                            >
                              Dismiss
                            </Button>
                          </>
                        )}
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
            <DialogTitle className="text-xl font-bold text-gray-900">
              {actionType === 'RESOLVED' ? 'Resolve Dispute' : 'Dismiss Dispute'}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 my-4">
            <p className="text-sm text-gray-600">
              Provide administrative feedback to settle this ticket.
            </p>
            <div className="space-y-1">
              <label className="text-sm font-semibold text-gray-700">Audit Log Notes</label>
              <Input
                placeholder="Details of decision/settlement..."
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                className="h-11 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300"
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              className={actionType === 'RESOLVED' ? 'bg-green-600 hover:bg-green-700 text-white rounded-xl w-full' : 'bg-red-600 hover:bg-red-700 text-white rounded-xl w-full'}
              onClick={handleDecision}
            >
              Submit Ticket Decision
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
