'use client';

import React, { useState, useEffect } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { DollarSign, CreditCard, Award } from 'lucide-react';

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
        return <Badge className="bg-green-100 text-green-800 border-none font-semibold">Completed</Badge>;
      case 'PENDING':
        return <Badge className="bg-amber-100 text-amber-800 border-none font-semibold">Pending</Badge>;
      case 'FAILED':
        return <Badge className="bg-red-100 text-red-800 border-none font-semibold">Failed</Badge>;
      case 'REFUNDED':
        return <Badge className="bg-gray-100 text-gray-800 border-none font-semibold">Refunded</Badge>;
      default:
        return <Badge className="bg-gray-100 text-gray-800 border-none font-semibold">{status}</Badge>;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Payments & Revenue</h1>
        <p className="text-gray-500 mt-1">Audit system payment ledgers, gateway configurations, and wallet flows.</p>
      </div>

      {/* Revenue Mini Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Total Volume</CardTitle>
            <div className="p-2 bg-green-50 text-green-600 rounded-xl">
              <DollarSign size={20} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-black text-gray-900">${stats?.totalVolume?.toFixed(2) || '0.00'}</div>
          </CardContent>
        </Card>
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase tracking-wider">Stripe Volume</CardTitle>
            <div className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
              <CreditCard size={20} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-black text-gray-900">${stats?.stripeVolume?.toFixed(2) || '0.00'}</div>
          </CardContent>
        </Card>
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase tracking-wider">PayPal Volume</CardTitle>
            <div className="p-2 bg-blue-50 text-blue-600 rounded-xl">
              <Award size={20} />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-black text-gray-900">${stats?.paypalVolume?.toFixed(2) || '0.00'}</div>
          </CardContent>
        </Card>
      </div>

      <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
        <CardHeader>
          <CardTitle className="text-lg font-bold text-gray-900">Transaction Logs</CardTitle>
        </CardHeader>
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
            <div className="border border-gray-100 rounded-xl overflow-hidden">
              <Table>
                <TableHeader className="bg-gray-50">
                  <TableRow>
                    <TableHead className="font-bold text-gray-700">Reference</TableHead>
                    <TableHead className="font-bold text-gray-700">Client</TableHead>
                    <TableHead className="font-bold text-gray-700">Gateway</TableHead>
                    <TableHead className="font-bold text-gray-700">Amount</TableHead>
                    <TableHead className="font-bold text-gray-700">Status</TableHead>
                    <TableHead className="font-bold text-gray-700">Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {payments.map((p) => (
                    <TableRow key={p.id} className="hover:bg-gray-50/50">
                      <TableCell>
                        <div className="font-semibold text-gray-900">{p.reference}</div>
                        {p.gatewayRef && (
                          <div className="text-[10px] text-gray-400 font-mono mt-0.5">{p.gatewayRef}</div>
                        )}
                      </TableCell>
                      <TableCell className="font-medium text-gray-700">
                        {p.homeowner?.fullName}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline" className="font-semibold">{p.gateway}</Badge>
                      </TableCell>
                      <TableCell className="font-extrabold text-gray-900">${Number(p.amount).toFixed(2)}</TableCell>
                      <TableCell>{getStatusBadge(p.status)}</TableCell>
                      <TableCell className="text-gray-600 font-medium">
                        {new Date(p.createdAt).toLocaleDateString()}
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
