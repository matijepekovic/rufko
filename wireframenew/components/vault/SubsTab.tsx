import { useState } from 'react';
import { Users, Phone, Star, Search, Plus, Filter } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface SubContractor {
  id: string;
  name: string;
  company: string;
  trade: string;
  phone: string;
  rating: number;
  status: 'active' | 'inactive';
  jobsCompleted: number;
}

export function SubsTab() {
  const [selectedTrade, setSelectedTrade] = useState('All');

  const mockSubContractors: SubContractor[] = [
    {
      id: '1',
      name: 'John Martinez',
      company: 'Elite Roofing Solutions',
      trade: 'Roofing',
      phone: '(555) 123-4567',
      rating: 4.8,
      status: 'active',
      jobsCompleted: 23
    },
    {
      id: '2',
      name: 'Sarah Kim',
      company: 'Perfect Gutters Inc.',
      trade: 'Gutters',
      phone: '(555) 987-6543',
      rating: 4.9,
      status: 'active',
      jobsCompleted: 18
    },
    {
      id: '3',
      name: 'Mike Thompson',
      company: 'Thompson Electrical',
      trade: 'Electrical',
      phone: '(555) 456-7890',
      rating: 4.7,
      status: 'active',
      jobsCompleted: 31
    },
    {
      id: '4',
      name: 'Lisa Chen',
      company: 'Pro Insulation Co.',
      trade: 'Insulation',
      phone: '(555) 321-0987',
      rating: 4.6,
      status: 'active',
      jobsCompleted: 15
    },
    {
      id: '5',
      name: 'Robert Davis',
      company: 'Davis HVAC Services',
      trade: 'HVAC',
      phone: '(555) 555-1234',
      rating: 4.5,
      status: 'inactive',
      jobsCompleted: 8
    }
  ];

  const trades = ['All', 'Roofing', 'Gutters', 'Electrical', 'Insulation', 'HVAC', 'Plumbing'];

  const filteredSubs = selectedTrade === 'All' 
    ? mockSubContractors 
    : mockSubContractors.filter(sub => sub.trade === selectedTrade);

  const handleCall = (phone: string) => {
    window.open(`tel:${phone}`, '_self');
  };

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        size={12}
        className={i < Math.floor(rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'}
      />
    ));
  };

  return (
    <div className="flex flex-col h-full">
      {/* Search and Add */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search sub-contractors..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <Plus size={16} className="mr-2" />
            Add
          </Button>
        </div>

        {/* Trade Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {trades.map((trade) => (
            <button
              key={trade}
              onClick={() => setSelectedTrade(trade)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedTrade === trade
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {trade}
            </button>
          ))}
        </div>
      </div>

      {/* Sub-contractors List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredSubs.map((sub) => (
            <div
              key={sub.id}
              className="flex items-center space-x-3 p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              <Avatar className="h-12 w-12">
                <div className="w-full h-full bg-primary/10 flex items-center justify-center">
                  <span className="text-primary font-semibold">
                    {sub.name.split(' ').map(n => n[0]).join('')}
                  </span>
                </div>
              </Avatar>
              
              <div className="flex-1 min-w-0">
                <div className="font-medium text-sm truncate">
                  {sub.name}
                </div>
                <div className="text-xs text-muted-foreground truncate">
                  {sub.company}
                </div>
                <div className="flex items-center space-x-3 mt-1">
                  <Badge 
                    variant="secondary" 
                    className={`text-xs ${sub.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}
                  >
                    {sub.trade}
                  </Badge>
                  <div className="flex items-center space-x-1">
                    <div className="flex">
                      {renderStars(sub.rating)}
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {sub.rating}
                    </span>
                  </div>
                  <span className="text-xs text-muted-foreground">
                    {sub.jobsCompleted} jobs
                  </span>
                </div>
              </div>
              
              <Button
                variant="ghost"
                size="sm"
                className="h-10 w-10 p-0 text-green-600 hover:text-green-700 hover:bg-green-50"
                onClick={() => handleCall(sub.phone)}
              >
                <Phone size={18} />
              </Button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}