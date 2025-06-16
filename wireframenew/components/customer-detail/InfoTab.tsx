import { useState } from 'react';
import { Phone, Mail, MapPin, Calendar, DollarSign, FileText, Edit2 } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { KanbanCardData } from '../KanbanCard';

interface InfoTabProps {
  customer: KanbanCardData;
}

export function InfoTab({ customer }: InfoTabProps) {
  const [isEditing, setIsEditing] = useState(false);

  // Safe access to customer properties with fallbacks
  const customerName = customer?.customerName || 'Unknown Customer';
  const customerLocation = customer?.location || 'Unknown Location';
  const customerUrgency = customer?.urgency || 'cold';
  const customerValue = customer?.value || '$0';

  const contactInfo = {
    email: 'sarah.johnson@email.com',
    phone: '(555) 123-4567',
    address: '1234 Elm Street, Springfield, IL 62701',
    preferredContact: 'Phone'
  };

  const projectInfo = {
    type: 'Roof Inspection & Repair',
    status: 'Assessment Complete',
    priority: customerUrgency,
    estimatedValue: customerValue,
    lastActivity: '2 days ago',
    nextAction: 'Schedule repair work'
  };

  const notes = [
    {
      id: '1',
      content: 'Customer has two large dogs in backyard. Schedule accordingly.',
      timestamp: '3 days ago',
      author: 'Mike Thompson'
    },
    {
      id: '2',
      content: 'Prefers morning appointments between 8-10 AM.',
      timestamp: '1 week ago',
      author: 'Sarah Wilson'
    },
    {
      id: '3',
      content: 'Previous customer - completed kitchen remodel in 2022.',
      timestamp: '2 weeks ago',
      author: 'System'
    }
  ];

  // Safe function to get urgency colors with fallback
  const getUrgencyColor = (urgency: string | undefined) => {
    if (!urgency) return 'bg-gray-100 text-gray-700';
    
    switch (urgency.toLowerCase()) {
      case 'hot': return 'bg-red-hot text-red-900';
      case 'warm': return 'bg-orange-risk text-orange-900';
      case 'cold': return 'bg-blue-100 text-blue-900';
      case 'dormant': return 'bg-gray-100 text-gray-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  return (
    <div className="p-4 space-y-6">
      {/* Contact Information */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Contact Information</CardTitle>
            <Button 
              variant="ghost" 
              size="sm"
              onClick={() => setIsEditing(!isEditing)}
            >
              <Edit2 className="w-4 h-4" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="pt-0">
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <Mail className="w-4 h-4 text-gray-500 flex-shrink-0" />
              <div>
                <p className="text-sm text-gray-900">{contactInfo.email}</p>
                <p className="text-xs text-gray-500">Email</p>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              <Phone className="w-4 h-4 text-gray-500 flex-shrink-0" />
              <div>
                <p className="text-sm text-gray-900">{contactInfo.phone}</p>
                <p className="text-xs text-gray-500">Mobile</p>
              </div>
            </div>
            
            <div className="flex items-start space-x-3">
              <MapPin className="w-4 h-4 text-gray-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm text-gray-900">{contactInfo.address}</p>
                <p className="text-xs text-gray-500">Home Address</p>
              </div>
            </div>
            
            <div className="pt-2 border-t border-gray-100">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Preferred Contact Method</span>
                <Badge variant="secondary">{contactInfo.preferredContact}</Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Project Details */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Project Details</CardTitle>
        </CardHeader>
        <CardContent className="pt-0">
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-700">Project Type</span>
              <span className="text-sm font-medium text-gray-900">{projectInfo.type}</span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-700">Status</span>
              <Badge variant="outline">{projectInfo.status}</Badge>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-700">Priority</span>
              <Badge className={`text-xs ${getUrgencyColor(projectInfo.priority)}`}>
                {projectInfo.priority || 'Unknown'}
              </Badge>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-700">Estimated Value</span>
              <div className="flex items-center space-x-1">
                <DollarSign className="w-3 h-3 text-gray-500" />
                <span className="text-sm font-medium text-gray-900">{projectInfo.estimatedValue}</span>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-700">Last Activity</span>
              <span className="text-sm text-gray-600">{projectInfo.lastActivity}</span>
            </div>
            
            <div className="pt-2 border-t border-gray-100">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-700">Next Action</span>
                <span className="text-sm font-medium text-primary">{projectInfo.nextAction}</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Project Notes */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Project Notes</CardTitle>
            <Button variant="ghost" size="sm">
              Add Note
            </Button>
          </div>
        </CardHeader>
        <CardContent className="pt-0">
          <div className="space-y-3">
            {notes.map((note) => (
              <div key={note.id} className="p-3 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-900 mb-2">{note.content}</p>
                <div className="flex items-center justify-between text-xs text-gray-500">
                  <span>{note.author}</span>
                  <span>{note.timestamp}</span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}