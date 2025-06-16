import { useState } from 'react';
import { Calendar, Clock, MapPin, Phone, ArrowRight, Search, Filter, Route, Navigation } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface ScheduledJob {
  id: string;
  customerName: string;
  address: string;
  date: string;
  time: string;
  type: string;
  duration: string;
  phone: string;
  status: 'confirmed' | 'pending' | 'rescheduled';
  isUrgent: boolean;
}

export function ScheduledTab() {
  const [selectedPeriod, setSelectedPeriod] = useState('today');

  const mockScheduledJobs: ScheduledJob[] = [
    {
      id: '1',
      customerName: 'Sarah Johnson',
      address: '123 Oak Street, Springfield',
      date: '2024-06-15',
      time: '9:00 AM',
      type: 'Roof Inspection',
      duration: '2 hours',
      phone: '(555) 123-4567',
      status: 'confirmed',
      isUrgent: false
    },
    {
      id: '2',
      customerName: 'Mike Chen',
      address: '456 Pine Avenue, Downtown',
      date: '2024-06-15',
      time: '11:30 AM',
      type: 'Emergency Repair',
      duration: '4 hours',
      phone: '(555) 987-6543',
      status: 'confirmed',
      isUrgent: true
    },
    {
      id: '3',
      customerName: 'Emily Rodriguez',
      address: '789 Maple Drive, Westside',
      date: '2024-06-16',
      time: '2:00 PM',
      type: 'Quote Consultation',
      duration: '1 hour',
      phone: '(555) 456-7890',
      status: 'pending',
      isUrgent: false
    },
    {
      id: '4',
      customerName: 'David Wilson',
      address: '321 Elm Street, Northgate',
      date: '2024-06-17',
      time: '10:00 AM',
      type: 'Installation',
      duration: '6 hours',
      phone: '(555) 555-1234',
      status: 'confirmed',
      isUrgent: false
    },
    {
      id: '5',
      customerName: 'Lisa Garcia',
      address: '654 Cedar Lane, Southside',
      date: '2024-06-17',
      time: '3:00 PM',
      type: 'Follow-up Inspection',
      duration: '1 hour',
      phone: '(555) 777-8888',
      status: 'rescheduled',
      isUrgent: false
    }
  ];

  const periods = [
    { id: 'today', label: 'Today', count: mockScheduledJobs.filter(j => j.date === '2024-06-15').length },
    { id: 'tomorrow', label: 'Tomorrow', count: mockScheduledJobs.filter(j => j.date === '2024-06-16').length },
    { id: 'week', label: 'This Week', count: mockScheduledJobs.length },
    { id: 'month', label: 'This Month', count: mockScheduledJobs.length }
  ];

  const getStatusColor = (status: ScheduledJob['status']) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      case 'rescheduled': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (date.toDateString() === today.toDateString()) return 'Today';
    if (date.toDateString() === tomorrow.toDateString()) return 'Tomorrow';
    return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  };

  const handleCall = (phone: string) => {
    window.open(`tel:${phone}`, '_self');
  };

  const handleOptimizeRoute = (date: string) => {
    console.log(`Optimizing route for ${date}...`);
    // This would integrate with the RouteMapTab functionality
  };

  const handleNavigateToJob = (address: string) => {
    // Open navigation app
    const encodedAddress = encodeURIComponent(address);
    window.open(`https://maps.google.com/maps?daddr=${encodedAddress}`, '_blank');
  };

  const groupedJobs = mockScheduledJobs.reduce((groups, job) => {
    const date = job.date;
    if (!groups[date]) groups[date] = [];
    groups[date].push(job);
    return groups;
  }, {} as Record<string, ScheduledJob[]>);

  return (
    <div className="flex flex-col h-full">
      {/* Search and Filters */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search scheduled jobs..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Calendar size={16} />
          </Button>
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

      {/* Scheduled Jobs List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-4">
          {Object.entries(groupedJobs).map(([date, jobs]) => (
            <div key={date}>
              {/* Date Header */}
              <div className="flex items-center space-x-2 mb-3">
                <h3 className="font-medium text-sm">{formatDate(date)}</h3>
                <div className="flex-1 h-px bg-border"></div>
                <span className="text-xs text-muted-foreground">{jobs.length} jobs</span>
                {jobs.length > 1 && (
                  <Button 
                    size="sm" 
                    variant="outline" 
                    className="h-6 px-2 text-xs"
                    onClick={() => handleOptimizeRoute(date)}
                  >
                    <Route className="w-3 h-3 mr-1" />
                    Optimize Route
                  </Button>
                )}
              </div>

              {/* Jobs for this date */}
              <div className="space-y-3">
                {jobs.map((job) => (
                  <div
                    key={job.id}
                    className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
                  >
                    <Avatar className="h-10 w-10">
                      <div className="w-full h-full bg-primary/10 flex items-center justify-center">
                        <span className="text-primary font-semibold text-xs">
                          {job.customerName.split(' ').map(n => n[0]).join('')}
                        </span>
                      </div>
                    </Avatar>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2 mb-1">
                        <div className="font-medium text-sm truncate">
                          {job.customerName}
                        </div>
                        {job.isUrgent && (
                          <Badge className="text-xs bg-red-100 text-red-800">
                            Urgent
                          </Badge>
                        )}
                      </div>
                      
                      <div className="text-xs text-muted-foreground truncate mb-1">
                        {job.type}
                      </div>
                      
                      <div className="flex items-center text-xs text-muted-foreground">
                        <MapPin size={10} className="mr-1 flex-shrink-0" />
                        <span className="truncate">{job.address}</span>
                      </div>
                    </div>
                    
                    <div className="text-right">
                      <div className="flex items-center text-xs bg-muted px-2 py-1 rounded-full mb-1">
                        <Clock size={10} className="mr-1" />
                        {job.time}
                      </div>
                      <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(job.status)}`}>
                        {job.status}
                      </Badge>
                    </div>
                    
                    <div className="flex items-center space-x-1">
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
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}