import { useDragLayer } from 'react-dnd';
import { KanbanCardData } from './KanbanCard';

function getItemStyles(initialOffset: any, currentOffset: any, isSnapToGrid: boolean) {
  if (!initialOffset || !currentOffset) {
    return {
      display: 'none',
    };
  }

  const { x, y } = currentOffset;

  const transform = `translate(${x}px, ${y}px) rotate(5deg) scale(1.05)`;
  return {
    transform,
    WebkitTransform: transform,
    // Ensure the dragged item appears above everything else
    zIndex: 9999,
  };
}

interface DragLayerProps {}

export function KanbanDragLayer({}: DragLayerProps) {
  const {
    itemType,
    isDragging,
    item,
    initialOffset,
    currentOffset,
  } = useDragLayer((monitor) => ({
    item: monitor.getItem(),
    itemType: monitor.getItemType(),
    initialOffset: monitor.getInitialSourceClientOffset(),
    currentOffset: monitor.getClientOffset(),
    isDragging: monitor.isDragging(),
  }));

  function renderItem() {
    if (itemType !== 'kanban-card') {
      return null;
    }

    const card = item.card as KanbanCardData;

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
        className={`relative p-3 rounded-lg border shadow-2xl ${getUrgencyColor(card.status)}`}
        style={{ 
          width: '268px',
          opacity: 0.9,
          pointerEvents: 'none'
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
          </div>
          
          {/* Value */}
          <div className="flex items-center justify-between">
            <span className="font-semibold text-base text-gray-900">
              ${card.value.toLocaleString()}
            </span>
            <div className={`text-xs px-2 py-0.5 rounded-full ${getStatusColor(card.status)}`}>
              {card.status}
            </div>
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
        </div>
      </div>
    );
  }

  if (!isDragging) {
    return null;
  }

  return (
    <div 
      className="fixed top-0 left-0 pointer-events-none"
      style={{ zIndex: 9999 }}
    >
      <div style={getItemStyles(initialOffset, currentOffset, false)}>
        {renderItem()}
      </div>
    </div>
  );
}