import { useState } from 'react';
import { X, ArrowUpDown, Filter } from 'lucide-react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogTrigger } from './ui/dialog';
import { Badge } from './ui/badge';

interface SortOptions {
  sortBy: 'urgency' | 'value' | 'activity' | 'date';
}

interface SortFilterDialogProps {
  options: SortOptions;
  onOptionsChange: (options: SortOptions) => void;
  type: 'leads' | 'quotes';
}

export function SortFilterDialog({ options, onOptionsChange, type }: SortFilterDialogProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [localOptions, setLocalOptions] = useState<SortOptions>(options);

  const sortOptions = [
    { 
      value: 'urgency', 
      label: 'Urgency', 
      description: 'Hot leads first',
      icon: '🔥'
    },
    { 
      value: 'value', 
      label: 'Value', 
      description: 'Highest value first',
      icon: '💰'
    },
    { 
      value: 'activity', 
      label: 'Activity', 
      description: 'Needs attention first',
      icon: '⏰'
    },
    { 
      value: 'date', 
      label: 'Date', 
      description: 'Newest first',
      icon: '📅'
    }
  ];

  const handleSortChange = (sortBy: 'urgency' | 'value' | 'activity' | 'date') => {
    setLocalOptions({ sortBy });
  };

  const handleApply = () => {
    onOptionsChange(localOptions);
    setIsOpen(false);
  };

  const isActive = options.sortBy !== 'urgency';

  const selectedSortOption = sortOptions.find(opt => opt.value === localOptions.sortBy);

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button 
          variant="outline" 
          className="relative justify-between text-xs h-8 px-3 min-w-[100px]"
        >
          <div className="flex items-center space-x-1">
            <ArrowUpDown className="w-3 h-3" />
            <span>Sort</span>
          </div>
          {isActive && (
            <Badge className="absolute -top-1 -right-1 h-4 w-4 p-0 flex items-center justify-center text-xs bg-primary text-primary-foreground">
              •
            </Badge>
          )}
        </Button>
      </DialogTrigger>
      
      <DialogContent className="w-full max-w-sm mx-auto rounded-t-xl rounded-b-xl animate-in slide-in-from-top-2 duration-300 top-[120px] translate-y-0">
        <DialogHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="flex flex-col space-y-1">
              <DialogTitle className="text-lg font-semibold">Sort {type}</DialogTitle>
              <DialogDescription className="text-sm text-muted-foreground">
                Choose how to order your {type}
              </DialogDescription>
            </div>
            <Button
              variant="ghost"
              size="sm"
              className="h-8 w-8 p-0"
              onClick={() => setIsOpen(false)}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        </DialogHeader>

        <div className="space-y-4">
          {/* Sort Options */}
          <div className="grid grid-cols-2 gap-2">
            {sortOptions.map((option) => (
              <button
                key={option.value}
                onClick={() => handleSortChange(option.value)}
                className={`p-3 rounded-lg border transition-all ${
                  localOptions.sortBy === option.value
                    ? 'border-primary bg-primary/5 text-primary'
                    : 'border-border bg-card hover:border-primary/50'
                }`}
              >
                <div className="text-lg mb-1">{option.icon}</div>
                <div className="text-sm font-medium">{option.label}</div>
                <div className="text-xs text-muted-foreground">{option.description}</div>
              </button>
            ))}
          </div>

          {/* Selected Option Display */}
          <div className="text-center p-3 bg-muted/30 rounded-lg">
            <div className="text-sm text-muted-foreground">
              Sorting by {selectedSortOption?.label.toLowerCase()}
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex space-x-2 pt-4 border-t">
          <Button
            variant="outline"
            onClick={() => setLocalOptions({ sortBy: 'urgency' })}
            className="flex-1"
          >
            Reset
          </Button>
          <Button
            onClick={handleApply}
            className="flex-1"
          >
            Apply
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}