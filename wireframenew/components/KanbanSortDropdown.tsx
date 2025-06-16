import { useState } from 'react';
import { ChevronDown, ArrowUpDown, Flame, Calendar, Clock, ArrowUp, ArrowDown } from 'lucide-react';
import { Button } from './ui/button';
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover';

export type SortField = 'urgency' | 'dateCreated' | 'lastInteraction';
export type SortDirection = 'asc' | 'desc';

export interface SortOptions {
  field: SortField;
  direction: SortDirection;
}

interface KanbanSortDropdownProps {
  currentSort?: SortOptions | null;
  onSortChange: (sortOptions: SortOptions | null) => void;
}

export function KanbanSortDropdown({ currentSort, onSortChange }: KanbanSortDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);

  const sortOptions = [
    {
      field: 'urgency' as SortField,
      label: 'Urgency Score',
      icon: Flame,
      description: 'Sort by hot → warm → cold → dormant'
    },
    {
      field: 'dateCreated' as SortField,
      label: 'Date Created',
      icon: Calendar,
      description: 'Sort by when the lead was created'
    },
    {
      field: 'lastInteraction' as SortField,
      label: 'Last Interaction',
      icon: Clock,
      description: 'Sort by most recent contact'
    }
  ];

  const handleSortSelect = (field: SortField, direction: SortDirection) => {
    onSortChange({ field, direction });
    setIsOpen(false);
  };

  const handleClearSort = () => {
    onSortChange(null);
    setIsOpen(false);
  };

  const getSortIcon = () => {
    if (!currentSort) return <ChevronDown className="w-4 h-4" />;
    
    const option = sortOptions.find(opt => opt.field === currentSort.field);
    if (!option) return <ChevronDown className="w-4 h-4" />;
    
    const IconComponent = option.icon;
    return (
      <div className="flex items-center space-x-1">
        <IconComponent className="w-3 h-3" />
        {currentSort.direction === 'asc' ? (
          <ArrowUp className="w-3 h-3" />
        ) : (
          <ArrowDown className="w-3 h-3" />
        )}
      </div>
    );
  };

  const getCurrentSortLabel = () => {
    if (!currentSort) return null;
    const option = sortOptions.find(opt => opt.field === currentSort.field);
    return option ? `${option.label} (${currentSort.direction === 'asc' ? 'Ascending' : 'Descending'})` : null;
  };

  return (
    <Popover open={isOpen} onOpenChange={setIsOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={`h-6 w-6 p-0 ${currentSort ? 'text-primary' : 'text-gray-400 hover:text-gray-600'}`}
          title={getCurrentSortLabel() || 'Sort column'}
        >
          {getSortIcon()}
        </Button>
      </PopoverTrigger>
      
      <PopoverContent className="w-64 p-2" align="end">
        <div className="space-y-1">
          <div className="px-2 py-1.5 text-xs font-medium text-muted-foreground border-b">
            Sort cards by
          </div>
          
          {sortOptions.map((option) => (
            <div key={option.field} className="space-y-1">
              {/* Ascending option */}
              <Button
                variant="ghost"
                size="sm"
                className={`w-full justify-start h-auto p-2 ${
                  currentSort?.field === option.field && currentSort?.direction === 'asc'
                    ? 'bg-primary/10 text-primary'
                    : 'hover:bg-accent'
                }`}
                onClick={() => handleSortSelect(option.field, 'asc')}
              >
                <div className="flex items-center space-x-2 flex-1">
                  <option.icon className="w-4 h-4" />
                  <ArrowUp className="w-3 h-3" />
                  <div className="text-left">
                    <div className="text-xs font-medium">{option.label}</div>
                    <div className="text-xs text-muted-foreground">
                      {option.field === 'urgency' ? 'Dormant → Hot' : 'Oldest → Newest'}
                    </div>
                  </div>
                </div>
              </Button>
              
              {/* Descending option */}
              <Button
                variant="ghost"
                size="sm"
                className={`w-full justify-start h-auto p-2 ${
                  currentSort?.field === option.field && currentSort?.direction === 'desc'
                    ? 'bg-primary/10 text-primary'
                    : 'hover:bg-accent'
                }`}
                onClick={() => handleSortSelect(option.field, 'desc')}
              >
                <div className="flex items-center space-x-2 flex-1">
                  <option.icon className="w-4 h-4" />
                  <ArrowDown className="w-3 h-3" />
                  <div className="text-left">
                    <div className="text-xs font-medium">{option.label}</div>
                    <div className="text-xs text-muted-foreground">
                      {option.field === 'urgency' ? 'Hot → Dormant' : 'Newest → Oldest'}
                    </div>
                  </div>
                </div>
              </Button>
            </div>
          ))}
          
          {currentSort && (
            <>
              <div className="border-t my-1" />
              <Button
                variant="ghost"
                size="sm"
                className="w-full justify-start text-xs text-muted-foreground"
                onClick={handleClearSort}
              >
                <ArrowUpDown className="w-3 h-3 mr-2" />
                Clear Sort
              </Button>
            </>
          )}
        </div>
      </PopoverContent>
    </Popover>
  );
}