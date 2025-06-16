import { useState } from 'react';
import { Archive, Calendar, Filter, Search, Eye, Download } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface ArchivedItem {
  id: string;
  name: string;
  type: 'job' | 'quote' | 'contract' | 'invoice';
  customer: string;
  value?: number;
  dateArchived: string;
  originalDate: string;
  status: 'completed' | 'cancelled' | 'expired' | 'paid';
}

export function ArchiveTab() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [selectedPeriod, setSelectedPeriod] = useState<string>('all');

  const mockArchivedItems: ArchivedItem[] = [
    {
      id: '1',
      name: 'Wilson Building Roof Replacement',
      type: 'job',
      customer: 'Wilson Building Corp',
      value: 12000,
      dateArchived: '1 week ago',
      originalDate: '2024-05-15',
      status: 'completed'
    },
    {
      id: '2',
      name: 'Thompson Residence Quote #1247',
      type: 'quote',
      customer: 'Sarah Thompson',
      value: 5800,
      dateArchived: '2 weeks ago',
      originalDate: '2024-04-20',
      status: 'expired'
    },
    {
      id: '3',
      name: 'Garcia Estate Service Contract',
      type: 'contract',
      customer: 'Garcia Estate',
      value: 15000,
      dateArchived: '1 month ago',
      originalDate: '2024-03-10',
      status: 'completed'
    },
    {
      id: '4',
      name: 'Miller House Emergency Repair',
      type: 'job',
      customer: 'David Miller',
      value: 1800,
      dateArchived: '1 month ago',
      originalDate: '2024-03-25',
      status: 'completed'
    },
    {
      id: '5',
      name: 'Invoice #1205 - Johnson Property',
      type: 'invoice',
      customer: 'Johnson Property LLC',
      value: 3200,
      dateArchived: '2 months ago',
      originalDate: '2024-02-14',
      status: 'paid'
    },
    {
      id: '6',
      name: 'Davis Home Inspection Quote',
      type: 'quote',
      customer: 'Emily Davis',
      value: 450,
      dateArchived: '3 months ago',
      originalDate: '2024-01-18',
      status: 'cancelled'
    }
  ];

  const archiveTypes = [
    { id: 'all', label: 'All', count: mockArchivedItems.length },
    { id: 'job', label: 'Jobs', count: mockArchivedItems.filter(i => i.type === 'job').length },
    { id: 'quote', label: 'Quotes', count: mockArchivedItems.filter(i => i.type === 'quote').length },
    { id: 'contract', label: 'Contracts', count: mockArchivedItems.filter(i => i.type === 'contract').length },
    { id: 'invoice', label: 'Invoices', count: mockArchivedItems.filter(i => i.type === 'invoice').length }
  ];

  const timePeriods = [
    { id: 'all', label: 'All Time' },
    { id: 'week', label: 'Last Week' },
    { id: 'month', label: 'Last Month' },
    { id: 'quarter', label: 'Last 3 Months' },
    { id: 'year', label: 'Last Year' }
  ];

  const getStatusColor = (status: ArchivedItem['status']) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'paid': return 'bg-blue-100 text-blue-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      case 'expired': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getTypeColor = (type: ArchivedItem['type']) => {
    switch (type) {
      case 'job': return 'bg-primary/10 text-primary';
      case 'quote': return 'bg-green-100 text-green-800';
      case 'contract': return 'bg-blue-100 text-blue-800';
      case 'invoice': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const filteredItems = mockArchivedItems.filter(item => {
    const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         item.customer.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = selectedType === 'all' || item.type === selectedType;
    return matchesSearch && matchesType;
  });

  const totalValue = filteredItems.reduce((sum, item) => sum + (item.value || 0), 0);

  return (
    <div className="flex flex-col h-full">
      {/* Search and Filters */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search archived items..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Calendar size={16} className="mr-2" />
            {timePeriods.find(p => p.id === selectedPeriod)?.label}
          </Button>
        </div>

        {/* Summary Stats */}
        <div className="flex items-center justify-between mb-4">
          <div className="text-sm text-muted-foreground">
            {filteredItems.length} archived items
          </div>
          <div className="text-sm font-medium">
            Total Value: ${totalValue.toLocaleString()}
          </div>
        </div>

        {/* Type Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {archiveTypes.map((type) => (
            <button
              key={type.id}
              onClick={() => setSelectedType(type.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedType === type.id
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {type.label} ({type.count})
            </button>
          ))}
        </div>
      </div>

      {/* Archive List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredItems.map((item) => (
            <div
              key={item.id}
              className="flex items-center space-x-3 p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              <div className="flex-shrink-0">
                <Archive size={20} className="text-muted-foreground" />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="font-medium text-sm truncate mb-1">
                  {item.name}
                </div>
                <div className="text-xs text-muted-foreground truncate mb-2">
                  {item.customer}
                </div>
                
                <div className="flex items-center space-x-2 flex-wrap gap-1">
                  <Badge className={`text-xs px-2 py-0.5 ${getTypeColor(item.type)}`}>
                    {item.type}
                  </Badge>
                  <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(item.status)}`}>
                    {item.status}
                  </Badge>
                  {item.value && (
                    <span className="text-xs font-medium text-primary">
                      ${item.value.toLocaleString()}
                    </span>
                  )}
                </div>
                
                <div className="flex items-center space-x-2 mt-2 text-xs text-muted-foreground">
                  <span>Archived {item.dateArchived}</span>
                  <span>•</span>
                  <span>Original: {item.originalDate}</span>
                </div>
              </div>
              
              <div className="flex items-center space-x-1">
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Eye size={16} />
                </Button>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Download size={16} />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}