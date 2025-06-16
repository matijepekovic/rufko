import { useState, useEffect } from 'react';
import { MapPin, Navigation, Clock, Phone, Route, Fuel, Timer, ArrowRight, Search, Filter } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';

interface JobLocation {
  id: string;
  lat: number;
  lng: number;
  address: string;
  customerName: string;
  phone: string;
  scheduledTime: string;
  estimatedDuration: number;
  type: string;
  priority: 'high' | 'medium' | 'low';
  status: 'scheduled' | 'in-progress' | 'completed';
  date: string;
}

interface RouteOptimization {
  totalDistance: number;
  totalTime: number;
  fuelCost: number;
  optimizedOrder: string[];
  timeSaved: number;
}

export function JobRoutesTab() {
  const [selectedDate, setSelectedDate] = useState('2024-06-15');
  const [jobLocations, setJobLocations] = useState<JobLocation[]>([]);
  const [routeOptimization, setRouteOptimization] = useState<RouteOptimization | null>(null);
  const [isOptimizing, setIsOptimizing] = useState(false);

  // Mock job locations data
  const mockJobLocations: JobLocation[] = [
    {
      id: '1',
      lat: 41.8781,
      lng: -87.6298,
      address: '123 Oak Street, Chicago, IL',
      customerName: 'Sarah Johnson',
      phone: '(555) 123-4567',
      scheduledTime: '9:00 AM',
      estimatedDuration: 120,
      type: 'Roof Inspection',
      priority: 'high',
      status: 'scheduled',
      date: '2024-06-15'
    },
    {
      id: '2',
      lat: 41.8851,
      lng: -87.6311,
      address: '456 Pine Avenue, Chicago, IL',
      customerName: 'Mike Chen',
      phone: '(555) 987-6543',
      scheduledTime: '11:30 AM',
      estimatedDuration: 240,
      type: 'Emergency Repair',
      priority: 'high',
      status: 'scheduled',
      date: '2024-06-15'
    },
    {
      id: '3',
      lat: 41.8701,
      lng: -87.6398,
      address: '789 Maple Drive, Chicago, IL',
      customerName: 'Emily Rodriguez',
      phone: '(555) 456-7890',
      scheduledTime: '2:00 PM',
      estimatedDuration: 60,
      type: 'Quote Consultation',
      priority: 'medium',
      status: 'scheduled',
      date: '2024-06-15'
    },
    {
      id: '4',
      lat: 41.8821,
      lng: -87.6198,
      address: '321 Elm Street, Chicago, IL',
      customerName: 'David Wilson',
      phone: '(555) 555-1234',
      scheduledTime: '10:00 AM',
      estimatedDuration: 360,
      type: 'Installation',
      priority: 'high',
      status: 'scheduled',
      date: '2024-06-17'
    }
  ];

  useEffect(() => {
    setJobLocations(mockJobLocations);
  }, []);

  const availableDates = [...new Set(jobLocations.map(job => job.date))].sort();
  const filteredJobs = jobLocations.filter(job => job.date === selectedDate);

  const getPriorityColor = (priority: JobLocation['priority']) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusColor = (status: JobLocation['status']) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'in-progress': return 'bg-blue-100 text-blue-800';
      case 'scheduled': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleOptimizeRoute = async () => {
    if (filteredJobs.length < 2) return;
    
    setIsOptimizing(true);
    
    // Mock route optimization calculation
    setTimeout(() => {
      const optimization: RouteOptimization = {
        totalDistance: 28.4,
        totalTime: 215, // minutes
        fuelCost: 9.80,
        optimizedOrder: filteredJobs.map(j => j.id),
        timeSaved: 45 // minutes saved
      };
      setRouteOptimization(optimization);
      setIsOptimizing(false);
    }, 2000);
  };

  const handleNavigateToJob = (address: string) => {
    const encodedAddress = encodeURIComponent(address);
    window.open(`https://maps.google.com/maps?daddr=${encodedAddress}`, '_blank');
  };

  const handleCall = (phone: string) => {
    window.open(`tel:${phone}`, '_self');
  };

  const handleStartRoute = () => {
    if (filteredJobs.length === 0) return;
    
    // Create multi-stop route in Google Maps
    const waypoints = filteredJobs.slice(1, -1).map(job => 
      encodeURIComponent(job.address)
    ).join('|');
    
    const origin = encodeURIComponent(filteredJobs[0].address);
    const destination = encodeURIComponent(filteredJobs[filteredJobs.length - 1].address);
    
    let mapsUrl = `https://maps.google.com/maps?saddr=${origin}&daddr=${destination}`;
    if (waypoints) {
      mapsUrl += `&waypoints=${waypoints}`;
    }
    
    window.open(mapsUrl, '_blank');
  };

  const formatTime = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header Controls */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-2">
            <div className="p-2 rounded-lg bg-primary/10">
              <Route className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h2 className="font-medium">Job Routes</h2>
              <p className="text-xs text-muted-foreground">Optimize routes between scheduled jobs</p>
            </div>
          </div>
          {filteredJobs.length > 1 && routeOptimization && (
            <Button size="sm" onClick={handleStartRoute}>
              <Navigation className="w-4 h-4 mr-2" />
              Start Route
            </Button>
          )}
        </div>

        {/* Date Selector */}
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <select
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm appearance-none"
            >
              {availableDates.map(date => (
                <option key={date} value={date}>
                  {new Date(date).toLocaleDateString('en-US', { 
                    weekday: 'long', 
                    month: 'short', 
                    day: 'numeric' 
                  })}
                </option>
              ))}
            </select>
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Filter size={16} />
          </Button>
        </div>

        {/* Route Optimization Controls */}
        {filteredJobs.length > 1 && (
          <div className="flex items-center justify-between p-3 bg-background rounded-lg border border-stroke">
            <div className="flex items-center space-x-2">
              <Route className="w-4 h-4 text-primary" />
              <div>
                <span className="text-sm font-medium">Route Optimization</span>
                <p className="text-xs text-muted-foreground">
                  Optimize travel between {filteredJobs.length} jobs
                </p>
              </div>
            </div>
            <Button 
              size="sm" 
              onClick={handleOptimizeRoute}
              disabled={isOptimizing}
            >
              {isOptimizing ? 'Optimizing...' : 'Optimize Route'}
            </Button>
          </div>
        )}

        {/* Route Stats */}
        {routeOptimization && (
          <div className="mt-3 p-3 bg-green-50 rounded-lg border border-green-200">
            <div className="grid grid-cols-4 gap-4 text-center">
              <div>
                <p className="text-lg font-semibold text-green-700">{routeOptimization.totalDistance} mi</p>
                <p className="text-xs text-green-600">Distance</p>
              </div>
              <div>
                <p className="text-lg font-semibold text-green-700">{formatTime(routeOptimization.totalTime)}</p>
                <p className="text-xs text-green-600">Travel Time</p>
              </div>
              <div>
                <p className="text-lg font-semibold text-green-700">${routeOptimization.fuelCost}</p>
                <p className="text-xs text-green-600">Fuel Cost</p>
              </div>
              <div>
                <p className="text-lg font-semibold text-green-700">{formatTime(routeOptimization.timeSaved)}</p>
                <p className="text-xs text-green-600">Time Saved</p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Job Route List */}
      <div className="flex-1 overflow-y-auto scrollable">
        {/* Map Placeholder */}
        <div className="p-4">
          <div className="aspect-video bg-gray-100 rounded-lg border border-stroke flex items-center justify-center mb-4">
            <div className="text-center">
              <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">Route Map</p>
              <p className="text-xs text-muted-foreground">
                {filteredJobs.length} scheduled jobs for {new Date(selectedDate).toLocaleDateString()}
              </p>
            </div>
          </div>
        </div>

        {/* Jobs List */}
        <div className="px-4 pb-4 space-y-3">
          {filteredJobs.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No jobs scheduled for this date</p>
            </div>
          ) : (
            filteredJobs.map((job, index) => (
              <Card key={job.id} className="cursor-pointer hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-sm font-medium">
                        {index + 1}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-medium text-sm truncate">
                          {job.customerName}
                        </div>
                        <p className="text-xs text-muted-foreground truncate">{job.type}</p>
                      </div>
                    </div>
                    <div className="flex flex-col items-end space-y-1">
                      <Badge className={`text-xs px-2 py-0.5 ${getPriorityColor(job.priority)}`}>
                        {job.priority}
                      </Badge>
                      <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(job.status)}`}>
                        {job.status}
                      </Badge>
                    </div>
                  </div>

                  <div className="space-y-2 mb-3">
                    <div className="flex items-center text-xs text-muted-foreground">
                      <MapPin size={12} className="mr-2 flex-shrink-0" />
                      <span className="truncate">{job.address}</span>
                    </div>
                    
                    <div className="flex items-center text-xs text-muted-foreground">
                      <Clock size={12} className="mr-2 flex-shrink-0" />
                      <span>{job.scheduledTime} • {formatTime(job.estimatedDuration)} duration</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex items-center justify-between">
                    <div className="flex space-x-1">
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

                    {index < filteredJobs.length - 1 && (
                      <div className="flex items-center space-x-1 text-xs text-muted-foreground">
                        <ArrowRight size={12} />
                        <span>Next job</span>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>
    </div>
  );
}