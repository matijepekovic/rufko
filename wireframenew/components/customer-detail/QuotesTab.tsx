import { useState } from 'react';
import { FileText, DollarSign, Calendar, Send, Plus, MoreVertical } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { KanbanCardData } from '../KanbanCard';

interface QuotesTabProps {
  customer: KanbanCardData;
}

interface Quote {
  id: string;
  title: string;
  amount: string;
  status: 'draft' | 'sent' | 'viewed' | 'accepted' | 'declined';
  createdDate: string;
  validUntil: string;
  items: number;
}

export function QuotesTab({ customer }: QuotesTabProps) {
  // Safe access to customer properties
  const customerName = customer?.customerName || 'Unknown Customer';

  const [quotes] = useState<Quote[]>([
    {
      id: '1',
      title: 'Roof Repair & Gutter Replacement',
      amount: '$12,450',
      status: 'sent',
      createdDate: '2 days ago',
      validUntil: '28 days',
      items: 8
    },
    {
      id: '2',
      title: 'Emergency Roof Patch',
      amount: '$850',
      status: 'accepted',
      createdDate: '1 week ago',
      validUntil: 'Accepted',
      items: 3
    },
    {
      id: '3',
      title: 'Initial Assessment Quote',
      amount: '$2,100',
      status: 'viewed',
      createdDate: '2 weeks ago',
      validUntil: '14 days',
      items: 5
    }
  ]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return 'bg-gray-100 text-gray-700';
      case 'sent': return 'bg-blue-100 text-blue-700';
      case 'viewed': return 'bg-yellow-100 text-yellow-800';
      case 'accepted': return 'bg-green-100 text-green-700';
      case 'declined': return 'bg-red-100 text-red-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStatusLabel = (status: string) => {
    return status.charAt(0).toUpperCase() + status.slice(1);
  };

  if (quotes.length === 0) {
    return (
      <div className="p-4">
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
            <FileText className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No quotes yet</h3>
          <p className="text-sm text-gray-500 mb-6 max-w-sm">
            Create your first quote for {customerName} to get started.
          </p>
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Create Quote
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-lg font-medium text-gray-900">Quotes</h2>
          <p className="text-sm text-gray-500">{quotes.length} quote{quotes.length !== 1 ? 's' : ''} for {customerName}</p>
        </div>
        <Button>
          <Plus className="w-4 h-4 mr-2" />
          New Quote
        </Button>
      </div>

      {/* Quotes List */}
      <div className="space-y-4">
        {quotes.map((quote) => (
          <Card key={quote.id} className="cursor-pointer hover:shadow-sm transition-shadow">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium text-gray-900 mb-1">{quote.title}</h3>
                  <div className="flex items-center space-x-4 text-sm text-gray-500">
                    <span>{quote.items} items</span>
                    <span>Created {quote.createdDate}</span>
                  </div>
                </div>
                <Button variant="ghost" size="sm">
                  <MoreVertical className="w-4 h-4" />
                </Button>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <div className="flex items-center space-x-1">
                    <DollarSign className="w-4 h-4 text-gray-500" />
                    <span className="font-medium text-gray-900">{quote.amount}</span>
                  </div>
                  <Badge className={getStatusColor(quote.status)}>
                    {getStatusLabel(quote.status)}
                  </Badge>
                </div>

                <div className="flex items-center space-x-2">
                  {quote.status === 'accepted' ? (
                    <Badge variant="outline" className="text-green-600 border-green-200">
                      <Calendar className="w-3 h-3 mr-1" />
                      {quote.validUntil}
                    </Badge>
                  ) : (
                    <span className="text-xs text-gray-500">
                      Valid for {quote.validUntil}
                    </span>
                  )}
                  
                  <div className="flex space-x-1">
                    <Button variant="ghost" size="sm">
                      <FileText className="w-4 h-4" />
                    </Button>
                    {quote.status === 'draft' && (
                      <Button variant="ghost" size="sm">
                        <Send className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                </div>
              </div>

              {/* Quote Actions */}
              {quote.status === 'sent' && (
                <div className="mt-3 pt-3 border-t border-gray-100">
                  <div className="flex space-x-2">
                    <Button variant="outline" size="sm">
                      Follow Up
                    </Button>
                    <Button variant="outline" size="sm">
                      Resend
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Summary Card */}
      <Card className="mt-6">
        <CardContent className="p-4">
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-sm text-gray-500">Total Quoted</p>
              <p className="text-lg font-medium text-gray-900">$15,400</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Accepted</p>
              <p className="text-lg font-medium text-green-600">$850</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Pending</p>
              <p className="text-lg font-medium text-blue-600">$14,550</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}