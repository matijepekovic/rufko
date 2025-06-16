import { Badge } from './ui/badge';
import { Clock, MapPin, Navigation, Phone, MessageSquare } from 'lucide-react';
import { Button } from './ui/button';

interface Job {
  id: string;
  customerName: string;
  phoneNumber: string;
  address: string;
  time: string;
  status: 'scheduled' | 'in-progress' | 'completed' | 'cancelled';
}

interface ScheduleListProps {
  jobs: Job[];
}

export function ScheduleList({ jobs }: ScheduleListProps) {
  const getStatusColor = (status: Job['status']) => {
    switch (status) {
      case 'scheduled': return 'bg-blue-100 text-blue-800';
      case 'in-progress': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-green-100 text-green-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const handleCall = (phoneNumber: string) => {
    window.open(`tel:${phoneNumber}`, '_self');
  };

  const handleText = (phoneNumber: string) => {
    window.open(`sms:${phoneNumber}`, '_self');
  };

  const handleAddressAction = async (address: string) => {
    // Try to copy to clipboard first
    try {
      await navigator.clipboard.writeText(address);
      console.log('Address copied to clipboard');
    } catch (err) {
      console.error('Failed to copy address:', err);
    }
    
    // Also try to open in maps
    const encodedAddress = encodeURIComponent(address);
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    
    if (isIOS) {
      // Try Apple Maps first on iOS
      window.open(`maps://maps.apple.com/?q=${encodedAddress}`, '_blank');
    } else {
      // Use Google Maps on other platforms
      window.open(`https://maps.google.com/?q=${encodedAddress}`, '_blank');
    }
  };

  if (jobs.length === 0) {
    return (
      <div className="py-8 text-center text-muted-foreground">
        No jobs scheduled for today
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {jobs.map((job) => (
        <div
          key={job.id}
          className="flex bg-card rounded-lg border border-stroke p-3"
        >
          {/* Left: All Customer Info */}
          <div className="flex-1 min-w-0">
            
            {/* Top Row: Time and Status */}
            <div className="flex items-center space-x-2 mb-2">
              <div className="flex items-center text-xs text-muted-foreground bg-muted px-2 py-1 rounded-full">
                <Clock className="w-3 h-3 mr-1" />
                {job.time}
              </div>
              <Badge 
                variant="secondary" 
                className={`text-xs px-2 py-0.5 ${getStatusColor(job.status)}`}
              >
                {job.status.replace('-', ' ')}
              </Badge>
            </div>
            
            {/* Customer Name - Prominent */}
            <div className="font-semibold text-base mb-2">
              {job.customerName}
            </div>
            
            {/* Phone Number - Clickable */}
            <div className="flex items-center text-sm text-foreground mb-2">
              <Phone className="w-4 h-4 mr-2 text-muted-foreground" />
              <a href={`tel:${job.phoneNumber}`} className="hover:text-primary hover:underline">
                {job.phoneNumber}
              </a>
            </div>
            
            {/* Address */}
            <div className="flex items-start text-sm text-muted-foreground">
              <MapPin className="w-4 h-4 mr-2 mt-0.5 flex-shrink-0" />
              <span className="line-clamp-2 leading-tight pr-2">{job.address}</span>
            </div>
            
          </div>

          {/* Right: Action Buttons Stack */}
          <div className="flex flex-col items-center space-y-1">
            
            {/* Call Button */}
            <Button
              variant="ghost"
              size="sm"
              className="h-10 w-10 p-0 text-green-600 hover:text-green-700 hover:bg-green-50 rounded-full"
              onClick={() => handleCall(job.phoneNumber)}
            >
              <Phone className="w-5 h-5" />
            </Button>
            
            {/* Text Button */}
            <Button
              variant="ghost"
              size="sm"
              className="h-10 w-10 p-0 text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-full"
              onClick={() => handleText(job.phoneNumber)}
            >
              <MessageSquare className="w-5 h-5" />
            </Button>
            
            {/* Navigation Button */}
            <Button
              variant="ghost"
              size="lg"
              className="h-12 w-12 p-0 text-primary hover:text-primary hover:bg-primary/10 rounded-full"
              onClick={() => handleAddressAction(job.address)}
            >
              <Navigation className="w-6 h-6" />
            </Button>
            
          </div>
        </div>
      ))}
    </div>
  );
}