import { useState } from 'react';
import { X, ChevronDown, ChevronRight, User, Calendar, FileText, MessageSquare, CheckSquare, Phone, Mail, MessageCircle } from 'lucide-react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { KanbanCardData } from './KanbanCard';

interface DrawerSection {
  id: string;
  title: string;
  icon: any;
  isOpen: boolean;
  content: React.ReactNode;
}

interface Communication {
  id: string;
  type: 'call' | 'text' | 'email';
  direction: 'inbound' | 'outbound';
  content: string;
  timestamp: string;
  duration?: string;
  threadId?: string;
  subject?: string;
}

interface EmailThread {
  threadId: string;
  subject: string;
  lastMessage: string;
  messageCount: number;
  timestamp: string;
  messages: Communication[];
}

interface CardDrawerProps {
  card: KanbanCardData | null;
  isOpen: boolean;
  onClose: () => void;
}

export function CardDrawer({ card, isOpen, onClose }: CardDrawerProps) {
  const [openSections, setOpenSections] = useState<Set<string>>(
    new Set(['overview', 'followups'])
  );

  if (!card || !isOpen) return null;

  const toggleSection = (sectionId: string) => {
    const newOpenSections = new Set(openSections);
    if (newOpenSections.has(sectionId)) {
      newOpenSections.delete(sectionId);
    } else {
      newOpenSections.add(sectionId);
    }
    setOpenSections(newOpenSections);
  };

  // Mock communications data
  const mockCommunications: Communication[] = [
    {
      id: '1',
      type: 'email',
      direction: 'outbound',
      content: 'Quote sent as requested. Please review and let me know if you have any questions.',
      timestamp: '2024-06-13T10:30:00Z',
      threadId: 'thread-1',
      subject: 'Roofing Quote - Thompson Residence'
    },
    {
      id: '2',
      type: 'email',
      direction: 'inbound',
      content: 'Thank you for the quote. We have a few questions about the timeline.',
      timestamp: '2024-06-13T14:15:00Z',
      threadId: 'thread-1',
      subject: 'Re: Roofing Quote - Thompson Residence'
    },
    {
      id: '3',
      type: 'call',
      direction: 'outbound',
      content: 'Discussed project timeline and materials',
      timestamp: '2024-06-12T09:15:00Z',
      duration: '15 minutes'
    },
    {
      id: '4',
      type: 'text',
      direction: 'inbound',
      content: 'Can we reschedule the inspection to next week?',
      timestamp: '2024-06-11T16:45:00Z'
    },
    {
      id: '5',
      type: 'text',
      direction: 'outbound',
      content: 'Sure! How about Tuesday at 2 PM?',
      timestamp: '2024-06-11T17:00:00Z'
    },
    {
      id: '6',
      type: 'call',
      direction: 'inbound',
      content: 'Initial consultation call',
      timestamp: '2024-06-10T11:00:00Z',
      duration: '25 minutes'
    }
  ];

  // Group communications by type
  const emailThreads: EmailThread[] = [];
  const callsAndTexts: Communication[] = [];

  // Process emails into threads
  const emailGroups = mockCommunications
    .filter(comm => comm.type === 'email')
    .reduce((groups, email) => {
      const threadId = email.threadId || email.id;
      if (!groups[threadId]) {
        groups[threadId] = [];
      }
      groups[threadId].push(email);
      return groups;
    }, {} as Record<string, Communication[]>);

  Object.entries(emailGroups).forEach(([threadId, messages]) => {
    const latestMessage = messages.sort((a, b) => 
      new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    )[0];
    
    emailThreads.push({
      threadId,
      subject: latestMessage.subject || 'No Subject',
      lastMessage: latestMessage.content,
      messageCount: messages.length,
      timestamp: latestMessage.timestamp,
      messages: messages.sort((a, b) => 
        new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
      )
    });
  });

  // Add calls and texts
  callsAndTexts.push(...mockCommunications.filter(comm => comm.type !== 'email'));

  const formatRelativeTime = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffTime = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    const diffHours = Math.floor(diffTime / (1000 * 60 * 60));
    const diffMinutes = Math.floor(diffTime / (1000 * 60));

    if (diffDays > 0) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    if (diffHours > 0) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffMinutes > 0) return `${diffMinutes} minute${diffMinutes > 1 ? 's' : ''} ago`;
    return 'Just now';
  };

  const getCommIcon = (type: string, direction: string) => {
    switch (type) {
      case 'call':
        return <Phone className={`w-3 h-3 ${direction === 'inbound' ? 'text-green-600' : 'text-blue-600'}`} />;
      case 'text':
        return <MessageCircle className={`w-3 h-3 ${direction === 'inbound' ? 'text-green-600' : 'text-blue-600'}`} />;
      case 'email':
        return <Mail className={`w-3 h-3 ${direction === 'inbound' ? 'text-green-600' : 'text-blue-600'}`} />;
      default:
        return <MessageSquare className="w-3 h-3 text-gray-600" />;
    }
  };

  const sections: DrawerSection[] = [
    {
      id: 'overview',
      title: 'OVERVIEW',
      icon: User,
      isOpen: openSections.has('overview'),
      content: (
        <div className="space-y-3">
          <div>
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Customer</label>
            <p className="text-sm font-medium mt-1">{card.title}</p>
          </div>
          <div>
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Stage</label>
            <p className="text-sm mt-1">{card.stage}</p>
          </div>
          <div>
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Value</label>
            <p className="text-sm font-medium mt-1">${card.value.toLocaleString()}</p>
          </div>
          <div>
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wide">Days Idle</label>
            <p className="text-sm mt-1">{card.daysIdle} days</p>
          </div>
        </div>
      )
    },
    {
      id: 'followups',
      title: 'FOLLOW-UPS',
      icon: Calendar,
      isOpen: openSections.has('followups'),
      content: (
        <div className="space-y-3">
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div>
              <p className="text-sm font-medium">Follow-up call</p>
              <p className="text-xs text-gray-500">Tomorrow at 10:00 AM</p>
            </div>
            <Badge variant="outline" className="text-xs">Scheduled</Badge>
          </div>
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div>
              <p className="text-sm font-medium">Send proposal</p>
              <p className="text-xs text-gray-500">Due in 3 days</p>
            </div>
            <Badge variant="outline" className="text-xs">Pending</Badge>
          </div>
        </div>
      )
    },
    {
      id: 'notes',
      title: 'NOTES',
      icon: FileText,
      isOpen: openSections.has('notes'),
      content: (
        <div className="space-y-3">
          <div className="p-3 bg-gray-50 rounded-lg">
            <p className="text-sm">Customer is interested in premium roofing package. Mentioned budget of $8-10k.</p>
            <p className="text-xs text-gray-500 mt-2">2 days ago</p>
          </div>
          <div className="p-3 bg-gray-50 rounded-lg">
            <p className="text-sm">Initial consultation completed. Roof inspection scheduled for next week.</p>
            <p className="text-xs text-gray-500 mt-2">1 week ago</p>
          </div>
        </div>
      )
    },
    {
      id: 'communications',
      title: 'COMMUNICATIONS',
      icon: MessageSquare,
      isOpen: openSections.has('communications'),
      content: (
        <div className="space-y-4">
          {/* Email Threads */}
          {emailThreads.length > 0 && (
            <div>
              <h4 className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Email Threads</h4>
              <div className="space-y-2">
                {emailThreads.map((thread) => (
                  <div key={thread.threadId} className="p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-2 mb-1">
                          <Mail className="w-3 h-3 text-blue-600" />
                          <p className="text-sm font-medium truncate">{thread.subject}</p>
                        </div>
                        <p className="text-xs text-gray-600 line-clamp-2">{thread.lastMessage}</p>
                      </div>
                      <div className="ml-2 text-right">
                        <Badge variant="outline" className="text-xs mb-1">
                          {thread.messageCount} message{thread.messageCount > 1 ? 's' : ''}
                        </Badge>
                        <p className="text-xs text-gray-500">{formatRelativeTime(thread.timestamp)}</p>
                      </div>
                    </div>
                    
                    {/* Thread messages preview */}
                    <div className="border-l-2 border-gray-200 pl-3 ml-1 space-y-1">
                      {thread.messages.slice(-2).map((message, index) => (
                        <div key={message.id} className="text-xs">
                          <div className="flex items-center space-x-1">
                            <span className={`font-medium ${message.direction === 'outbound' ? 'text-blue-600' : 'text-green-600'}`}>
                              {message.direction === 'outbound' ? 'You' : 'Customer'}:
                            </span>
                            <span className="text-gray-600 truncate">{message.content}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Calls & Texts */}
          {callsAndTexts.length > 0 && (
            <div>
              <h4 className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Calls &amp; Messages</h4>
              <div className="space-y-2">
                {callsAndTexts
                  .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                  .map((comm) => (
                    <div key={comm.id} className="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
                      <div className="w-6 h-6 bg-white rounded-full flex items-center justify-center border">
                        {getCommIcon(comm.type, comm.direction)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <div className="flex items-center space-x-2">
                            <span className="text-sm font-medium capitalize">
                              {comm.type} {comm.direction === 'inbound' ? 'received' : 'sent'}
                            </span>
                            {comm.duration && (
                              <Badge variant="outline" className="text-xs">
                                {comm.duration}
                              </Badge>
                            )}
                          </div>
                          <p className="text-xs text-gray-500">{formatRelativeTime(comm.timestamp)}</p>
                        </div>
                        <p className="text-xs text-gray-600">{comm.content}</p>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          )}
        </div>
      )
    },
    {
      id: 'tasks',
      title: 'TASKS',
      icon: CheckSquare,
      isOpen: openSections.has('tasks'),
      content: (
        <div className="space-y-3">
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <input type="checkbox" className="rounded" />
            <span className="text-sm">Schedule roof inspection</span>
          </div>
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <input type="checkbox" className="rounded" defaultChecked />
            <span className="text-sm line-through text-gray-500">Send initial quote</span>
          </div>
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <input type="checkbox" className="rounded" />
            <span className="text-sm">Follow up on proposal</span>
          </div>
        </div>
      )
    }
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black bg-opacity-50" onClick={onClose}>
      <div 
        className="fixed bottom-0 left-0 right-0 bg-white rounded-t-3xl shadow-xl max-h-[600px] overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Drag Handle */}
        <div className="flex justify-center py-3">
          <div className="w-8 h-1 bg-gray-300 rounded-full" />
        </div>
        
        {/* Header */}
        <div className="flex items-center justify-between px-4 pb-4 border-b border-gray-200">
          <div>
            <h2 className="font-semibold text-lg">{card.title}</h2>
            <p className="text-sm text-gray-500">{card.stage}</p>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose} className="h-8 w-8 p-0">
            <X className="w-4 h-4" />
          </Button>
        </div>
        
        {/* Content */}
        <div className="overflow-y-auto" style={{ maxHeight: '500px' }}>
          <div className="p-4 space-y-4">
            {sections.map((section) => {
              const Icon = section.icon;
              return (
                <div key={section.id} className="border border-gray-200 rounded-lg overflow-hidden">
                  <button
                    onClick={() => toggleSection(section.id)}
                    className="w-full flex items-center justify-between p-3 bg-gray-50 hover:bg-gray-100 transition-colors"
                  >
                    <div className="flex items-center space-x-2">
                      <Icon className="w-4 h-4 text-gray-600" />
                      <span className="text-xs font-medium text-gray-600 uppercase tracking-wide">
                        {section.title}
                      </span>
                    </div>
                    {section.isOpen ? (
                      <ChevronDown className="w-4 h-4 text-gray-600" />
                    ) : (
                      <ChevronRight className="w-4 h-4 text-gray-600" />
                    )}
                  </button>
                  
                  {section.isOpen && (
                    <div className="p-4 bg-white">
                      {section.content}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}