import { Phone, MessageSquare, CheckSquare, ChevronRight, Calendar, Clock } from 'lucide-react';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { useDrag } from 'react-dnd';
import { useEffect } from 'react';
import { getEmptyImage } from 'react-dnd-html5-backend';

export interface KanbanCardData {
  id: string;
  title: string;
  stage: string;
  value: number;
  daysIdle: number;
  status: 'hot' | 'warm' | 'cold' | 'dormant';
  tags: string[];
  phone: string;
  lastContact: string;
  nextAction: string;
  boardColor?: string;
  // New fields for sorting
  dateCreated: Date;
  lastInteractionDate: Date;
}

interface KanbanCardProps {
  card: KanbanCardData;
  onCardClick?: (card: KanbanCardData) => void;
  onCall?: (phone: string) => void;
  onNote?: (cardId: string) => void;
  onTask?: (cardId: string) => void;
}

export function KanbanCard({ card, onCardClick, onCall, onNote, onTask }: KanbanCardProps) {
  const [{ isDragging }, drag, preview] = useDrag({
    type: 'kanban-card',
    item: { card },
    collect: (monitor) => ({
      isDragging: !!monitor.isDragging(),
    }),
  });

  // Use empty image as drag preview so we can use our custom drag layer
  useEffect(() => {
    preview(getEmptyImage(), { captureDraggingState: true });
  }, [preview]);

  const getUrgencyColor = (status: string) => {
    switch (status) {
      case 'hot': return 'bg-red-50 border-red-200';
      case 'warm': return 'bg-yellow-50 border-yellow-200';
      case 'cold': return 'bg-blue-50 border-blue-200';
      case 'dormant': return 'bg-gray-50 border-gray-200';
      default: return 'bg-gray-50 border-gray-200';
    }
  };

  const getValueBarColor = (status: string) => {
    switch (status) {
      case 'hot': return '#EF4444';
      case 'warm': return '#F59E0B';
      case 'cold': return '#3B82F6';
      case 'dormant': return '#6B7280';
      default: return '#6B7280';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'hot': return 'bg-red-100 text-red-800';
      case 'warm': return 'bg-yellow-100 text-yellow-800';
      case 'cold': return 'bg-blue-100 text-blue-800';
      case 'dormant': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div 
      ref={drag}
      className={`relative p-3 rounded-lg border cursor-pointer transition-all hover:shadow-md ${getUrgencyColor(card.status)} ${
        isDragging ? 'opacity-40' : ''
      }`}
      onClick={() => !isDragging && onCardClick?.(card)}
      style={{ 
        width: '268px',
        touchAction: 'none' // Prevents scrolling while dragging on mobile
      }}
    >
      {/* Value Bar */}
      <div 
        className="absolute left-0 top-0 bottom-0 w-1 rounded-l-lg"
        style={{ backgroundColor: getValueBarColor(card.status) }}
      />
      
      {/* Content Stack */}
      <div className="ml-2 space-y-3">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <h4 className="font-semibold text-sm text-gray-900 truncate">
              {card.title}
            </h4>
            <p className="text-xs text-gray-500 mt-0.5">
              {card.stage}
            </p>
          </div>
          <ChevronRight className="w-4 h-4 text-gray-400 flex-shrink-0 ml-2" />
        </div>
        
        {/* Value */}
        <div className="flex items-center justify-between">
          <span className="font-semibold text-base text-gray-900">
            ${card.value.toLocaleString()}
          </span>
          <Badge className={`text-xs px-2 py-0.5 ${getStatusColor(card.status)}`}>
            {card.status}
          </Badge>
        </div>
        
        {/* Tags */}
        <div className="flex flex-wrap gap-1">
          {card.tags.slice(0, 2).map((tag, index) => (
            <span 
              key={index}
              className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded-full"
            >
              {tag}
            </span>
          ))}
          {card.tags.length > 2 && (
            <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded-full">
              +{card.tags.length - 2}
            </span>
          )}
        </div>
        
        {/* Last Contact & Next Action */}
        <div className="space-y-1">
          <div className="flex items-center space-x-1">
            <Clock className="w-3 h-3 text-gray-400" />
            <span className="text-xs text-gray-500">{card.lastContact}</span>
          </div>
          <div className="flex items-center space-x-1">
            <Calendar className="w-3 h-3 text-gray-400" />
            <span className="text-xs text-gray-600 truncate">{card.nextAction}</span>
          </div>
        </div>
        
        {/* Quick Actions */}
        <div className="flex items-center space-x-2 pt-2 border-t border-gray-200">
          <Button
            variant="ghost"
            size="sm"
            className="h-8 px-2 text-xs"
            onClick={(e) => {
              e.stopPropagation();
              onCall?.(card.phone);
            }}
          >
            <Phone className="w-3 h-3 mr-1" />
            Call
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 px-2 text-xs"
            onClick={(e) => {
              e.stopPropagation();
              onNote?.(card.id);
            }}
          >
            <MessageSquare className="w-3 h-3 mr-1" />
            Note
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 px-2 text-xs"
            onClick={(e) => {
              e.stopPropagation();
              onTask?.(card.id);
            }}
          >
            <CheckSquare className="w-3 h-3 mr-1" />
            Task
          </Button>
        </div>
      </div>
    </div>
  );
}