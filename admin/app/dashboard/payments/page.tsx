'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { DollarSign, CreditCard, Award, Search, Filter, GripHorizontal, Plus, MoreVertical, ChevronDown } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function PaymentsControl() {
  const [payments, setPayments] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [payRes, statRes] = await Promise.all([
          api.payments.list(),
          api.payments.getStats(),
        ]);
        setPayments(payRes || []);
        setStats(statRes);
      } catch (err) {
        console.error('Failed to load payments data', err);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'COMPLETED':
        return <span className="px-2 py-0.5 rounded border border-green-400 text-[10px] font-bold text-green-600 uppercase">Completed</span>;
      case 'PENDING':
        return <span className="px-2 py-0.5 rounded border border-amber-400 text-[10px] font-bold text-amber-600 uppercase">Pending</span>;
      case 'FAILED':
        return <span className="px-2 py-0.5 rounded border border-red-400 text-[10px] font-bold text-red-600 uppercase">Failed</span>;
      case 'REFUNDED':
        return <span className="px-2 py-0.5 rounded border border-gray-400 text-[10px] font-bold text-gray-600 uppercase">Refunded</span>;
      default:
        return <span className="px-2 py-0.5 rounded border border-gray-400 text-[10px] font-bold text-gray-600 uppercase">{status}</span>;
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
        <h2 className="text-lg font-bold text-gray-900">Payments & Revenue</h2>
      </div>

      {/* Revenue Mini Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 p-6 border-b border-gray-100 bg-gray-50/30">
        <div className="bg-white border border-gray-100 shadow-sm rounded-xl p-4 flex items-center justify-between">
          <div>
            <div className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider mb-1">Total Volume</div>
            <div className="text-xl font-bold text-gray-900">${stats?.totalVolume?.toFixed(2) || '0.00'}</div>
          </div>
          <div className="w-10 h-10 rounded-full bg-green-50 flex items-center justify-center text-green-500">
            <DollarSign size={20} />
          </div>
        </div>
        <div className="bg-white border border-gray-100 shadow-sm rounded-xl p-4 flex items-center justify-between">
          <div>
            <div className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider mb-1">Stripe Volume</div>
            <div className="text-xl font-bold text-gray-900">${stats?.stripeVolume?.toFixed(2) || '0.00'}</div>
          </div>
          <div className="w-10 h-10 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-500">
            <CreditCard size={20} />
          </div>
        </div>
        <div className="bg-white border border-gray-100 shadow-sm rounded-xl p-4 flex items-center justify-between">
          <div>
            <div className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider mb-1">PayPal Volume</div>
            <div className="text-xl font-bold text-gray-900">${stats?.paypalVolume?.toFixed(2) || '0.00'}</div>
          </div>
          <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-500">
            <Award size={20} />
          </div>
        </div>
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
          ) : payments.length === 0 ? (
            <div className="text-center py-12 text-gray-500 font-medium">
              No transactions recorded yet.
            </div>
          ) : (
            <div className="w-full">
              <Table>
                <TableHeader>
                  <TableRow className="hover:bg-transparent border-b border-gray-100">
                    <TableHead className="w-12 px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Reference <ChevronDown size={12} className="inline ml-1" /></TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Client</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Gateway</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Amount</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Status</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10">Date</TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider h-10 text-right pr-6">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {payments.map((p) => (
                    <TableRow key={p.id} className="hover:bg-gray-50 border-b border-gray-50">
                      <TableCell className="px-6"><Checkbox className="border-gray-300 rounded-sm" /></TableCell>
                      <TableCell>
                        <div className="font-semibold text-gray-900 text-[13px]">{p.reference}</div>
                        {p.gatewayRef && (
                          <div className="text-[10px] text-gray-400 font-mono mt-0.5 truncate max-w-[120px]">{p.gatewayRef}</div>
                        )}
                      </TableCell>
                      <TableCell className="font-medium text-[13px] text-gray-700">
                        {p.homeowner?.fullName || '—'}
                      </TableCell>
                      <TableCell>
                        <span className="px-2 py-0.5 rounded border border-gray-300 text-[10px] font-bold text-gray-600 uppercase">{p.gateway}</span>
                      </TableCell>
                      <TableCell className="font-extrabold text-[13px] text-gray-900">${Number(p.amount).toFixed(2)}</TableCell>
                      <TableCell>{getStatusBadge(p.status)}</TableCell>
                      <TableCell className="text-[12px] text-gray-600 font-medium">
                        {new Date(p.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right pr-6">
                        <button className="text-gray-400 hover:text-gray-600">
                          <MoreVertical size={16} />
                        </button>
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
        <p className="text-[13px] text-gray-500">Showing <span className="font-medium text-gray-900">{payments.length}</span> of {payments.length}</p>
        <div className="flex items-center gap-1">
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&lt;</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-[13px] font-medium bg-amber-500 text-white">1</button>
          <button className="w-8 h-8 flex items-center justify-center rounded text-gray-400 hover:text-gray-700 hover:bg-gray-50" disabled>&gt;</button>
        </div>
      </div>
    </div>
  );
}
