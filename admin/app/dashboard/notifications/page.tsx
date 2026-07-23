'use client';

import React, { useState } from 'react';
import { request } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Bell, Send } from 'lucide-react';

const NOTIFICATION_TYPES = ['GENERAL', 'JOB', 'PAYMENT', 'BOOKING', 'VERIFICATION'];

export default function NotificationsPage() {
  const [userId, setUserId] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [type, setType] = useState('GENERAL');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!userId.trim() || !title.trim() || !body.trim()) return;

    setSending(true);
    setResult(null);
    try {
      await request('/notifications', {
        method: 'POST',
        body: JSON.stringify({ userId, title, body, type }),
      });
      setResult({ success: true, message: 'Notification sent successfully.' });
      setUserId('');
      setTitle('');
      setBody('');
    } catch (err: any) {
      setResult({ success: false, message: err.message || 'Failed to send notification.' });
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-extrabold text-gray-900 tracking-tight">Notifications</h1>
        <p className="text-gray-500 mt-1">Send system notifications directly to platform users.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Send notification form */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900 flex items-center gap-2">
              <Bell size={20} className="text-amber-500" />
              Send Notification
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSend} className="space-y-4">
              {result && (
                <div
                  className={`p-3 rounded-xl text-sm font-medium border ${
                    result.success
                      ? 'bg-green-50 text-green-700 border-green-200'
                      : 'bg-red-50 text-red-700 border-red-200'
                  }`}
                >
                  {result.message}
                </div>
              )}

              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">User ID</label>
                <Input
                  required
                  placeholder="Target user UUID"
                  value={userId}
                  onChange={(e) => setUserId(e.target.value)}
                  className="h-11 rounded-xl border-gray-300 focus:border-amber-400 focus:ring-amber-400"
                />
              </div>

              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Type</label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value)}
                  className="w-full h-11 rounded-xl border border-gray-300 px-3 text-sm focus:outline-none focus:border-amber-400"
                >
                  {NOTIFICATION_TYPES.map((t) => (
                    <option key={t} value={t}>
                      {t}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Title</label>
                <Input
                  required
                  placeholder="Notification title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="h-11 rounded-xl border-gray-300 focus:border-amber-400 focus:ring-amber-400"
                />
              </div>

              <div className="space-y-1">
                <label className="text-sm font-semibold text-gray-700">Body</label>
                <textarea
                  required
                  rows={4}
                  placeholder="Notification message body..."
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  className="w-full rounded-xl border border-gray-300 px-3 py-2.5 text-sm focus:outline-none focus:border-amber-400 resize-none"
                />
              </div>

              <Button
                type="submit"
                disabled={sending}
                className="w-full h-11 bg-amber-400 hover:bg-amber-500 text-white font-bold rounded-xl flex items-center justify-center gap-2"
              >
                <Send size={16} />
                {sending ? 'Sending...' : 'Send Notification'}
              </Button>
            </form>
          </CardContent>
        </Card>

        {/* Info card */}
        <Card className="border-gray-200 shadow-sm rounded-2xl bg-white">
          <CardHeader>
            <CardTitle className="text-lg font-bold text-gray-900">Notification Types</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {[
              { type: 'GENERAL', desc: 'Platform-wide announcements and updates', color: 'bg-gray-100 text-gray-700' },
              { type: 'JOB', desc: 'Job posting status changes and updates', color: 'bg-blue-100 text-blue-700' },
              { type: 'PAYMENT', desc: 'Payment confirmations and receipts', color: 'bg-green-100 text-green-700' },
              { type: 'BOOKING', desc: 'Booking confirmations and scheduling', color: 'bg-purple-100 text-purple-700' },
              { type: 'VERIFICATION', desc: 'Document review results for artisans', color: 'bg-amber-100 text-amber-700' },
            ].map((item) => (
              <div key={item.type} className="flex items-start gap-3 p-3 rounded-xl border border-gray-100">
                <span className={`px-2 py-0.5 rounded-lg text-xs font-bold ${item.color}`}>
                  {item.type}
                </span>
                <p className="text-sm text-gray-600">{item.desc}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
