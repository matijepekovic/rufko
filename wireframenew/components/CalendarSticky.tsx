import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from './ui/button';

interface CalendarStickyProps {
  onDateChange?: (date: Date) => void;
}

export function CalendarSticky({ onDateChange }: CalendarStickyProps) {
  const today = new Date();
  const currentWeek = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(today);
    date.setDate(today.getDate() - today.getDay() + i);
    return date;
  });

  const jobIndicators = {
    0: 2, // Sunday
    1: 1, // Monday
    2: 3, // Tuesday
    3: 0, // Wednesday
    4: 2, // Thursday
    5: 1, // Friday
    6: 0, // Saturday
  };

  const dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  return (
    <div className="sticky top-0 z-10 bg-background border-b border-stroke" style={{ width: '412px', height: '64px' }}>
      <div className="flex items-center justify-between h-16 px-4">
        <Button variant="ghost" size="sm" className="h-8 w-8 p-0 flex-shrink-0">
          <ChevronLeft className="h-4 w-4" />
        </Button>
        
        <div className="flex-1 flex justify-center">
          <div className="grid grid-cols-7 gap-1" style={{ width: '300px' }}>
            {currentWeek.map((date, index) => {
              const isToday = date.toDateString() === today.toDateString();
              const jobCount = jobIndicators[index as keyof typeof jobIndicators];
              
              return (
                <button
                  key={date.toISOString()}
                  onClick={() => onDateChange?.(date)}
                  className={`flex flex-col items-center justify-center h-11 rounded-lg transition-colors ${
                    isToday 
                      ? 'bg-primary text-primary-foreground' 
                      : 'hover:bg-muted'
                  }`}
                  style={{ width: '40px' }}
                >
                  <span className="text-xs font-medium">{dayNames[index]}</span>
                  <span className="text-xs">{date.getDate()}</span>
                  {jobCount > 0 && (
                    <div className="w-1 h-1 bg-primary rounded-full mt-0.5" 
                         style={{ backgroundColor: isToday ? 'white' : 'var(--primary)' }} />
                  )}
                </button>
              );
            })}
          </div>
        </div>
        
        <Button variant="ghost" size="sm" className="h-8 w-8 p-0 flex-shrink-0">
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}