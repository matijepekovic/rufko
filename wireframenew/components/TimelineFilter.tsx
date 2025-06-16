import { useState } from 'react';
import { Calendar, Plus, Minus } from 'lucide-react';
import { Button } from './ui/button';
import { Popover, PopoverContent, PopoverTrigger } from './ui/popover';
import { Input } from './ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

interface TimelineOptions {
  timeAmount: number;
  timeUnit: 'days' | 'weeks' | 'months' | 'years';
}

interface TimelineFilterProps {
  options: TimelineOptions;
  onOptionsChange: (options: TimelineOptions) => void;
}

export function TimelineFilter({ options, onOptionsChange }: TimelineFilterProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [localOptions, setLocalOptions] = useState<TimelineOptions>(options);

  const timeUnits = [
    { value: 'days', label: 'Days' },
    { value: 'weeks', label: 'Weeks' },
    { value: 'months', label: 'Months' },
    { value: 'years', label: 'Years' }
  ];

  const handleTimeAmountChange = (value: string) => {
    const amount = parseInt(value) || 1;
    setLocalOptions(prev => ({ ...prev, timeAmount: Math.max(1, Math.min(999, amount)) }));
  };

  const handleIncrement = () => {
    setLocalOptions(prev => ({ ...prev, timeAmount: Math.min(999, prev.timeAmount + 1) }));
  };

  const handleDecrement = () => {
    setLocalOptions(prev => ({ ...prev, timeAmount: Math.max(1, prev.timeAmount - 1) }));
  };

  const handleTimeUnitChange = (unit: 'days' | 'weeks' | 'months' | 'years') => {
    setLocalOptions(prev => ({ ...prev, timeUnit: unit }));
  };

  const handleApply = () => {
    onOptionsChange(localOptions);
    setIsOpen(false);
  };

  const getDisplayText = () => {
    const { timeAmount, timeUnit } = options;
    if (timeAmount === 1) {
      return `${timeUnit.slice(0, -1)}`; // Remove 's' for singular
    }
    return `${timeAmount}${timeUnit.charAt(0)}`;
  };

  const isActive = options.timeAmount !== 30 || options.timeUnit !== 'days';

  return (
    <Popover open={isOpen} onOpenChange={setIsOpen}>
      <PopoverTrigger asChild>
        <Button 
          variant="ghost" 
          size="sm" 
          className={`h-8 w-8 p-0 ${isActive ? 'text-primary' : ''}`}
        >
          <Calendar size={18} />
        </Button>
      </PopoverTrigger>
      
      <PopoverContent className="w-64 p-4" align="end">
        <div className="space-y-4">
          <div className="space-y-2">
            <h4 className="font-medium">Show data from</h4>
            <div className="flex space-x-2">
              <div className="flex-1">
                {/* Custom number input with +/- buttons for mobile */}
                <div className="flex items-center border border-input rounded-md overflow-hidden bg-input-background">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 w-8 p-0 rounded-none border-none hover:bg-muted"
                    onClick={handleDecrement}
                    disabled={localOptions.timeAmount <= 1}
                  >
                    <Minus size={14} />
                  </Button>
                  <Input
                    type="number"
                    inputMode="numeric"
                    pattern="[0-9]*"
                    min="1"
                    max="999"
                    value={localOptions.timeAmount}
                    onChange={(e) => handleTimeAmountChange(e.target.value)}
                    className="text-center border-none bg-transparent h-8 px-2 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                    placeholder="30"
                  />
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 w-8 p-0 rounded-none border-none hover:bg-muted"
                    onClick={handleIncrement}
                    disabled={localOptions.timeAmount >= 999}
                  >
                    <Plus size={14} />
                  </Button>
                </div>
              </div>
              <div className="flex-1">
                <Select value={localOptions.timeUnit} onValueChange={handleTimeUnitChange}>
                  <SelectTrigger className="h-8">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {timeUnits.map((unit) => (
                      <SelectItem key={unit.value} value={unit.value}>
                        {unit.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          </div>
          
          <div className="flex space-x-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setLocalOptions({ timeAmount: 30, timeUnit: 'days' })}
              className="flex-1"
            >
              Reset
            </Button>
            <Button
              size="sm"
              onClick={handleApply}
              className="flex-1"
            >
              Apply
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  );
}