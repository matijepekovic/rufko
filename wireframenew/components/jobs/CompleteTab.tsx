import { useState } from 'react';
import { CheckCircle, MapPin, Calendar, DollarSign, Search, Download, Eye } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface CompletedJob {
  id: string;
  customerName: string;
  address: string;
  completedDate: string;
  type: string;
  value: number;
  duration: string;
  rating?: number;
  paymentStatus: 'paid' | 'pending' | 'overdue';
}

export function CompleteTab() {
  const [selectedPeriod, setSelectedPeriod] = useState('month');

  const mockCompletedJobs: CompletedJob[] = [
    {
      id: '1',
      customerName: 'Wilson Building Corp',
      address: '1234 Business Park Dr, Downtown',
      completedDate: '2024-06-10',
      type: 'Roof Replacement',
      value: 12000,
      duration: '5 days',
      rating: 5,
      paymentStatus: 'paid'
    },
    {
      id: '2',
      customerName: 'Thompson Residence',
      address: '456 Oak Street, Suburbia',
      completedDate: '2024-06-08',
      type: 'Gutter Repair',
      value: 850,
      duration: '1 day',
      rating: 4,
      paymentStatus: 'paid'
    },
    {
      id: '3',
      customerName: 'Garcia Estate',
      address: '789 Hill View Ave, Heights',
      completedDate: '2024-06-05',
      type: 'Emergency Leak Repair',
      value: 2400,
      duration: '2 days',
      rating: 5,
      paymentStatus: 'pending'
    },
    {
      id: '4',
      customerName: 'Miller House',
      address: '321 Pine Street, Westside',
      completedDate: '2024-05-28',
      type: 'Roof Inspection',
      value: 300,
      duration: '3 hours',
      rating: 4,
      paymentStatus: 'paid'
    },
    {
      id: '5',
      customerName: 'Davis Home',
      address: '654 Maple Ave, Northgate',
      completedDate: '2024-05-25',
      type: 'Shingle Installation',
      value: 4200,
      duration: '3 days',
      paymentStatus: 'overdue'
    }
  ];

  const periods = [
    { id: 'week', label: 'Last Week', count: 1 },
    { id: 'month', label: 'Last Month', count: mockCompletedJobs.length },
    { id: 'quarter', label: 'Last 3 Months', count: mockCompletedJobs.length },
    { id: 'year', label: 'Last Year', count: mockCompletedJobs.length }
  ];

  const getPaymentStatusColor = (status: CompletedJob['paymentStatus']) => {
    switch (status) {
      case 'paid': return 'bg-green-100 text-green-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'overdue': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: date.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined
    });
  };

  const renderStars = (rating?: number) => {
    if (!rating) return null;
    return (
      <div className="flex items-center space-x-1">
        {Array.from({ length: 5 }, (_, i) => (
          <span
            key={i}
            className={`text-xs ${i < rating ? 'text-yellow-400' : 'text-gray-300'}`}
          >
            ★
          </span>
        ))}
      </div>
    );
  };

  const totalValue = mockCompletedJobs.reduce((sum, job) => sum + job.value, 0);
  const avgRating = mockCompletedJobs.filter(j => j.rating).reduce((sum, job) => sum + (job.rating || 0), 0) / mockCompletedJobs.filter(j => j.rating).length;

  return (
    <div className="flex flex-col h-full">
      {/* Search and Summary */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search completed jobs..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Download size={16} />
          </Button>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-3 gap-3 mb-4">
          <div className="bg-card rounded-lg p-3 border border-stroke">
            <div className="text-xs text-muted-foreground">Total Value</div>
            <div className="font-semibold text-sm">${totalValue.toLocaleString()}</div>
          </div>
          <div className="bg-card rounded-lg p-3 border border-stroke">
            <div className="text-xs text-muted-foreground">Jobs Done</div>
            <div className="font-semibold text-sm">{mockCompletedJobs.length}</div>
          </div>
          <div className="bg-card rounded-lg p-3 border border-stroke">
            <div className="text-xs text-muted-foreground">Avg Rating</div>
            <div className="font-semibold text-sm">{avgRating.toFixed(1)} ⭐</div>
          </div>
        </div>

        {/* Period Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {periods.map((period) => (
            <button
              key={period.id}
              onClick={() => setSelectedPeriod(period.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedPeriod === period.id
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {period.label} ({period.count})
            </button>
          ))}
        </div>
      </div>

      {/* Completed Jobs List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {mockCompletedJobs.map((job) => (
            <div
              key={job.id}
              className="p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              {/* Header */}
              <div className="flex items-start space-x-3 mb-3">
                <div className="flex-shrink-0 mt-1">
                  <CheckCircle size={16} className="text-green-600" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-sm truncate">
                    {job.customerName}
                  </div>
                  <div className="text-xs text-muted-foreground truncate">
                    {job.type}
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="font-semibold text-sm text-green-600">
                    ${job.value.toLocaleString()}
                  </div>
                  <Badge className={`text-xs px-2 py-0.5 ${getPaymentStatusColor(job.paymentStatus)}`}>
                    {job.paymentStatus}
                  </Badge>
                </div>
              </div>

              {/* Details */}
              <div className="space-y-2">
                <div className="flex items-center text-xs text-muted-foreground">
                  <MapPin size={10} className="mr-2 flex-shrink-0" />
                  <span className="truncate">{job.address}</span>
                </div>
                
                <div className="flex items-center justify-between">
                  <div className="flex items-center text-xs text-muted-foreground">
                    <Calendar size={10} className="mr-2 flex-shrink-0" />
                    <span>Completed {formatDate(job.completedDate)}</span>
                    <span className="mx-2">•</span>
                    <span>{job.duration}</span>
                  </div>
                  
                  {job.rating && (
                    <div className="flex items-center">
                      {renderStars(job.rating)}
                    </div>
                  )}
                </div>
              </div>

              {/* Actions */}
              <div className="flex items-center justify-end space-x-2 mt-3 pt-3 border-t border-stroke">
                <Button variant="ghost" size="sm" className="h-8 px-3 text-xs">
                  <Eye size={12} className="mr-1" />
                  View
                </Button>
                <Button variant="ghost" size="sm" className="h-8 px-3 text-xs">
                  <Download size={12} className="mr-1" />
                  Invoice
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}