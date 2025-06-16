import { useState } from 'react';
import { FileText, Calendar, DollarSign, Eye, Plus, Filter, Search } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent } from './ui/card';
import { Badge } from './ui/badge';

interface Quote {
  id: string;
  customerName: string;
  title: string;
  status: 'draft' | 'sent' | 'viewed' | 'approved' | 'rejected' | 'expired';
  total: number;
  createdDate: string;
  validUntil: string;
  customerPhone: string;
}

export function QuotesList() {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  const quotes: Quote[] = [
    {
      id: 'Q-2024-001',
      customerName: 'Thompson Residence',
      title: 'Roof Repair & Gutter Replacement',
      status: 'sent',
      total: 2500,
      createdDate: 'June 10, 2024',
      validUntil: 'July 10, 2024',
      customerPhone: '(555) 123-4567'
    },
    {
      id: 'Q-2024-002',
      customerName: 'Johnson Property',
      title: 'Full Roof Replacement',
      status: 'approved',
      total: 8500,
      createdDate: 'June 5, 2024',
      validUntil: 'July 5, 2024',
      customerPhone: '(555) 987-6543'
    },
    {
      id: 'Q-2024-003',
      customerName: 'Davis Home',
      title: 'Gutter Installation',
      status: 'viewed',
      total: 1200,
      createdDate: 'June 8, 2024',
      validUntil: 'July 8, 2024',
      customerPhone: '(555) 456-7890'
    },
    {
      id: 'Q-2024-004',
      customerName: 'Wilson Building',
      title: 'Commercial Roof Maintenance',
      status: 'draft',
      total: 15000,
      createdDate: 'June 12, 2024',
      validUntil: 'July 12, 2024',
      customerPhone: '(555) 321-0987'
    },
    {
      id: 'Q-2024-005',
      customerName: 'Miller House',
      title: 'Emergency Roof Repair',
      status: 'expired',
      total: 3200,
      createdDate: 'May 15, 2024',
      validUntil: 'June 15, 2024',
      customerPhone: '(555) 555-0123'
    }
  ];

  const filteredQuotes = quotes.filter(quote => {
    const matchesSearch = quote.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         quote.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         quote.id.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterStatus === 'all' || quote.status === filterStatus;
    
    return matchesSearch && matchesFilter;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'sent': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'viewed': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'approved': return 'bg-green-100 text-green-800 border-green-200';
      case 'rejected': return 'bg-red-100 text-red-800 border-red-200';
      case 'expired': return 'bg-gray-100 text-gray-600 border-gray-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'draft': return 'Draft';
      case 'sent': return 'Sent';
      case 'viewed': return 'Viewed';
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'expired': return 'Expired';
      default: return status;
    }
  };

  const getStatusPriority = (status: string) => {
    const priorities = {
      'approved': 1,
      'viewed': 2,
      'sent': 3,
      'draft': 4,
      'rejected': 5,
      'expired': 6
    };
    return priorities[status as keyof typeof priorities] || 7;
  };

  const sortedQuotes = [...filteredQuotes].sort((a, b) => {
    return getStatusPriority(a.status) - getStatusPriority(b.status);
  });

  const totalValue = quotes.reduce((sum, quote) => sum + quote.total, 0);
  const activeQuotes = quotes.filter(q => !['rejected', 'expired'].includes(q.status));

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Search and Filter Bar */}
      <div className="flex-shrink-0 p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-2">
          <div className="flex-1">
            <Input
              placeholder="Search quotes..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full"
            />
          </div>
          <Button variant="outline" size="sm">
            <Filter className="w-4 h-4" />
          </Button>
          <Button size="sm">
            <Plus className="w-4 h-4" />
          </Button>
        </div>
        
        {/* Status Filter Chips */}
        <div className="flex space-x-2 overflow-x-auto">
          {['all', 'draft', 'sent', 'viewed', 'approved', 'rejected'].map((status) => (
            <Button
              key={status}
              variant={filterStatus === status ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilterStatus(status)}
              className="flex-shrink-0 text-xs"
            >
              {status === 'all' ? 'All' : getStatusLabel(status)}
            </Button>
          ))}
        </div>

        {/* Summary Stats */}
        <div className="grid grid-cols-3 gap-4 mt-3 pt-3 border-t border-gray-200">
          <div className="text-center">
            <p className="text-lg font-semibold text-gray-900">{quotes.length}</p>
            <p className="text-xs text-gray-500">Total Quotes</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-semibold text-gray-900">{activeQuotes.length}</p>
            <p className="text-xs text-gray-500">Active</p>
          </div>
          <div className="text-center">
            <p className="text-lg font-semibold text-gray-900">${totalValue.toLocaleString()}</p>
            <p className="text-xs text-gray-500">Total Value</p>
          </div>
        </div>
      </div>

      {/* Quotes List */}
      <div className="flex-1 overflow-y-auto">
        {sortedQuotes.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <FileText className="w-12 h-12 text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No quotes found</h3>
            <p className="text-sm text-gray-500 mb-4">
              {searchTerm ? 'Try adjusting your search terms' : 'No quotes match the current filter'}
            </p>
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Create Quote
            </Button>
          </div>
        ) : (
          <div className="p-4 space-y-3">
            {sortedQuotes.map((quote) => (
              <Card key={quote.id} className="cursor-pointer hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                      <h3 className="font-medium text-gray-900 mb-1">{quote.title}</h3>
                      <p className="text-sm text-gray-500 mb-1">{quote.customerName}</p>
                      <p className="text-xs text-gray-400">Quote #{quote.id}</p>
                    </div>
                    <Badge className={`text-xs ml-2 ${getStatusColor(quote.status)}`}>
                      {getStatusLabel(quote.status)}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center text-lg font-semibold text-gray-900">
                      <DollarSign className="w-4 h-4 mr-1" />
                      {quote.total.toLocaleString()}
                    </div>
                    <Button variant="ghost" size="sm">
                      <Eye className="w-4 h-4 mr-1" />
                      View
                    </Button>
                  </div>

                  <div className="flex items-center justify-between text-xs text-gray-500">
                    <div className="flex items-center">
                      <Calendar className="w-3 h-3 mr-1" />
                      Created {quote.createdDate}
                    </div>
                    <div className={quote.status === 'expired' ? 'text-red-500' : ''}>
                      Valid until {quote.validUntil}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}