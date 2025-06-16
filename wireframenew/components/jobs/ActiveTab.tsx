import { useState } from 'react';
import { Clock, MapPin, Phone, Users, Search, Filter, Calendar, Route, Navigation } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface ActiveJob {
  id: string;
  customerName: string;
  address: string;
  startTime: string;
  estimatedCompletion: string;
  progress: number;
  type: string;
  crew: string[];
  phone: string;
  priority: 'high' | 'medium' | 'low';
}

export function ActiveTab() {
  const [selectedFilter, setSelectedFilter] = useState('all');

  const mockActiveJobs: ActiveJob[] = [
    {
      id: '1',
      customerName: 'Wilson Building Corp',
      address: '1234 Business Park Dr, Downtown',
      startTime: '8:00 AM',
      estimatedCompletion: '5:00 PM',
      progress: 65,
      type: 'Commercial Roof Replacement',
      crew: ['John M.', 'Sarah K.', 'Mike T.'],
      phone: '(555) 123-4567',
      priority: 'high'
    },
    {
      id: '2',
      customerName: 'Thompson Residence',
      address: '456 Oak Street, Suburbia',
      startTime: '9:00 AM',
      estimatedCompletion: '3:00 PM',
      progress: 30,
      type: 'Gutter Installation',
      crew: ['Lisa C.', 'Robert D.'],
      phone: '(555) 987-6543',
      priority: 'medium'
    },
    {
      id: '3',
      customerName: 'Garcia Estate',
      address: '789 Hill View Ave, Heights',
      startTime: '10:00 AM',
      estimatedCompletion: '4:00 PM',
      progress: 85,
      type: 'Emergency Repair',
      crew: ['Mike T.', 'John M.'],
      phone: '(555) 456-7890',
      priority: 'high'
    }
  ];

  const filters = [
    { id: 'all', label: 'All', count: mockActiveJobs.length },
    { id: 'high', label: 'High Priority', count: mockActiveJobs.filter(j => j.priority === 'high').length },
    { id: 'behind', label: 'Behind Schedule', count: 1 },
    { id: 'ontrack', label: 'On Track', count: mockActiveJobs.length - 1 }
  ];

  const getPriorityColor = (priority: ActiveJob['priority']) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getProgressColor = (progress: number) => {
    if (progress >= 80) return 'bg-green-500';
    if (progress >= 50) return 'bg-yellow-500';
    return 'bg-blue-500';
  };

  const handleCall = (phone: string) => {
    window.open(`tel:${phone}`, '_self');
  };

  const handleOptimizeRoute = () => {
    console.log('Optimizing route for active jobs...');
    // This would integrate with the RouteMapTab functionality
  };

  const handleNavigateToJob = (address: string) => {
    // Open navigation app
    const encodedAddress = encodeURIComponent(address);
    window.open(`https://maps.google.com/maps?daddr=${encodedAddress}`, '_blank');
  };

  return (
    <div className="flex flex-col h-full">
      {/* Search and Filters */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search active jobs..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Filter size={16} />
          </Button>
        </div>

        {/* Status Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable mb-3">
          {filters.map((filter) => (
            <button
              key={filter.id}
              onClick={() => setSelectedFilter(filter.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedFilter === filter.id
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {filter.label} ({filter.count})
            </button>
          ))}
        </div>

        {/* Route Optimization */}
        {mockActiveJobs.length > 1 && (
          <div className="flex items-center justify-between p-3 bg-background rounded-lg border border-stroke">
            <div className="flex items-center space-x-2">
              <Route className="w-4 h-4 text-primary" />
              <div>
                <span className="text-sm font-medium">Route Optimization</span>
                <p className="text-xs text-muted-foreground">Optimize travel between {mockActiveJobs.length} active jobs</p>
              </div>
            </div>
            <Button size="sm" onClick={handleOptimizeRoute}>
              <Navigation className="w-4 h-4 mr-2" />
              Optimize
            </Button>
          </div>
        )}
      </div>

      {/* Active Jobs List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-4">
          {mockActiveJobs.map((job) => (
            <div
              key={job.id}
              className="p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              {/* Header */}
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-sm truncate">
                    {job.customerName}
                  </div>
                  <div className="text-xs text-muted-foreground truncate mt-1">
                    {job.type}
                  </div>
                </div>
                <div className="flex items-center space-x-1">
                  <Badge className={`text-xs px-2 py-0.5 ${getPriorityColor(job.priority)}`}>
                    {job.priority} priority
                  </Badge>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 w-8 p-0 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                    onClick={() => handleNavigateToJob(job.address)}
                    title="Navigate to job"
                  >
                    <Navigation size={14} />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 w-8 p-0 text-green-600 hover:text-green-700 hover:bg-green-50"
                    onClick={() => handleCall(job.phone)}
                    title="Call customer"
                  >
                    <Phone size={14} />
                  </Button>
                </div>
              </div>

              {/* Progress */}
              <div className="mb-3">
                <div className="flex items-center justify-between text-xs text-muted-foreground mb-1">
                  <span>Progress</span>
                  <span>{job.progress}% complete</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full transition-all ${getProgressColor(job.progress)}`}
                    style={{ width: `${job.progress}%` }}
                  />
                </div>
              </div>

              {/* Details */}
              <div className="space-y-2">
                <div className="flex items-center text-xs text-muted-foreground">
                  <MapPin size={12} className="mr-2 flex-shrink-0" />
                  <span className="truncate">{job.address}</span>
                </div>
                
                <div className="flex items-center text-xs text-muted-foreground">
                  <Clock size={12} className="mr-2 flex-shrink-0" />
                  <span>Started: {job.startTime} • Est. completion: {job.estimatedCompletion}</span>
                </div>
                
                <div className="flex items-center text-xs text-muted-foreground">
                  <Users size={12} className="mr-2 flex-shrink-0" />
                  <span>Crew: {job.crew.join(', ')}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}