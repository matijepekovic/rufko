import { useState } from 'react';
import { Phone, MessageSquare, MapPin, Clock, DollarSign, Filter, Search } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent } from './ui/card';
import { Badge } from './ui/badge';
import { useLeadData } from '../hooks/useLeadData';

export function LeadsList() {
  const { leads, loading } = useLeadData();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  const filteredLeads = leads.filter(lead => {
    const matchesSearch = lead.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         lead.phone.includes(searchTerm) ||
                         lead.email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesFilter = filterStatus === 'all' || lead.status === filterStatus;
    
    return matchesSearch && matchesFilter;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'hot': return 'bg-red-100 text-red-800 border-red-200';
      case 'warm': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'cold': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'dormant': return 'bg-gray-100 text-gray-800 border-gray-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const handleCall = (phone: string) => {
    console.log('Calling:', phone);
  };

  const handleMessage = (phone: string) => {
    console.log('Messaging:', phone);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-2"></div>
          <p className="text-sm text-muted-foreground">Loading leads...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Search and Filter Bar */}
      <div className="flex-shrink-0 p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-2">
          <div className="flex-1">
            <Input
              placeholder="Search leads..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full"
            />
          </div>
          <Button variant="outline" size="sm">
            <Filter className="w-4 h-4" />
          </Button>
        </div>
        
        {/* Status Filter Chips */}
        <div className="flex space-x-2 overflow-x-auto">
          {['all', 'hot', 'warm', 'cold', 'dormant'].map((status) => (
            <Button
              key={status}
              variant={filterStatus === status ? 'default' : 'outline'}
              size="sm"
              onClick={() => setFilterStatus(status)}
              className="flex-shrink-0 text-xs"
            >
              {status === 'all' ? 'All' : status.charAt(0).toUpperCase() + status.slice(1)}
            </Button>
          ))}
        </div>
      </div>

      {/* Leads List */}
      <div className="flex-1 overflow-y-auto">
        {filteredLeads.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <Search className="w-12 h-12 text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No leads found</h3>
            <p className="text-sm text-gray-500">
              {searchTerm ? 'Try adjusting your search terms' : 'No leads match the current filter'}
            </p>
          </div>
        ) : (
          <div className="p-4 space-y-3">
            {filteredLeads.map((lead) => (
              <Card key={lead.id} className="cursor-pointer hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                      <h3 className="font-medium text-gray-900 mb-1">{lead.name}</h3>
                      <div className="flex items-center text-sm text-gray-500 mb-1">
                        <MapPin className="w-3 h-3 mr-1" />
                        <span className="truncate">{lead.address}</span>
                      </div>
                      <div className="flex items-center text-sm text-gray-500">
                        <Clock className="w-3 h-3 mr-1" />
                        <span>Last contact: {lead.lastContact}</span>
                      </div>
                    </div>
                    <Badge className={`text-xs ml-2 ${getStatusColor(lead.status)}`}>
                      {lead.status}
                    </Badge>
                  </div>

                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center text-lg font-semibold text-gray-900">
                      <DollarSign className="w-4 h-4 mr-1" />
                      {lead.estimatedValue?.toLocaleString() || 'TBD'}
                    </div>
                    <div className="text-sm text-gray-500">
                      {lead.source}
                    </div>
                  </div>

                  {/* Quick Actions */}
                  <div className="flex space-x-2 pt-2 border-t border-gray-200">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleCall(lead.phone);
                      }}
                    >
                      <Phone className="w-3 h-3 mr-1" />
                      Call
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleMessage(lead.phone);
                      }}
                    >
                      <MessageSquare className="w-3 h-3 mr-1" />
                      SMS
                    </Button>
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