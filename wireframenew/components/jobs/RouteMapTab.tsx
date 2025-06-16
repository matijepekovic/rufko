import { useState, useEffect } from 'react';
import { MapPin, Navigation, Users, Clock, Phone, MessageSquare, Mail, Calendar, Plus, Target, Route, Save } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Label } from '../ui/label';

interface Location {
  id: string;
  lat: number;
  lng: number;
  address: string;
  customerName?: string;
  phone?: string;
  email?: string;
  type: 'job' | 'lead' | 'door-knock' | 'completed';
  priority: 'high' | 'medium' | 'low';
  notes?: string;
  scheduledTime?: string;
  estimatedDuration?: number;
  status: 'pending' | 'contacted' | 'interested' | 'not-interested' | 'completed';
  addedAt: Date;
}

interface RouteOptimization {
  totalDistance: number;
  totalTime: number;
  fuelCost: number;
  optimizedOrder: string[];
}

export function RouteMapTab() {
  const [selectedMode, setSelectedMode] = useState<'jobs' | 'door-knock'>('jobs');
  const [locations, setLocations] = useState<Location[]>([]);
  const [selectedLocation, setSelectedLocation] = useState<Location | null>(null);
  const [isAddingLocation, setIsAddingLocation] = useState(false);
  const [routeOptimization, setRouteOptimization] = useState<RouteOptimization | null>(null);
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [newLocationForm, setNewLocationForm] = useState({
    address: '',
    customerName: '',
    phone: '',
    email: '',
    notes: '',
    priority: 'medium' as const,
    type: 'door-knock' as const
  });

  // Mock locations data
  const mockLocations: Location[] = [
    {
      id: '1',
      lat: 41.8781,
      lng: -87.6298,
      address: '123 Oak Street, Chicago, IL',
      customerName: 'John Smith',
      phone: '(555) 123-4567',
      type: 'job',
      priority: 'high',
      status: 'pending',
      scheduledTime: '9:00 AM',
      estimatedDuration: 120,
      addedAt: new Date('2024-06-15T08:00:00')
    },
    {
      id: '2',
      lat: 41.8851,
      lng: -87.6311,
      address: '456 Pine Avenue, Chicago, IL',
      customerName: 'Sarah Johnson',
      phone: '(555) 987-6543',
      email: 'sarah@email.com',
      type: 'door-knock',
      priority: 'medium',
      status: 'interested',
      notes: 'Interested in roof inspection, mentioned recent storm damage',
      addedAt: new Date('2024-06-15T10:30:00')
    },
    {
      id: '3',
      lat: 41.8701,
      lng: -87.6398,
      address: '789 Maple Drive, Chicago, IL',
      type: 'door-knock',
      priority: 'low',
      status: 'not-interested',
      notes: 'Not interested, renting property',
      addedAt: new Date('2024-06-15T11:15:00')
    },
    {
      id: '4',
      lat: 41.8821,
      lng: -87.6198,
      address: '321 Elm Street, Chicago, IL',
      customerName: 'Mike Chen',
      phone: '(555) 456-7890',
      type: 'job',
      priority: 'high',
      status: 'completed',
      scheduledTime: '2:00 PM',
      estimatedDuration: 180,
      addedAt: new Date('2024-06-15T14:00:00')
    }
  ];

  useEffect(() => {
    setLocations(mockLocations);
  }, []);

  const filteredLocations = locations.filter(location => {
    if (selectedMode === 'jobs') {
      return location.type === 'job';
    } else {
      return location.type === 'door-knock' || location.type === 'lead';
    }
  });

  const getStatusColor = (status: Location['status']) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'interested': return 'bg-blue-100 text-blue-800';
      case 'contacted': return 'bg-yellow-100 text-yellow-800';
      case 'not-interested': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: Location['priority']) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleOptimizeRoute = async () => {
    setIsOptimizing(true);
    
    // Mock route optimization calculation
    setTimeout(() => {
      const optimization: RouteOptimization = {
        totalDistance: 24.7,
        totalTime: 186, // minutes
        fuelCost: 8.50,
        optimizedOrder: filteredLocations.map(l => l.id)
      };
      setRouteOptimization(optimization);
      setIsOptimizing(false);
    }, 2000);
  };

  const handleAddLocation = () => {
    const newLocation: Location = {
      id: Date.now().toString(),
      lat: 41.8781 + (Math.random() - 0.5) * 0.01,
      lng: -87.6298 + (Math.random() - 0.5) * 0.01,
      address: newLocationForm.address,
      customerName: newLocationForm.customerName || undefined,
      phone: newLocationForm.phone || undefined,
      email: newLocationForm.email || undefined,
      type: newLocationForm.type,
      priority: newLocationForm.priority,
      notes: newLocationForm.notes || undefined,
      status: 'pending',
      addedAt: new Date()
    };

    setLocations(prev => [...prev, newLocation]);
    setNewLocationForm({
      address: '',
      customerName: '',
      phone: '',
      email: '',
      notes: '',
      priority: 'medium',
      type: 'door-knock'
    });
    setIsAddingLocation(false);
  };

  const handleContactCustomer = (location: Location, method: 'call' | 'text' | 'email') => {
    switch (method) {
      case 'call':
        if (location.phone) {
          window.open(`tel:${location.phone}`, '_self');
        }
        break;
      case 'text':
        if (location.phone) {
          window.open(`sms:${location.phone}`, '_self');
        }
        break;
      case 'email':
        if (location.email) {
          window.open(`mailto:${location.email}`, '_self');
        }
        break;
    }

    // Update status to contacted
    setLocations(prev => 
      prev.map(l => 
        l.id === location.id 
          ? { ...l, status: 'contacted' as const }
          : l
      )
    );
  };

  const updateLocationStatus = (locationId: string, status: Location['status']) => {
    setLocations(prev => 
      prev.map(l => 
        l.id === locationId 
          ? { ...l, status }
          : l
      )
    );
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
              <h2 className="font-medium">Route Planning</h2>
              <p className="text-xs text-muted-foreground">Optimize routes & manage door knocking</p>
            </div>
          </div>
          <Button size="sm" onClick={() => setIsAddingLocation(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Add Location
          </Button>
        </div>

        {/* Mode Switcher */}
        <div className="flex space-x-2 mb-4">
          <Button
            variant={selectedMode === 'jobs' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedMode('jobs')}
          >
            <Navigation className="w-4 h-4 mr-2" />
            Job Routes
          </Button>
          <Button
            variant={selectedMode === 'door-knock' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedMode('door-knock')}
          >
            <Target className="w-4 h-4 mr-2" />
            Door Knocking
          </Button>
        </div>

        {/* Route Optimization */}
        {filteredLocations.length > 1 && (
          <div className="flex items-center justify-between p-3 bg-background rounded-lg border border-stroke">
            <div className="flex items-center space-x-2">
              <Route className="w-4 h-4 text-primary" />
              <span className="text-sm font-medium">Route Optimization</span>
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
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <p className="text-lg font-semibold text-green-700">{routeOptimization.totalDistance} mi</p>
                <p className="text-xs text-green-600">Total Distance</p>
              </div>
              <div>
                <p className="text-lg font-semibold text-green-700">{Math.floor(routeOptimization.totalTime / 60)}h {routeOptimization.totalTime % 60}m</p>
                <p className="text-xs text-green-600">Est. Time</p>
              </div>
              <div>
                <p className="text-lg font-semibold text-green-700">${routeOptimization.fuelCost}</p>
                <p className="text-xs text-green-600">Fuel Cost</p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Map Placeholder & Location List */}
      <div className="flex-1 overflow-y-auto scrollable">
        {/* Map Placeholder */}
        <div className="p-4">
          <div className="aspect-video bg-gray-100 rounded-lg border border-stroke flex items-center justify-center mb-4">
            <div className="text-center">
              <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">Interactive Map</p>
              <p className="text-xs text-muted-foreground">{filteredLocations.length} locations</p>
            </div>
          </div>
        </div>

        {/* Locations List */}
        <div className="px-4 pb-4 space-y-3">
          {filteredLocations.map((location, index) => (
            <Card key={location.id} className="cursor-pointer hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-xs font-medium text-primary bg-primary/10 px-2 py-1 rounded">
                        #{index + 1}
                      </span>
                      {location.customerName && (
                        <span className="font-medium text-sm truncate">
                          {location.customerName}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground truncate">{location.address}</p>
                    {location.scheduledTime && (
                      <p className="text-xs text-muted-foreground mt-1">
                        <Clock className="w-3 h-3 inline mr-1" />
                        {location.scheduledTime} ({location.estimatedDuration}min)
                      </p>
                    )}
                  </div>
                  <div className="flex flex-col items-end space-y-1">
                    <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(location.status)}`}>
                      {location.status.replace('-', ' ')}
                    </Badge>
                    <Badge className={`text-xs px-2 py-0.5 ${getPriorityColor(location.priority)}`}>
                      {location.priority}
                    </Badge>
                  </div>
                </div>

                {location.notes && (
                  <p className="text-xs text-muted-foreground mb-3 p-2 bg-muted rounded">
                    {location.notes}
                  </p>
                )}

                {/* Action Buttons */}
                <div className="flex items-center justify-between">
                  <div className="flex space-x-1">
                    {location.phone && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => handleContactCustomer(location, 'call')}
                      >
                        <Phone className="w-4 h-4 text-green-600" />
                      </Button>
                    )}
                    {location.phone && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => handleContactCustomer(location, 'text')}
                      >
                        <MessageSquare className="w-4 h-4 text-blue-600" />
                      </Button>
                    )}
                    {location.email && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => handleContactCustomer(location, 'email')}
                      >
                        <Mail className="w-4 h-4 text-purple-600" />
                      </Button>
                    )}
                  </div>

                  {selectedMode === 'door-knock' && location.type === 'door-knock' && (
                    <div className="flex space-x-1">
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-8 px-2 text-xs"
                        onClick={() => updateLocationStatus(location.id, 'interested')}
                      >
                        Interested
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-8 px-2 text-xs"
                        onClick={() => updateLocationStatus(location.id, 'not-interested')}
                      >
                        Not Interested
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Add Location Dialog */}
      <Dialog open={isAddingLocation} onOpenChange={setIsAddingLocation}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Add New Location</DialogTitle>
            <DialogDescription>
              Add a location for job scheduling or door knocking
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label htmlFor="address">Address *</Label>
              <Input
                id="address"
                value={newLocationForm.address}
                onChange={(e) => setNewLocationForm(prev => ({ ...prev, address: e.target.value }))}
                placeholder="123 Main Street, City, State"
                className="mt-2"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="type">Type</Label>
                <Select value={newLocationForm.type} onValueChange={(value: any) => setNewLocationForm(prev => ({ ...prev, type: value }))}>
                  <SelectTrigger className="mt-2">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="door-knock">Door Knock</SelectItem>
                    <SelectItem value="lead">Lead</SelectItem>
                    <SelectItem value="job">Scheduled Job</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div>
                <Label htmlFor="priority">Priority</Label>
                <Select value={newLocationForm.priority} onValueChange={(value: any) => setNewLocationForm(prev => ({ ...prev, priority: value }))}>
                  <SelectTrigger className="mt-2">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="high">High</SelectItem>
                    <SelectItem value="medium">Medium</SelectItem>
                    <SelectItem value="low">Low</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div>
              <Label htmlFor="customerName">Customer Name</Label>
              <Input
                id="customerName"
                value={newLocationForm.customerName}
                onChange={(e) => setNewLocationForm(prev => ({ ...prev, customerName: e.target.value }))}
                placeholder="John Smith"
                className="mt-2"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="phone">Phone</Label>
                <Input
                  id="phone"
                  value={newLocationForm.phone}
                  onChange={(e) => setNewLocationForm(prev => ({ ...prev, phone: e.target.value }))}
                  placeholder="(555) 123-4567"
                  className="mt-2"
                />
              </div>
              
              <div>
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  value={newLocationForm.email}
                  onChange={(e) => setNewLocationForm(prev => ({ ...prev, email: e.target.value }))}
                  placeholder="john@email.com"
                  className="mt-2"
                />
              </div>
            </div>

            <div>
              <Label htmlFor="notes">Notes</Label>
              <Textarea
                id="notes"
                value={newLocationForm.notes}
                onChange={(e) => setNewLocationForm(prev => ({ ...prev, notes: e.target.value }))}
                placeholder="Any additional notes..."
                className="mt-2"
                rows={2}
              />
            </div>

            <div className="flex space-x-3 pt-2">
              <Button onClick={() => setIsAddingLocation(false)} variant="outline" className="flex-1">
                Cancel
              </Button>
              <Button onClick={handleAddLocation} className="flex-1" disabled={!newLocationForm.address}>
                <Save className="w-4 h-4 mr-2" />
                Add Location
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}