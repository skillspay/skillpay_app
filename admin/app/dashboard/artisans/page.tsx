'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { api } from '../../../lib/api';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  ExternalLink,
  Search,
  Filter,
  Users,
  ShieldCheck,
  Clock,
  AlertCircle,
  Star,
  Briefcase,
  Phone,
  Mail,
  Calendar,
  CheckCircle2,
  XCircle,
  Eye,
  Download,
  MoreVertical,
  ChevronDown,
  RefreshCw,
  Award,
  FileText
} from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';

export default function ArtisansPage() {
  const [activeTab, setActiveTab] = useState<'all' | 'pending'>('all');
  
  // All Artisans state
  const [artisans, setArtisans] = useState<any[]>([]);
  const [loadingArtisans, setLoadingArtisans] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [page, setPage] = useState(1);
  const [totalArtisans, setTotalArtisans] = useState(0);
  const [stats, setStats] = useState({
    total: 0,
    verified: 0,
    pending: 0,
    unverified: 0,
  });

  // Pending Verifications state
  const [verifications, setVerifications] = useState<any[]>([]);
  const [loadingVerifications, setLoadingVerifications] = useState(true);
  const [selectedDoc, setSelectedDoc] = useState<any | null>(null);
  const [adminNote, setAdminNote] = useState('');
  const [verificationDialogOpen, setVerificationDialogOpen] = useState(false);

  // Detail Modal state
  const [selectedArtisan, setSelectedArtisan] = useState<any | null>(null);
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);

  // Fetch Artisans
  const fetchArtisans = useCallback(async () => {
    setLoadingArtisans(true);
    try {
      const res = await api.artisans.list({
        search: searchQuery || undefined,
        verificationStatus: statusFilter === 'ALL' ? undefined : statusFilter,
        page,
        limit: 20,
      });
      if (res) {
        setArtisans(res.data || []);
        setTotalArtisans(res.total || 0);
        if (res.stats) {
          setStats(res.stats);
        }
      }
    } catch (err) {
      console.error('Failed to fetch artisans', err);
    } finally {
      setLoadingArtisans(false);
    }
  }, [searchQuery, statusFilter, page]);

  // Fetch Pending Verifications
  const fetchVerifications = useCallback(async () => {
    setLoadingVerifications(true);
    try {
      const res = await api.artisans.listPendingVerifications();
      setVerifications(res || []);
    } catch (err) {
      console.error('Failed to fetch verifications', err);
    } finally {
      setLoadingVerifications(false);
    }
  }, []);

  useEffect(() => {
    fetchArtisans();
  }, [fetchArtisans]);

  useEffect(() => {
    fetchVerifications();
  }, [fetchVerifications]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchArtisans();
  };

  const openDecisionDialog = (doc: any) => {
    setSelectedDoc(doc);
    setAdminNote('');
    setVerificationDialogOpen(true);
  };

  const handleDocumentDecision = async (status: 'VERIFIED' | 'REJECTED') => {
    if (!selectedDoc) return;
    try {
      await api.artisans.verifyDocument(selectedDoc.id, status, adminNote);
      setVerificationDialogOpen(false);
      fetchVerifications();
      fetchArtisans();
    } catch (err) {
      console.error('Failed to process document verification', err);
    }
  };

  const handleDirectStatusChange = async (artisanId: string, newStatus: 'VERIFIED' | 'PENDING' | 'UNVERIFIED' | 'REJECTED') => {
    try {
      setStatusUpdating(true);
      await api.artisans.updateStatus(artisanId, newStatus);
      if (selectedArtisan && selectedArtisan.id === artisanId) {
        setSelectedArtisan({ ...selectedArtisan, verificationStatus: newStatus });
      }
      fetchArtisans();
      fetchVerifications();
    } catch (err) {
      console.error('Failed to update artisan status', err);
    } finally {
      setStatusUpdating(false);
    }
  };

  const openArtisanDetails = (artisan: any) => {
    setSelectedArtisan(artisan);
    setDetailModalOpen(true);
  };

  const exportArtisansCSV = () => {
    if (!artisans.length) return;
    const headers = ['ID', 'Full Name', 'Business Name', 'Email', 'Phone', 'Profession', 'Rating', 'Completed Jobs', 'Verification Status', 'Availability'];
    const rows = artisans.map((a) => [
      a.id,
      `"${a.fullName || ''}"`,
      `"${a.businessName || ''}"`,
      a.user?.email || '',
      a.user?.phone || '',
      `"${a.profession || ''}"`,
      a.averageRating || 0,
      a.completedJobs || 0,
      a.verificationStatus,
      a.availabilityStatus,
    ]);
    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `artisans_export_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const getVerificationBadge = (status: string) => {
    switch (status) {
      case 'VERIFIED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-green-50 text-green-700 border border-green-200">
            <CheckCircle2 size={12} className="text-green-600" />
            Verified
          </span>
        );
      case 'PENDING':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            <Clock size={12} className="text-amber-600" />
            Pending
          </span>
        );
      case 'REJECTED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-red-50 text-red-700 border border-red-200">
            <XCircle size={12} className="text-red-600" />
            Rejected
          </span>
        );
      case 'UNVERIFIED':
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-gray-50 text-gray-600 border border-gray-200">
            <AlertCircle size={12} className="text-gray-400" />
            Unverified
          </span>
        );
    }
  };

  const getAvailabilityBadge = (status: string) => {
    switch (status) {
      case 'AVAILABLE':
        return (
          <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-emerald-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Available
          </span>
        );
      case 'BUSY':
        return (
          <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-amber-700">
            <span className="w-2 h-2 rounded-full bg-amber-500"></span>
            Busy
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 text-[12px] font-medium text-gray-500">
            <span className="w-2 h-2 rounded-full bg-gray-300"></span>
            Offline
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Stats Overview */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border border-gray-100 shadow-sm rounded-xl">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Total Artisans</p>
              <h3 className="text-2xl font-bold text-gray-900 mt-1">{stats.total || artisans.length}</h3>
              <p className="text-xs text-gray-400 mt-1">All registered workers</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600">
              <Users size={22} />
            </div>
          </CardContent>
        </Card>

        <Card className="border border-gray-100 shadow-sm rounded-xl">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Verified Pros</p>
              <h3 className="text-2xl font-bold text-green-600 mt-1">{stats.verified}</h3>
              <p className="text-xs text-green-600 font-medium mt-1">Ready for bookings</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-green-50 flex items-center justify-center text-green-600">
              <ShieldCheck size={22} />
            </div>
          </CardContent>
        </Card>

        <Card className="border border-gray-100 shadow-sm rounded-xl">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Pending Review</p>
              <h3 className="text-2xl font-bold text-amber-600 mt-1">{stats.pending || verifications.length}</h3>
              <p className="text-xs text-amber-600 font-medium mt-1">Awaiting approval</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center text-amber-600">
              <Clock size={22} />
            </div>
          </CardContent>
        </Card>

        <Card className="border border-gray-100 shadow-sm rounded-xl">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Unverified</p>
              <h3 className="text-2xl font-bold text-gray-700 mt-1">{stats.unverified}</h3>
              <p className="text-xs text-gray-400 mt-1">No credentials yet</p>
            </div>
            <div className="w-12 h-12 rounded-xl bg-gray-50 flex items-center justify-center text-gray-500">
              <AlertCircle size={22} />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Table Card */}
      <div className="flex flex-col bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
        {/* Navigation Tabs */}
        <div className="flex items-center justify-between px-6 border-b border-gray-200">
          <div className="flex items-center gap-8">
            <button
              onClick={() => setActiveTab('all')}
              className={`py-4 text-[14px] font-semibold border-b-2 flex items-center gap-2 transition-colors ${
                activeTab === 'all'
                  ? 'border-amber-500 text-gray-900'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              <span>All Artisans</span>
              <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-700">
                {totalArtisans}
              </span>
            </button>
            <button
              onClick={() => setActiveTab('pending')}
              className={`py-4 text-[14px] font-semibold border-b-2 flex items-center gap-2 transition-colors ${
                activeTab === 'pending'
                  ? 'border-amber-500 text-gray-900'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              <span>Pending Documents</span>
              {verifications.length > 0 && (
                <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-amber-500 text-white">
                  {verifications.length}
                </span>
              )}
            </button>
          </div>

          <div className="flex items-center gap-3">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                fetchArtisans();
                fetchVerifications();
              }}
              className="h-9 px-3 text-xs font-medium text-gray-600 border-gray-200 hover:bg-gray-50"
            >
              <RefreshCw size={14} className="mr-1.5" />
              Refresh
            </Button>
            <Button
              size="sm"
              onClick={exportArtisansCSV}
              className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-9 px-4 text-[13px]"
            >
              <Download size={15} className="mr-1.5" />
              Export CSV
            </Button>
          </div>
        </div>

        {/* Tab 1: All Artisans */}
        {activeTab === 'all' && (
          <>
            {/* Filter and Search Bar */}
            <div className="p-4 border-b border-gray-100 bg-gray-50/50 flex flex-wrap items-center justify-between gap-4">
              <form onSubmit={handleSearchSubmit} className="relative flex-1 min-w-[280px] max-w-md">
                <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
                <Input
                  type="text"
                  placeholder="Search by name, business, email or phone..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 h-10 bg-white border-gray-200 rounded-lg text-sm focus:border-amber-400 focus:ring-amber-400"
                />
              </form>

              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-xs font-semibold text-gray-500 uppercase mr-1">Status:</span>
                {['ALL', 'VERIFIED', 'PENDING', 'UNVERIFIED', 'REJECTED'].map((status) => (
                  <button
                    key={status}
                    onClick={() => {
                      setStatusFilter(status);
                      setPage(1);
                    }}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                      statusFilter === status
                        ? 'bg-amber-500 text-white shadow-sm'
                        : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-100'
                    }`}
                  >
                    {status === 'ALL' ? 'All' : status.charAt(0) + status.slice(1).toLowerCase()}
                  </button>
                ))}
              </div>
            </div>

            {/* Artisans Table */}
            <div className="flex-1 overflow-x-auto">
              {loadingArtisans ? (
                <div className="flex justify-center items-center py-20">
                  <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
                </div>
              ) : artisans.length === 0 ? (
                <div className="text-center py-20 text-gray-500">
                  <Users size={40} className="mx-auto text-gray-300 mb-3" />
                  <p className="font-semibold text-gray-800 text-base">No artisans found</p>
                  <p className="text-xs text-gray-400 mt-1">Try adjusting your search or filters.</p>
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="bg-gray-50/50 hover:bg-gray-50/50 border-b border-gray-200">
                      <TableHead className="w-12 px-6">
                        <Checkbox className="border-gray-300 rounded-sm" />
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                        Artisan Profile
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                        Trade / Profession
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                        Contact Info
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                        Performance
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                        Status
                      </TableHead>
                      <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3 text-right pr-6">
                        Actions
                      </TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {artisans.map((artisan) => (
                      <TableRow key={artisan.id} className="hover:bg-gray-50/80 border-b border-gray-100 transition-colors">
                        <TableCell className="px-6">
                          <Checkbox className="border-gray-300 rounded-sm" />
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-3">
                            {artisan.profilePhoto ? (
                              <img
                                src={artisan.profilePhoto}
                                alt={artisan.fullName}
                                className="w-10 h-10 rounded-full object-cover border border-gray-200"
                              />
                            ) : (
                              <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-amber-400 to-amber-500 text-white flex items-center justify-center font-bold text-sm shadow-sm">
                                {artisan.fullName?.slice(0, 2).toUpperCase() || 'AR'}
                              </div>
                            )}
                            <div>
                              <div className="font-semibold text-gray-900 text-[13px] flex items-center gap-1.5">
                                <span>{artisan.fullName || 'Unnamed Artisan'}</span>
                                {artisan.verificationStatus === 'VERIFIED' && (
                                  <ShieldCheck size={14} className="text-green-600" />
                                )}
                              </div>
                              {artisan.businessName && (
                                <p className="text-[11px] text-gray-500 font-medium">{artisan.businessName}</p>
                              )}
                              <p className="text-[10px] text-gray-400 font-mono">ID: {artisan.id.slice(0, 8)}...</p>
                            </div>
                          </div>
                        </TableCell>

                        <TableCell>
                          <div className="space-y-1">
                            <span className="inline-block px-2 py-0.5 text-xs font-semibold rounded bg-amber-50 text-amber-800 border border-amber-200">
                              {artisan.profession || 'Artisan'}
                            </span>
                            {artisan.categories && artisan.categories.length > 0 && (
                              <div className="flex flex-wrap gap-1 mt-1">
                                {artisan.categories.slice(0, 2).map((c: any, idx: number) => (
                                  <span key={idx} className="text-[10px] text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded">
                                    {c.category?.name || c.category}
                                  </span>
                                ))}
                                {artisan.categories.length > 2 && (
                                  <span className="text-[10px] text-gray-400">+{artisan.categories.length - 2}</span>
                                )}
                              </div>
                            )}
                          </div>
                        </TableCell>

                        <TableCell>
                          <div className="text-xs space-y-1">
                            {artisan.user?.email && (
                              <div className="flex items-center gap-1.5 text-gray-600">
                                <Mail size={12} className="text-gray-400" />
                                <span>{artisan.user.email}</span>
                              </div>
                            )}
                            {artisan.user?.phone && (
                              <div className="flex items-center gap-1.5 text-gray-600">
                                <Phone size={12} className="text-gray-400" />
                                <span>{artisan.user.phone}</span>
                              </div>
                            )}
                            <div className="flex items-center gap-1.5 text-[11px] text-gray-400">
                              <Calendar size={11} />
                              <span>Joined {new Date(artisan.createdAt).toLocaleDateString()}</span>
                            </div>
                          </div>
                        </TableCell>

                        <TableCell>
                          <div className="text-xs space-y-1">
                            <div className="flex items-center gap-1 font-semibold text-gray-900">
                              <Star size={13} className="text-amber-500 fill-amber-500" />
                              <span>{Number(artisan.averageRating || 0).toFixed(1)}</span>
                              <span className="text-gray-400 font-normal">({artisan._count?.reviews || 0})</span>
                            </div>
                            <div className="text-[11px] text-gray-500">
                              <span className="font-semibold text-gray-700">{artisan.completedJobs || 0}</span> jobs done
                            </div>
                            <div className="pt-0.5">
                              {getAvailabilityBadge(artisan.availabilityStatus)}
                            </div>
                          </div>
                        </TableCell>

                        <TableCell>
                          <div className="space-y-1">
                            <div>{getVerificationBadge(artisan.verificationStatus)}</div>
                            {artisan.verificationDocuments && artisan.verificationDocuments.length > 0 && (
                              <div className="text-[10px] text-gray-400 font-medium">
                                {artisan.verificationDocuments.length} doc{artisan.verificationDocuments.length > 1 ? 's' : ''} uploaded
                              </div>
                            )}
                          </div>
                        </TableCell>

                        <TableCell className="text-right pr-6">
                          <div className="flex items-center justify-end gap-2">
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => openArtisanDetails(artisan)}
                              className="h-8 px-2.5 text-xs font-medium text-gray-700 border-gray-200 hover:bg-gray-50 hover:text-amber-600"
                            >
                              <Eye size={13} className="mr-1" />
                              Profile
                            </Button>

                            {artisan.verificationStatus !== 'VERIFIED' && (
                              <Button
                                size="sm"
                                onClick={() => handleDirectStatusChange(artisan.id, 'VERIFIED')}
                                className="h-8 px-2.5 text-xs font-semibold bg-green-600 hover:bg-green-700 text-white"
                              >
                                Approve
                              </Button>
                            )}

                            {artisan.verificationStatus === 'VERIFIED' && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => handleDirectStatusChange(artisan.id, 'UNVERIFIED')}
                                className="h-8 px-2.5 text-xs font-medium text-red-600 border-red-200 hover:bg-red-50"
                              >
                                Revoke
                              </Button>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </div>

            {/* Pagination */}
            <div className="flex justify-between items-center px-6 py-4 border-t border-gray-100 bg-gray-50/30">
              <p className="text-[13px] text-gray-500">
                Showing <span className="font-medium text-gray-900">{artisans.length}</span> of{' '}
                <span className="font-medium text-gray-900">{totalArtisans}</span> artisans
              </p>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page <= 1}
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  className="h-8 px-3 text-xs"
                >
                  Previous
                </Button>
                <span className="text-xs font-semibold px-2 py-1 bg-white border border-gray-200 rounded">
                  Page {page}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={artisans.length < 20}
                  onClick={() => setPage(p => p + 1)}
                  className="h-8 px-3 text-xs"
                >
                  Next
                </Button>
              </div>
            </div>
          </>
        )}

        {/* Tab 2: Pending Verifications Documents */}
        {activeTab === 'pending' && (
          <div className="flex-1 overflow-x-auto">
            {loadingVerifications ? (
              <div className="flex justify-center items-center py-20">
                <div className="w-8 h-8 rounded-full border-4 border-amber-400 border-t-transparent animate-spin"></div>
              </div>
            ) : verifications.length === 0 ? (
              <div className="text-center py-20 text-gray-500">
                <ShieldCheck size={40} className="mx-auto text-green-500 mb-3" />
                <p className="font-semibold text-gray-800 text-base">All caught up!</p>
                <p className="text-xs text-gray-400 mt-1">No pending artisan verification documents at this time.</p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow className="bg-gray-50/50 hover:bg-gray-50/50 border-b border-gray-200">
                    <TableHead className="w-12 px-6">
                      <Checkbox className="border-gray-300 rounded-sm" />
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                      Artisan Name
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                      Document Type
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                      Submission Date
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3">
                      Attachment
                    </TableHead>
                    <TableHead className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider py-3 text-right pr-6">
                      Review Action
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {verifications.map((v) => (
                    <TableRow key={v.id} className="hover:bg-gray-50 border-b border-gray-100">
                      <TableCell className="px-6">
                        <Checkbox className="border-gray-300 rounded-sm" />
                      </TableCell>
                      <TableCell>
                        <div className="text-[13px] font-medium text-gray-900">
                          {v.artisan?.userId ? (
                            <a
                              href={`/dashboard/users/${v.artisan.userId}`}
                              className="hover:underline hover:text-amber-600 transition-colors font-semibold"
                            >
                              {v.artisan?.fullName || 'N/A'}
                            </a>
                          ) : (
                            v.artisan?.fullName || 'N/A'
                          )}
                        </div>
                        <div className="text-[10px] text-gray-400 font-mono mt-0.5">{v.artisan?.id}</div>
                      </TableCell>
                      <TableCell>
                        <span className="px-2.5 py-1 rounded bg-gray-100 border border-gray-200 text-[11px] font-bold text-gray-700 uppercase">
                          {v.type}
                        </span>
                      </TableCell>
                      <TableCell className="text-[13px] text-gray-600 font-medium">
                        {new Date(v.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        <a
                          href={v.fileUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center space-x-1 text-amber-600 hover:text-amber-700 font-semibold transition-colors text-[12px]"
                        >
                          <span>Open File</span>
                          <ExternalLink size={13} />
                        </a>
                      </TableCell>
                      <TableCell className="text-right pr-6">
                        <Button
                          size="sm"
                          className="bg-amber-500 hover:bg-amber-600 text-white rounded shadow-sm font-semibold h-8 px-3 text-[12px]"
                          onClick={() => openDecisionDialog(v)}
                        >
                          Review & Decide
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </div>
        )}
      </div>

      {/* Decision Dialog for Document */}
      <Dialog open={verificationDialogOpen} onOpenChange={setVerificationDialogOpen}>
        <DialogContent className="max-w-md rounded-2xl bg-white border border-gray-100 p-6">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-gray-900">Verify Credentials</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 my-4">
            <p className="text-sm text-gray-600">
              Please review the document submitted by{' '}
              <span className="font-bold text-gray-900">{selectedDoc?.artisan?.fullName}</span>.
            </p>
            {selectedDoc?.fileUrl && (
              <div className="p-3 bg-gray-50 border border-gray-200 rounded-lg flex items-center justify-between">
                <span className="text-xs font-semibold text-gray-700 uppercase">{selectedDoc.type}</span>
                <a
                  href={selectedDoc.fileUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-xs font-bold text-amber-600 hover:text-amber-700 inline-flex items-center gap-1"
                >
                  <span>View Full Document</span>
                  <ExternalLink size={12} />
                </a>
              </div>
            )}
            <div className="space-y-1">
              <label className="text-xs font-semibold text-gray-700">Administrator Review Note (Optional)</label>
              <Input
                placeholder="Explain approval or rejection reason"
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                className="h-10 rounded-xl focus:border-amber-400 focus:ring-amber-400 border-gray-300 text-sm"
              />
            </div>
          </div>
          <DialogFooter className="flex space-x-2 justify-end">
            <Button
              variant="outline"
              className="text-red-600 border-red-200 hover:bg-red-50 rounded-xl text-xs h-9"
              onClick={() => handleDocumentDecision('REJECTED')}
            >
              Reject Document
            </Button>
            <Button
              className="bg-green-600 hover:bg-green-700 text-white rounded-xl text-xs h-9"
              onClick={() => handleDocumentDecision('VERIFIED')}
            >
              Approve Document
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Artisan Profile Details Dialog */}
      <Dialog open={detailModalOpen} onOpenChange={setDetailModalOpen}>
        <DialogContent className="max-w-2xl rounded-2xl bg-white border border-gray-100 p-6 max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-gray-900 flex items-center justify-between">
              <span>Artisan Details</span>
              {selectedArtisan && getVerificationBadge(selectedArtisan.verificationStatus)}
            </DialogTitle>
          </DialogHeader>

          {selectedArtisan && (
            <div className="space-y-6 my-2">
              {/* Profile Card Header */}
              <div className="flex items-center gap-4 p-4 rounded-xl bg-gray-50 border border-gray-100">
                {selectedArtisan.profilePhoto ? (
                  <img
                    src={selectedArtisan.profilePhoto}
                    alt={selectedArtisan.fullName}
                    className="w-16 h-16 rounded-full object-cover border-2 border-white shadow"
                  />
                ) : (
                  <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-amber-400 to-amber-500 text-white flex items-center justify-center font-bold text-xl shadow">
                    {selectedArtisan.fullName?.slice(0, 2).toUpperCase() || 'AR'}
                  </div>
                )}
                <div>
                  <h3 className="text-lg font-bold text-gray-900">{selectedArtisan.fullName}</h3>
                  {selectedArtisan.businessName && (
                    <p className="text-sm font-medium text-amber-700">{selectedArtisan.businessName}</p>
                  )}
                  <p className="text-xs text-gray-500 mt-0.5">
                    Profession: <span className="font-semibold text-gray-700">{selectedArtisan.profession || 'Artisan'}</span>
                  </p>
                  <p className="text-xs text-gray-400 font-mono mt-0.5">Artisan ID: {selectedArtisan.id}</p>
                </div>
              </div>

              {/* Metrics Grid */}
              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="p-3 rounded-lg bg-gray-50 border border-gray-100">
                  <p className="text-[11px] font-semibold text-gray-500 uppercase">Average Rating</p>
                  <p className="text-lg font-bold text-amber-500 mt-1 flex items-center justify-center gap-1">
                    <Star size={16} className="fill-amber-500 text-amber-500" />
                    {Number(selectedArtisan.averageRating || 0).toFixed(1)}
                  </p>
                </div>
                <div className="p-3 rounded-lg bg-gray-50 border border-gray-100">
                  <p className="text-[11px] font-semibold text-gray-500 uppercase">Completed Jobs</p>
                  <p className="text-lg font-bold text-gray-900 mt-1">{selectedArtisan.completedJobs || 0}</p>
                </div>
                <div className="p-3 rounded-lg bg-gray-50 border border-gray-100">
                  <p className="text-[11px] font-semibold text-gray-500 uppercase">Experience</p>
                  <p className="text-lg font-bold text-gray-900 mt-1">{selectedArtisan.yearsExperience || 0} yrs</p>
                </div>
              </div>

              {/* Contact Information */}
              <div className="space-y-2">
                <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Contact & Location</h4>
                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="p-3 rounded-lg border border-gray-200">
                    <span className="text-gray-400 block mb-0.5">Email</span>
                    <span className="font-medium text-gray-800">{selectedArtisan.user?.email || 'N/A'}</span>
                  </div>
                  <div className="p-3 rounded-lg border border-gray-200">
                    <span className="text-gray-400 block mb-0.5">Phone</span>
                    <span className="font-medium text-gray-800">{selectedArtisan.user?.phone || 'N/A'}</span>
                  </div>
                  <div className="p-3 rounded-lg border border-gray-200">
                    <span className="text-gray-400 block mb-0.5">Based In</span>
                    <span className="font-medium text-gray-800">{selectedArtisan.basedIn || 'Not specified'}</span>
                  </div>
                  <div className="p-3 rounded-lg border border-gray-200">
                    <span className="text-gray-400 block mb-0.5">Hourly Rate</span>
                    <span className="font-medium text-gray-800">
                      {selectedArtisan.hourlyRate ? `$${selectedArtisan.hourlyRate}/hr` : 'Negotiable'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Bio & Experience */}
              {selectedArtisan.bio && (
                <div className="space-y-1">
                  <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">About & Bio</h4>
                  <p className="text-xs text-gray-700 bg-gray-50 p-3 rounded-lg leading-relaxed border border-gray-100">
                    {selectedArtisan.bio}
                  </p>
                </div>
              )}

              {/* Categories */}
              {selectedArtisan.categories && selectedArtisan.categories.length > 0 && (
                <div className="space-y-2">
                  <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Assigned Categories</h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedArtisan.categories.map((c: any, i: number) => (
                      <span key={i} className="px-3 py-1 bg-amber-50 text-amber-800 border border-amber-200 rounded-full text-xs font-semibold">
                        {c.category?.name || c.category}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Uploaded Verification Documents */}
              <div className="space-y-2">
                <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Uploaded Documents</h4>
                {selectedArtisan.verificationDocuments && selectedArtisan.verificationDocuments.length > 0 ? (
                  <div className="space-y-2">
                    {selectedArtisan.verificationDocuments.map((doc: any) => (
                      <div key={doc.id} className="flex items-center justify-between p-3 rounded-lg bg-gray-50 border border-gray-200 text-xs">
                        <div className="flex items-center gap-2">
                          <FileText size={16} className="text-amber-500" />
                          <div>
                            <span className="font-semibold text-gray-800 uppercase">{doc.type}</span>
                            <span className="text-gray-400 ml-2 text-[11px]">{new Date(doc.createdAt).toLocaleDateString()}</span>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                            doc.status === 'VERIFIED' ? 'bg-green-100 text-green-700' :
                            doc.status === 'REJECTED' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'
                          }`}>
                            {doc.status}
                          </span>
                          <a
                            href={doc.fileUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-amber-600 hover:text-amber-700 font-bold inline-flex items-center gap-1"
                          >
                            <span>View</span>
                            <ExternalLink size={12} />
                          </a>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-xs text-gray-400 italic">No verification documents uploaded yet.</p>
                )}
              </div>

              {/* Quick Admin Actions */}
              <div className="pt-2 border-t border-gray-100 flex items-center justify-between">
                <div>
                  {selectedArtisan.userId && (
                    <a
                      href={`/dashboard/users/${selectedArtisan.userId}`}
                      className="text-xs font-semibold text-amber-600 hover:text-amber-700 hover:underline"
                    >
                      View User Account &rarr;
                    </a>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    disabled={statusUpdating || selectedArtisan.verificationStatus === 'REJECTED'}
                    onClick={() => handleDirectStatusChange(selectedArtisan.id, 'REJECTED')}
                    className="text-red-600 border-red-200 hover:bg-red-50 text-xs h-8"
                  >
                    Mark Rejected
                  </Button>
                  <Button
                    size="sm"
                    disabled={statusUpdating || selectedArtisan.verificationStatus === 'VERIFIED'}
                    onClick={() => handleDirectStatusChange(selectedArtisan.id, 'VERIFIED')}
                    className="bg-green-600 hover:bg-green-700 text-white text-xs h-8 font-semibold"
                  >
                    Mark Verified
                  </Button>
                </div>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
