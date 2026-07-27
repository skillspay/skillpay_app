'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown, Check, X } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

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
        return <span className="px-2 py-0.5 rounded border border-amber-400 text-[10px] font-bold text-amber-600 uppercase">Open</span>;
      case 'UNDER_REVIEW':
        return <span className="px-2 py-0.5 rounded border border-blue-400 text-[10px] font-bold text-blue-600 uppercase">Under Review</span>;
      case 'RESOLVED':
        return <span className="px-2 py-0.5 rounded border border-green-400 text-[10px] font-bold text-green-600 uppercase">Resolved</span>;
      case 'DISMISSED':
        return <span className="px-2 py-0.5 rounded border border-gray-400 text-[10px] font-bold text-gray-600 uppercase">Dismissed</span>;
      default:
        return <span className="px-2 py-0.5 rounded border border-gray-400 text-[10px] font-bold text-gray-600 uppercase">{status}</span>;
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Disputes & Reports</h2>
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
        
        <button className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-9 px-4 text-[13px] flex items-center">
          <Plus size={16} className="mr-2" />
          Export Data
        </button>
      </div>

      {/* Main Content */}
      <div className="flex-1 p-0 overflow-auto">
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
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Reporter <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Reported User</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Reason</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {reports.map((r) => (
                    <TableRow key={r.id} className="hover:bg-gray-50 border-b border-gray-50">
                      <TableCell className="px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell>
                        <div className="font-semibold text-gray-900 text-[13px]">{r.reportedBy?.email || '—'}</div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{r.reportedBy?.id}</div>
                      </TableCell>
                      <TableCell>
                        <div className="font-medium text-gray-700 text-[13px]">{r.reportedUser?.email || '—'}</div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{r.reportedUser?.id}</div>
                      </TableCell>
                      <TableCell className="text-[13px] text-gray-600 font-medium max-w-[250px] truncate">{r.reason}</TableCell>
                      <TableCell>{getStatusBadge(r.status)}</TableCell>
                      <TableCell className="text-right pr-6">
                        <div className="flex items-center justify-end gap-2">
                          {r.status === 'OPEN' ? (
                            <>
                              <button
                                className="w-8 h-8 rounded flex items-center justify-center bg-green-50 text-green-600 hover:bg-green-100 transition-colors"
                                onClick={() => openDecisionDialog(r, 'RESOLVED')}
                                title="Resolve"
                              >
                                <Check size={16} />
                              </button>
                              <button
                                className="w-8 h-8 rounded flex items-center justify-center bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                                onClick={() => openDecisionDialog(r, 'DISMISSED')}
                                title="Dismiss"
                              >
                                <X size={16} />
                              </button>
                            </>
                          ) : (
                            <button className="text-gray-400 hover:text-gray-600">
                              <MoreVertical size={16} />
                            </button>
                          )}
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

      {/* Pagination */}
      <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100">
        <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{reports.length}</span> of {reports.length}</p>
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
