import { Badge } from './ui/badge';

interface UrgencyChipsProps {
  selected: 'all' | 'hot' | 'warm' | 'cold' | 'dormant';
  onSelectionChange: (urgency: 'all' | 'hot' | 'warm' | 'cold' | 'dormant') => void;
  counts: {
    all: number;
    hot: number;
    warm: number;
    cold: number;
    dormant: number;
  };
}

export function UrgencyChips({ selected, onSelectionChange, counts }: UrgencyChipsProps) {
  const urgencyOptions = [
    { 
      value: 'all', 
      label: 'All', 
      color: 'bg-gray-100 text-gray-700 border-gray-200',
      selectedColor: 'bg-gray-200 text-gray-800 border-gray-300',
      count: counts.all
    },
    { 
      value: 'hot', 
      label: 'Hot', 
      color: 'bg-red-hot/20 text-red-800 border-red-200',
      selectedColor: 'bg-red-hot text-red-800 border-red-300',
      count: counts.hot
    },
    { 
      value: 'warm', 
      label: 'Warm', 
      color: 'bg-orange-risk/20 text-orange-800 border-orange-200',
      selectedColor: 'bg-orange-risk text-orange-800 border-orange-300',
      count: counts.warm
    },
    { 
      value: 'cold', 
      label: 'Cold', 
      color: 'bg-blue-100/50 text-blue-700 border-blue-200',
      selectedColor: 'bg-blue-100 text-blue-800 border-blue-300',
      count: counts.cold
    },
    { 
      value: 'dormant', 
      label: 'Dormant', 
      color: 'bg-yellow-idle/20 text-yellow-800 border-yellow-200',
      selectedColor: 'bg-yellow-idle text-yellow-800 border-yellow-300',
      count: counts.dormant
    }
  ];

  return (
    <div className="flex space-x-2 overflow-x-auto pb-1">
      {urgencyOptions.map((option) => (
        <button
          key={option.value}
          onClick={() => onSelectionChange(option.value as 'all' | 'hot' | 'warm' | 'cold' | 'dormant')}
          className={`
            px-3 py-1.5 rounded-full text-xs font-medium border transition-all whitespace-nowrap flex-shrink-0
            ${selected === option.value 
              ? option.selectedColor 
              : option.color + ' hover:opacity-80'
            }
          `}
        >
          {option.label}
          <span className="ml-1 opacity-70">({option.count})</span>
        </button>
      ))}
    </div>
  );
}