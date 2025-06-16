import { useState, useRef } from 'react';
import { ArrowLeft, MoreVertical, Phone, MessageCircle, Calendar, Mail, MapPin, Clock, ChevronDown, User } from 'lucide-react';
import { Button } from '../ui/button';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Textarea } from '../ui/textarea';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { InfoTab } from '../customer-detail/InfoTab';
import { QuotesTab } from '../customer-detail/QuotesTab';
import { InspectionTab } from '../customer-detail/InspectionTab';
import { MediaTab } from '../customer-detail/MediaTab';
import { CommunicationsTab } from '../customer-detail/CommunicationsTab';
import { KanbanCardData } from '../KanbanCard';

interface CustomerDetailScreenProps {
  customer: KanbanCardData | null;
  onBack: () => void;
}

type DialogType = 'call' | 'text' | 'email' | 'schedule' | 'go' | null;

export function CustomerDetailScreen({ customer, onBack }: CustomerDetailScreenProps) {
  const [isSelectionMode, setIsSelectionMode] = useState(false);
  const [activeTab, setActiveTab] = useState('info');
  const [openDialog, setOpenDialog] = useState<DialogType>(null);
  const [appointmentType, setAppointmentType] = useState('');
  const [scheduleDate, setScheduleDate] = useState('');
  const [scheduleTime, setScheduleTime] = useState('');
  const [scheduleDescription, setScheduleDescription] = useState('');
  const quickActionsRef = useRef<HTMLDivElement>(null);
  const tabsRef = useRef<HTMLDivElement>(null);

  if (!customer) {
    return (
      <div className="h-full flex items-center justify-center">
        <p className="text-gray-500">No customer selected</p>
      </div>
    );
  }

  // Safe access to customer properties with fallbacks
  const customerName = customer.customerName || 'Unknown Customer';
  const customerLocation = customer.location || 'Unknown Location';
  const customerUrgency = customer.urgency || 'cold';

  // Mock customer contact data
  const customerPhone = '(555) 123-4567';
  const customerEmail = 'sarah.johnson@email.com';
  const customerAddress = '1234 Elm Street, Springfield, IL 62701';

  const getUrgencyColor = (urgency: string) => {
    switch (urgency.toLowerCase()) {
      case 'hot': 
        return 'bg-red-hot text-red-900';
      case 'warm': 
        return 'bg-orange-risk text-orange-900';
      case 'cold': 
        return 'bg-blue-100 text-blue-900';
      case 'dormant': 
        return 'bg-gray-100 text-gray-700';
      default: 
        return 'bg-gray-100 text-gray-700';
    }
  };

  // Safe avatar initials generation
  const getAvatarInitials = (name: string) => {
    try {
      return name.split(' ').map(n => n[0]).join('').toUpperCase();
    } catch {
      return 'UC';
    }
  };

  const quickActions = [
    { id: 'call', icon: Phone, color: 'text-green-600' },
    { id: 'text', icon: MessageCircle, color: 'text-blue-600' },
    { id: 'email', icon: Mail, color: 'text-gray-600' },
    { id: 'schedule', icon: Calendar, color: 'text-purple-600' },
    { id: 'go', icon: MapPin, color: 'text-indigo-600' }
  ];

  const appointmentTypes = [
    'Initial Consultation',
    'Roof Inspection',
    'Estimate Review',
    'Follow-up Meeting',
    'Project Start',
    'Progress Check',
    'Final Walkthrough',
    'Other'
  ];

  const handleQuickAction = (action: string) => {
    console.log(`${action} action triggered for ${customerName}`);
    
    const iconElement = document.querySelector(`[data-action="${action}"]`);
    if (iconElement && quickActionsRef.current) {
      iconElement.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest', 
        inline: 'center' 
      });
    }

    setOpenDialog(action as DialogType);
  };

  const handleTabChange = (value: string) => {
    setActiveTab(value);
    
    setTimeout(() => {
      const activeTabElement = document.querySelector(`[data-state="active"]`);
      if (activeTabElement && tabsRef.current) {
        activeTabElement.scrollIntoView({ 
          behavior: 'smooth', 
          block: 'nearest', 
          inline: 'center' 
        });
      }
    }, 100);
  };

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      console.log('Copied to clipboard:', text);
    } catch (err) {
      console.error('Failed to copy to clipboard:', err);
    }
  };

  const handleCall = () => {
    window.location.href = `tel:${customerPhone}`;
    setOpenDialog(null);
  };

  const handleText = () => {
    window.location.href = `sms:${customerPhone}`;
    setOpenDialog(null);
  };

  const handleEmail = () => {
    window.location.href = `mailto:${customerEmail}`;
    setOpenDialog(null);
  };

  const handleSchedule = () => {
    if (appointmentType && scheduleDate && scheduleTime && scheduleDescription.trim()) {
      console.log('Scheduling appointment:', {
        type: appointmentType,
        date: scheduleDate,
        time: scheduleTime,
        description: scheduleDescription,
        customer: customerName
      });
      
      setOpenDialog(null);
      setAppointmentType('');
      setScheduleDate('');
      setScheduleTime('');
      setScheduleDescription('');
    }
  };

  const handleGoToMaps = () => {
    const encodedAddress = encodeURIComponent(customerAddress);
    window.open(`https://maps.google.com/?q=${encodedAddress}`, '_blank');
    setOpenDialog(null);
  };

  // Get today's date for minimum date constraint
  const getTodayDate = () => {
    const today = new Date();
    return today.toISOString().split('T')[0];
  };

  // Format date for display
  const formatDateForDisplay = (dateString: string) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    
    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === tomorrow.toDateString()) {
      return 'Tomorrow';
    } else {
      return date.toLocaleDateString('en-US', { 
        weekday: 'short', 
        month: 'short', 
        day: 'numeric' 
      });
    }
  };

  // Format time for display
  const formatTimeForDisplay = (timeString: string) => {
    if (!timeString) return '';
    const [hours, minutes] = timeString.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return `${displayHour}:${minutes} ${ampm}`;
  };

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="border-b border-gray-200 bg-background">
        {/* Top Bar */}
        <div className="flex items-center justify-between p-4 pb-2">
          <div className="flex items-center space-x-4">
            <Button
              variant="ghost" 
              size="sm"
              onClick={onBack}
              className="p-2 -ml-2"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div className="flex items-center space-x-2">
              <User className="w-5 h-5 text-primary" />
              <span className="font-medium text-gray-900">Customer</span>
            </div>
            <div className="flex items-center space-x-3">
              <Avatar className="w-11 h-11">
                <AvatarFallback className="bg-primary text-primary-foreground">
                  {getAvatarInitials(customerName)}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0">
                <h1 className="font-medium text-lg truncate">{customerName}</h1>
                <div className="flex items-center space-x-2 mt-0.5">
                  <Badge className={`text-xs px-2 py-0.5 ${getUrgencyColor(customerUrgency)}`}>
                    {customerUrgency}
                  </Badge>
                  <span className="text-sm text-gray-500 truncate">{customerLocation}</span>
                </div>
              </div>
            </div>
          </div>
          <Button variant="ghost" size="sm" className="p-2">
            <MoreVertical className="w-5 h-5" />
          </Button>
        </div>

        {/* Quick Actions */}
        <div className="px-4 pb-3">
          <div 
            ref={quickActionsRef}
            className="flex items-center space-x-6 overflow-x-auto scrollbar-hide py-2"
            style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
          >
            {quickActions.map((action) => {
              const IconComponent = action.icon;
              return (
                <button
                  key={action.id}
                  data-action={action.id}
                  className="flex-shrink-0 p-2 rounded-full hover:bg-gray-100 active:bg-gray-200 transition-colors touch-manipulation"
                  onClick={() => handleQuickAction(action.id)}
                  style={{ minWidth: '48px', minHeight: '48px' }}
                >
                  <IconComponent className={`w-6 h-6 ${action.color}`} />
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden">
        <Tabs value={activeTab} onValueChange={handleTabChange} className="h-full flex flex-col">
          {/* Tab Navigation */}
          <div className="border-b border-gray-200 bg-background">
            <TabsList className="w-full justify-start h-auto p-0 bg-transparent">
              <div 
                ref={tabsRef}
                className="flex overflow-x-auto scrollbar-hide"
                style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
              >
                <TabsTrigger 
                  value="info" 
                  className="flex-shrink-0 px-6 py-3 whitespace-nowrap data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:bg-transparent rounded-none bg-transparent text-gray-600 data-[state=active]:text-primary hover:text-gray-900 transition-colors"
                >
                  Info
                </TabsTrigger>
                <TabsTrigger 
                  value="communications" 
                  className="flex-shrink-0 px-6 py-3 whitespace-nowrap data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:bg-transparent rounded-none bg-transparent text-gray-600 data-[state=active]:text-primary hover:text-gray-900 transition-colors"
                >
                  Communications
                </TabsTrigger>
                <TabsTrigger 
                  value="quotes" 
                  className="flex-shrink-0 px-6 py-3 whitespace-nowrap data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:bg-transparent rounded-none bg-transparent text-gray-600 data-[state=active]:text-primary hover:text-gray-900 transition-colors"
                >
                  Quotes
                </TabsTrigger>
                <TabsTrigger 
                  value="inspection" 
                  className="flex-shrink-0 px-6 py-3 whitespace-nowrap data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:bg-transparent rounded-none bg-transparent text-gray-600 data-[state=active]:text-primary hover:text-gray-900 transition-colors"
                >
                  Inspection
                </TabsTrigger>
                <TabsTrigger 
                  value="media" 
                  className="flex-shrink-0 px-6 py-3 whitespace-nowrap data-[state=active]:border-b-2 data-[state=active]:border-primary data-[state=active]:bg-transparent rounded-none bg-transparent text-gray-600 data-[state=active]:text-primary hover:text-gray-900 transition-colors"
                >
                  Media
                </TabsTrigger>
              </div>
            </TabsList>
          </div>

          {/* Tab Content */}
          <div className="flex-1 overflow-hidden">
            <TabsContent value="info" className="h-full m-0">
              <InfoTab customer={customer} />
            </TabsContent>
            
            <TabsContent value="communications" className="h-full m-0">
              <CommunicationsTab customer={customer} />
            </TabsContent>
            
            <TabsContent value="quotes" className="h-full m-0">
              <QuotesTab customer={customer} />
            </TabsContent>
            
            <TabsContent value="inspection" className="h-full m-0">
              <InspectionTab customer={customer} />
            </TabsContent>
            
            <TabsContent value="media" className="h-full m-0">
              <MediaTab 
                customer={customer} 
                isSelectionMode={isSelectionMode}
                onSelectionModeChange={setIsSelectionMode}
              />
            </TabsContent>
          </div>
        </Tabs>
      </div>

      {/* Call Dialog */}
      <Dialog open={openDialog === 'call'} onOpenChange={() => setOpenDialog(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <Phone className="w-5 h-5 text-green-600" />
              <span>Call {customerName}</span>
            </DialogTitle>
            <DialogDescription>
              Choose to copy the phone number or call directly.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Phone Number</p>
              <p className="font-medium">{customerPhone}</p>
            </div>
            <div className="flex space-x-3">
              <Button 
                onClick={() => copyToClipboard(customerPhone)}
                variant="outline" 
                className="flex-1"
              >
                Copy Number
              </Button>
              <Button 
                onClick={handleCall}
                className="flex-1"
              >
                <Phone className="w-4 h-4 mr-2" />
                Call Now
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Text Dialog */}
      <Dialog open={openDialog === 'text'} onOpenChange={() => setOpenDialog(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <MessageCircle className="w-5 h-5 text-blue-600" />
              <span>Text {customerName}</span>
            </DialogTitle>
            <DialogDescription>
              Choose to copy the phone number or send a text message.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Phone Number</p>
              <p className="font-medium">{customerPhone}</p>
            </div>
            <div className="flex space-x-3">
              <Button 
                onClick={() => copyToClipboard(customerPhone)}
                variant="outline" 
                className="flex-1"
              >
                Copy Number
              </Button>
              <Button 
                onClick={handleText}
                className="flex-1"
              >
                <MessageCircle className="w-4 h-4 mr-2" />
                Send Text
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Email Dialog */}
      <Dialog open={openDialog === 'email'} onOpenChange={() => setOpenDialog(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <Mail className="w-5 h-5 text-gray-600" />
              <span>Email {customerName}</span>
            </DialogTitle>
            <DialogDescription>
              Choose to copy the email address or open your email client.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Email Address</p>
              <p className="font-medium">{customerEmail}</p>
            </div>
            <div className="flex space-x-3">
              <Button 
                onClick={() => copyToClipboard(customerEmail)}
                variant="outline" 
                className="flex-1"
              >
                Copy Email
              </Button>
              <Button 
                onClick={handleEmail}
                className="flex-1"
              >
                <Mail className="w-4 h-4 mr-2" />
                Send Email
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Schedule Dialog - With Reverted Appointment Type */}
      <Dialog open={openDialog === 'schedule'} onOpenChange={() => setOpenDialog(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <Calendar className="w-5 h-5 text-purple-600" />
              <span>Schedule Appointment</span>
            </DialogTitle>
            <DialogDescription>
              Create a new appointment with date, time, and appointment details.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            {/* Appointment Type - Reverted to Select */}
            <div>
              <Label htmlFor="appointment-type">Appointment Type</Label>
              <Select value={appointmentType} onValueChange={setAppointmentType}>
                <SelectTrigger className="mt-2">
                  <SelectValue placeholder="Select appointment type" />
                </SelectTrigger>
                <SelectContent>
                  {appointmentTypes.map((type) => (
                    <SelectItem key={type} value={type}>
                      {type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Date & Time - Native Inputs */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="appointment-date" className="text-sm font-medium mb-2 block">
                  Date
                </Label>
                <input
                  id="appointment-date"
                  type="date"
                  value={scheduleDate}
                  onChange={(e) => setScheduleDate(e.target.value)}
                  min={getTodayDate()}
                  className="w-full p-3 border border-gray-200 rounded-lg bg-white focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                />
              </div>
              <div>
                <Label htmlFor="appointment-time" className="text-sm font-medium mb-2 block">
                  Time
                </Label>
                <input
                  id="appointment-time"
                  type="time"
                  value={scheduleTime}
                  onChange={(e) => setScheduleTime(e.target.value)}
                  className="w-full p-3 border border-gray-200 rounded-lg bg-white focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                />
              </div>
            </div>

            {/* Notes */}
            <div>
              <Label htmlFor="appointment-notes" className="text-sm font-medium mb-2 block">
                Notes
              </Label>
              <Textarea
                id="appointment-notes"
                placeholder="Add any notes or special instructions..."
                value={scheduleDescription}
                onChange={(e) => setScheduleDescription(e.target.value)}
                className="resize-none"
                rows={3}
              />
            </div>

            {/* Preview Card */}
            {appointmentType && scheduleDate && scheduleTime && (
              <div className="p-4 bg-purple-50 rounded-lg border border-purple-200">
                <div className="flex items-center space-x-2 mb-2">
                  <Calendar className="w-4 h-4 text-purple-600" />
                  <span className="text-sm font-medium text-purple-900">Appointment Summary</span>
                </div>
                <div className="space-y-1">
                  <p className="text-sm text-purple-800 font-medium">{appointmentType}</p>
                  <p className="text-sm text-purple-700">
                    {formatDateForDisplay(scheduleDate)} at {formatTimeForDisplay(scheduleTime)}
                  </p>
                  {scheduleDescription.trim() && (
                    <p className="text-sm text-purple-700 mt-2">
                      "{scheduleDescription.trim()}"
                    </p>
                  )}
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex space-x-3 pt-2">
              <Button 
                onClick={() => setOpenDialog(null)}
                variant="outline" 
                className="flex-1"
              >
                Cancel
              </Button>
              <Button 
                onClick={handleSchedule}
                disabled={!appointmentType || !scheduleDate || !scheduleTime || !scheduleDescription.trim()}
                className="flex-1"
              >
                <Calendar className="w-4 h-4 mr-2" />
                Schedule
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Go Dialog */}
      <Dialog open={openDialog === 'go'} onOpenChange={() => setOpenDialog(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              <MapPin className="w-5 h-5 text-indigo-600" />
              <span>Navigate to {customerName}</span>
            </DialogTitle>
            <DialogDescription>
              Choose to copy the address or open it in your maps application.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Address</p>
              <p className="font-medium">{customerAddress}</p>
            </div>
            <div className="flex space-x-3">
              <Button 
                onClick={() => copyToClipboard(customerAddress)}
                variant="outline" 
                className="flex-1"
              >
                Copy Address
              </Button>
              <Button 
                onClick={handleGoToMaps}
                className="flex-1"
              >
                <MapPin className="w-4 h-4 mr-2" />
                Open in Maps
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}