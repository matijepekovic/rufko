import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { KanbanCard, KanbanCardData } from './KanbanCard';
import { KanbanSortDropdown, SortOptions } from './KanbanSortDropdown';
import { useDrop } from 'react-dnd';

export interface KanbanColumnData {
  id: string;
  title: string;
  count: number;
  cards: KanbanCardData[];
  boardColor?: string;
}

interface KanbanColumnProps {
  column: KanbanColumnData;
  onCardClick?: (card: KanbanCardData) => void;
  onCall?: (phone: string) => void;
  onNote?: (cardId: string) => void;
  onTask?: (cardId: string) => void;
  sortOptions?: SortOptions | null;
  onSortChange?: (columnId: string, sortOptions: SortOptions | null) => void;
  onCardMove?: (cardId: string, targetColumnId: string) => void;
}

export function KanbanColumn({ 
  column, 
  onCardClick, 
  onCall, 
  onNote, 
  onTask,
  sortOptions,
  onSortChange,
  onCardMove
}: KanbanColumnProps) {
  
  const [{ isOver, canDrop }, drop] = useDrop({
    accept: 'kanban-card',
    drop: (item: { card: KanbanCardData }) => {
      if (item.card.stage !== column.title) {
        onCardMove?.(item.card.id, column.id);
      }
    },
    collect: (monitor) => ({
      isOver: !!monitor.isOver(),
      canDrop: !!monitor.canDrop(),
    }),
  });

  // Sort cards based on the current sort options
  const getSortedCards = () => {
    if (!sortOptions) {
      return column.cards;
    }
    
    const sorted = [...column.cards].sort((a, b) => {
      let comparison = 0;
      
      switch (sortOptions.field) {
        case 'urgency':
          const urgencyOrder = { hot: 4, warm: 3, cold: 2, dormant: 1 };
          const aUrgency = urgencyOrder[a.status] || 0;
          const bUrgency = urgencyOrder[b.status] || 0;
          comparison = aUrgency - bUrgency;
          break;
          
        case 'dateCreated':
          comparison = a.dateCreated.getTime() - b.dateCreated.getTime();
          break;
          
        case 'lastInteraction':
          comparison = a.lastInteractionDate.getTime() - b.lastInteractionDate.getTime();
          break;
          
        default:
          return 0;
      }
      
      return sortOptions.direction === 'desc' ? -comparison : comparison;
    });
    
    return sorted;
  };

  const handleSortChange = (newSortOptions: SortOptions | null) => {
    onSortChange?.(column.id, newSortOptions);
  };

  const getDropZoneStyle = () => {
    if (isOver && canDrop) {
      return 'bg-primary/10 border-primary border-2 border-dashed';
    }
    if (canDrop) {
      return 'border-gray-300 border-2 border-dashed';
    }
    return '';
  };

  return (
    <div 
      ref={drop}
      className={`flex flex-col flex-shrink-0 h-full transition-all duration-200 ${getDropZoneStyle()}`} 
      style={{ width: '300px' }}
    >
      {/* Column Header */}
      <div className="flex items-center justify-between mb-3 px-1 flex-shrink-0">
        <div className="flex items-center space-x-2">
          <h4 className="font-semibold text-base text-gray-900">
            {column.title}
          </h4>
          <Badge 
            variant="secondary" 
            className="text-xs px-2 py-0.5 bg-gray-100 text-gray-600"
          >
            {column.count}
          </Badge>
        </div>
        
        <KanbanSortDropdown
          currentSort={sortOptions}
          onSortChange={handleSortChange}
        />
      </div>
      
      {/* Cards Container - Now fills remaining space */}
      <div className={`flex-1 space-y-3 overflow-y-auto scrollable rounded-lg p-2 transition-all duration-200 ${
        isOver && canDrop ? 'bg-primary/5' : ''
      }`}>
        {getSortedCards().map((card) => (
          <KanbanCard
            key={card.id}
            card={{ ...card, boardColor: column.boardColor }}
            onCardClick={onCardClick}
            onCall={onCall}
            onNote={onNote}
            onTask={onTask}
          />
        ))}
        
        {/* Drop Zone Indicator */}
        {isOver && canDrop && (
          <div className="h-16 border-2 border-dashed border-primary bg-primary/10 rounded-lg flex items-center justify-center">
            <span className="text-sm text-primary font-medium">Drop card here</span>
          </div>
        )}
      </div>
    </div>
  );
}