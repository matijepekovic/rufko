import { useState } from 'react';
import { FileText, MapPin, Calendar, DollarSign, Search, Send, Edit, Trash2 } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface Estimate {
  id: string;
  customerName: string;
  address: string;
  createdDate: string;
  expiryDate: string;
  type: string;
  value: number;
  status: 'draft' | 'sent' | 'viewed' | 'accepted' | 'declined' | 'expired';
  phone: string;
  lastActivity?: string;
}

export function EstimatesTab() {
  const [selectedStatus, setSelectedStatus] = useState('all');

  const mockEstimates: Estimate[] = [
    {
      id: '1',
      customerName: 'Jennifer Adams',
      address: '123 Residential St, Suburbs',
      createdDate: '2024-06-12',
      expiryDate: '2024-07-12',
      type: 'Roof Replacement Quote',
      value: 8500,
      status: 'sent',
      phone: '(555) 123-4567',
      lastActivity: 'Opened 2 days ago'
    },
    {
      id: '2',
      customerName: 'Martinez Construction',
      address: '456 Commercial Blvd, Business District',
      createdDate: '2024-06-10',
      expiryDate: '2024-07-10',
      type: 'Commercial Roof Inspection',
      value: 1200,
      status: 'viewed',
      phone: '(555) 987-6543',
      lastActivity: 'Viewed yesterday'
    },
    {
      id: '3',
      customerName: 'Smith Family Home',
      address: '789 Oak Lane, Residential Area',
      createdDate: '2024-06-08',
      expiryDate: '2024-07-08',
      type: 'Gutter Installation',
      value: 3200,
      status: 'accepted',
      phone: '(555) 456-7890'
    },
    {
      id: '4',
      customerName: 'Brown Estate',
      address: '321 Hill Drive, Heights',
      createdDate: '2024-06-05',
      expiryDate: '2024-07-05',
      type: 'Emergency Repair Estimate',
      value: 1800,
      status: 'declined',
      phone: '(555) 555-1234'
    },
    {
      id: '5',
      customerName: 'Taylor Properties',
      address: '654 Main Street, Downtown',
      createdDate: '2024-05-20',
      expiryDate: '2024-06-20',
      type: 'Roof Maintenance Contract',
      value: 4500,
      status: 'expired',
      phone: '(555) 777-8888'
    }
  ];

  const statuses = [
    { id: 'all', label: 'All', count: mockEstimates.length },
    { id: 'draft', label: 'Draft', count: mockEstimates.filter(e => e.status === 'draft').length },
    { id: 'sent', label: 'Sent', count: mockEstimates.filter(e => e.status === 'sent').length },
    { id: 'viewed', label: 'Viewed', count: mockEstimates.filter(e => e.status === 'viewed').length },
    { id: 'accepted', label: 'Accepted', count: mockEstimates.filter(e => e.status === 'accepted').length },
    { id: 'pending', label: 'Pending Response', count: mockEstimates.filter(e => ['sent', 'viewed'].includes(e.status)).length }
  ];

  const getStatusColor = (status: Estimate['status']) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800';
      case 'sent': return 'bg-blue-100 text-blue-800';
      case 'viewed': return 'bg-yellow-100 text-yellow-800';
      case 'accepted': return 'bg-green-100 text-green-800';
      case 'declined': return 'bg-red-100 text-red-800';
      case 'expired': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getDaysUntilExpiry = (expiryDate: string) => {
    const today = new Date();
    const expiry = new Date(expiryDate);
    const diffTime = expiry.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  const filteredEstimates = selectedStatus === 'all' 
    ? mockEstimates 
    : selectedStatus === 'pending'
    ? mockEstimates.filter(e => ['sent', 'viewed'].includes(e.status))
    : mockEstimates.filter(e => e.status === selectedStatus);

  const totalValue = filteredEstimates.reduce((sum, estimate) => sum + estimate.value, 0);
  const pendingValue = mockEstimates.filter(e => ['sent', 'viewed'].includes(e.status)).reduce((sum, e) => sum + e.value, 0);

  return (
    <div className="flex flex-col h-full">
      {/* Search and Summary */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search estimates..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <FileText size={16} className="mr-2" />
            New
          </Button>
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="bg-card rounded-lg p-3 border border-stroke">
            <div className="text-xs text-muted-foreground">Total Value</div>
            <div className="font-semibold text-sm">${totalValue.toLocaleString()}</div>
          </div>
          <div className="bg-card rounded-lg p-3 border border-stroke">
            <div className="text-xs text-muted-foreground">Pending Response</div>
            <div className="font-semibold text-sm">${pendingValue.toLocaleString()}</div>
          </div>
        </div>

        {/* Status Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {statuses.map((status) => (
            <button
              key={status.id}
              onClick={() => setSelectedStatus(status.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedStatus === status.id
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {status.label} ({status.count})
            </button>
          ))}
        </div>
      </div>

      {/* Estimates List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredEstimates.map((estimate) => {
            const daysUntilExpiry = getDaysUntilExpiry(estimate.expiryDate);
            const isExpiringSoon = daysUntilExpiry <= 7 && daysUntilExpiry > 0;
            
            return (
              <div
                key={estimate.id}
                className="p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
              >
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0 mt-1">
                      <FileText size={16} className="text-muted-foreground" />
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-sm truncate">
                        {estimate.customerName}
                      </div>
                      <div className="text-xs text-muted-foreground truncate">
                        {estimate.type}
                      </div>
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <div className="font-semibold text-sm">
                      ${estimate.value.toLocaleString()}
                    </div>
                    <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(estimate.status)}`}>
                      {estimate.status}
                    </Badge>
                  </div>
                </div>

                {/* Details */}
                <div className="space-y-2 mb-3">
                  <div className="flex items-center text-xs text-muted-foreground">
                    <MapPin size={10} className="mr-2 flex-shrink-0" />
                    <span className="truncate">{estimate.address}</span>
                  </div>
                  
                  <div className="flex items-center justify-between text-xs text-muted-foreground">
                    <div className="flex items-center">
                      <Calendar size={10} className="mr-2 flex-shrink-0" />
                      <span>Created {formatDate(estimate.createdDate)}</span>
                    </div>
                    
                    <div className={`flex items-center ${isExpiringSoon ? 'text-orange-600' : ''}`}>
                      <span>Expires {formatDate(estimate.expiryDate)}</span>
                      {isExpiringSoon && (
                        <span className="ml-1">⚠️</span>
                      )}
                    </div>
                  </div>
                  
                  {estimate.lastActivity && (
                    <div className="text-xs text-muted-foreground">
                      {estimate.lastActivity}
                    </div>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center space-x-2 pt-3 border-t border-stroke">
                  {estimate.status === 'draft' && (
                    <>
                      <Button size="sm" className="h-8 px-3 text-xs">
                        <Send size={12} className="mr-1" />
                        Send
                      </Button>
                      <Button variant="ghost" size="sm" className="h-8 px-3 text-xs">
                        <Edit size={12} className="mr-1" />
                        Edit
                      </Button>
                    </>
                  )}
                  
                  {estimate.status === 'sent' || estimate.status === 'viewed' ? (
                    <Button size="sm" variant="outline" className="h-8 px-3 text-xs">
                      Resend
                    </Button>
                  ) : null}
                  
                  <div className="flex-1"></div>
                  
                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-destructive hover:text-destructive">
                    <Trash2 size={12} />
                  </Button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}