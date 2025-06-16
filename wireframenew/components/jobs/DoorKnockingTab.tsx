import { useState, useEffect } from 'react';
import { MapPin, Target, Phone, MessageSquare, Mail, Plus, Save, User, Calendar, Search, Filter } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Label } from '../ui/label';

interface DoorKnockLocation {
  id: string;
  lat: number;
  lng: number;
  address: string;
  customerName?: string;
  phone?: string;
  email?: string;
  notes?: string;
  priority: 'high' | 'medium' | 'low';
  status: 'pending' | 'contacted' | 'interested' | 'not-interested' | 'follow-up' | 'converted';
  addedAt: Date;
  lastContact?: Date;
  nextFollowUp?: Date;
}

export function DoorKnockingTab() {
  const [locations, setLocations] = useState<DoorKnockLocation[]>([]);
  const [isAddingLocation, setIsAddingLocation] = useState(false);
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [newLocationForm, setNewLocationForm] = useState({
    address: '',
    customerName: '',
    phone: '',
    email: '',
    notes: '',
    priority: 'medium' as const
  });

  // Mock door knocking locations
  const mockLocations: DoorKnockLocation[] = [
    {
      id: '1',
      lat: 41.8781,
      lng: -87.6298,
      address: '456 Pine Avenue, Chicago, IL',
      customerName: 'Sarah Johnson',
      phone: '(555) 987-6543',
      email: 'sarah@email.com',
      priority: 'high',
      status: 'interested',
      notes: 'Interested in roof inspection, mentioned recent storm damage. Wants quote next week.',
      addedAt: new Date('2024-06-15T10:30:00'),
      lastContact: new Date('2024-06-15T10:30:00'),
      nextFollowUp: new Date('2024-06-20T09:00:00')
    },
    {
      id: '2',
      lat: 41.8701,
      lng: -87.6398,
      address: '789 Maple Drive, Chicago, IL',
      priority: 'low',
      status: 'not-interested',
      notes: 'Not interested, renting property. Landlord contact needed.',
      addedAt: new Date('2024-06-15T11:15:00'),
      lastContact: new Date('2024-06-15T11:15:00')
    },
    {
      id: '3',
      lat: 41.8821,
      lng: -87.6198,
      address: '321 Elm Street, Chicago, IL',
      customerName: 'Mike Chen',
      phone: '(555) 456-7890',
      priority: 'medium',
      status: 'follow-up',
      notes: 'Interested but wants to wait until spring. Schedule follow-up in March.',
      addedAt: new Date('2024-06-14T14:00:00'),
      lastContact: new Date('2024-06-14T14:00:00'),
      nextFollowUp: new Date('2024-03-01T09:00:00')
    },
    {
      id: '4',
      lat: 41.8851,
      lng: -87.6311,
      address: '654 Oak Lane, Chicago, IL',
      priority: 'medium',
      status: 'pending',
      notes: 'No one home, try again tomorrow evening.',
      addedAt: new Date('2024-06-15T16:00:00')
    }
  ];

  useEffect(() => {
    setLocations(mockLocations);
  }, []);

  const filterOptions = [
    { id: 'all', label: 'All', count: locations.length },
    { id: 'pending', label: 'Pending', count: locations.filter(l => l.status === 'pending').length },
    { id: 'interested', label: 'Interested', count: locations.filter(l => l.status === 'interested').length },
    { id: 'follow-up', label: 'Follow-up', count: locations.filter(l => l.status === 'follow-up').length },
    { id: 'contacted', label: 'Contacted', count: locations.filter(l => l.status === 'contacted').length }
  ];

  const filteredLocations = selectedFilter === 'all' 
    ? locations 
    : locations.filter(location => location.status === selectedFilter);

  const getStatusColor = (status: DoorKnockLocation['status']) => {
    switch (status) {
      case 'converted': return 'bg-green-100 text-green-800';
      case 'interested': return 'bg-blue-100 text-blue-800';
      case 'follow-up': return 'bg-purple-100 text-purple-800';
      case 'contacted': return 'bg-yellow-100 text-yellow-800';
      case 'not-interested': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority: DoorKnockLocation['priority']) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleAddLocation = () => {
    const newLocation: DoorKnockLocation = {
      id: Date.now().toString(),
      lat: 41.8781 + (Math.random() - 0.5) * 0.01,
      lng: -87.6298 + (Math.random() - 0.5) * 0.01,
      address: newLocationForm.address,
      customerName: newLocationForm.customerName || undefined,
      phone: newLocationForm.phone || undefined,
      email: newLocationForm.email || undefined,
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
      priority: 'medium'
    });
    setIsAddingLocation(false);
  };

  const handleContactCustomer = (location: DoorKnockLocation, method: 'call' | 'text' | 'email') => {
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
    updateLocationStatus(location.id, 'contacted');
  };

  const updateLocationStatus = (locationId: string, status: DoorKnockLocation['status']) => {
    setLocations(prev => 
      prev.map(l => 
        l.id === locationId 
          ? { ...l, status, lastContact: new Date() }
          : l
      )
    );
  };

  const handleNavigateToLocation = (address: string) => {
    const encodedAddress = encodeURIComponent(address);
    window.open(`https://maps.google.com/maps?daddr=${encodedAddress}`, '_blank');
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header Controls */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-2">
            <div className="p-2 rounded-lg bg-primary/10">
              <Target className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h2 className="font-medium">Door Knocking</h2>
              <p className="text-xs text-muted-foreground">Manage leads & customer acquisition</p>
            </div>
          </div>
          <Button size="sm" onClick={() => setIsAddingLocation(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Add Location
          </Button>
        </div>

        {/* Search and Filter */}
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search locations..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" variant="outline" className="px-3">
            <Filter size={16} />
          </Button>
        </div>

        {/* Status Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {filterOptions.map((filter) => (
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
      </div>

      {/* Door Knocking Map & List */}
      <div className="flex-1 overflow-y-auto scrollable">
        {/* Map Placeholder */}
        <div className="p-4">
          <div className="aspect-video bg-gray-100 rounded-lg border border-stroke flex items-center justify-center mb-4">
            <div className="text-center">
              <Target className="w-12 h-12 text-gray-400 mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">Door Knocking Map</p>
              <p className="text-xs text-muted-foreground">{filteredLocations.length} locations</p>
            </div>
          </div>
        </div>

        {/* Locations List */}
        <div className="px-4 pb-4 space-y-3">
          {filteredLocations.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No locations found</p>
            </div>
          ) : (
            filteredLocations.map((location) => (
              <Card key={location.id} className="cursor-pointer hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-2 mb-1">
                        {location.customerName ? (
                          <div className="font-medium text-sm truncate">
                            {location.customerName}
                          </div>
                        ) : (
                          <div className="flex items-center text-sm text-muted-foreground">
                            <User className="w-4 h-4 mr-1" />
                            <span>Unknown</span>
                          </div>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground truncate">{location.address}</p>
                      <p className="text-xs text-muted-foreground mt-1">
                        Added {location.addedAt.toLocaleDateString()}
                        {location.lastContact && (
                          <span> • Last contact {location.lastContact.toLocaleDateString()}</span>
                        )}
                      </p>
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
                    <div className="mb-3 p-2 bg-muted rounded text-xs text-muted-foreground">
                      {location.notes}
                    </div>
                  )}

                  {location.nextFollowUp && (
                    <div className="mb-3 flex items-center text-xs text-orange-600">
                      <Calendar className="w-3 h-3 mr-1" />
                      Follow-up: {location.nextFollowUp.toLocaleDateString()}
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex items-center justify-between">
                    <div className="flex space-x-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                        onClick={() => handleNavigateToLocation(location.address)}
                        title="Navigate to location"
                      >
                        <MapPin size={14} />
                      </Button>
                      {location.phone && (
                        <>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-8 w-8 p-0 text-green-600 hover:text-green-700 hover:bg-green-50"
                            onClick={() => handleContactCustomer(location, 'call')}
                            title="Call"
                          >
                            <Phone size={14} />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="h-8 w-8 p-0 text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                            onClick={() => handleContactCustomer(location, 'text')}
                            title="Text"
                          >
                            <MessageSquare size={14} />
                          </Button>
                        </>
                      )}
                      {location.email && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-8 w-8 p-0 text-purple-600 hover:text-purple-700 hover:bg-purple-50"
                          onClick={() => handleContactCustomer(location, 'email')}
                          title="Email"
                        >
                          <Mail size={14} />
                        </Button>
                      )}
                    </div>

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
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>

      {/* Add Location Dialog */}
      <Dialog open={isAddingLocation} onOpenChange={setIsAddingLocation}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Add Door Knocking Location</DialogTitle>
            <DialogDescription>
              Add a new location for door knocking and lead generation
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
                placeholder="Initial conversation notes, interests, follow-up details..."
                className="mt-2"
                rows={3}
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