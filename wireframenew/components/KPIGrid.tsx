import { TrendingUp, TrendingDown, Users, FileText, DollarSign, Calendar } from 'lucide-react';

interface KPICard {
  id: string;
  icon: React.ReactNode;
  label: string;
  value: string;
  statusColor: 'green' | 'red' | 'blue' | 'yellow';
  trend?: string;
}

interface KPIGridProps {
  onCardClick?: (cardId: string) => void;
}

export function KPIGrid({ onCardClick }: KPIGridProps) {
  const kpiData: KPICard[] = [
    {
      id: 'new-leads',
      icon: <Users className="w-6 h-6" />,
      label: 'New Leads',
      value: '24',
      statusColor: 'green',
      trend: '+12%'
    },
    {
      id: 'quotes-awaiting',
      icon: <FileText className="w-6 h-6" />,
      label: 'Quotes Awaiting',
      value: '8',
      statusColor: 'yellow',
      trend: '+2'
    },
    {
      id: 'revenue-mtd',
      icon: <DollarSign className="w-6 h-6" />,
      label: 'Revenue MTD',
      value: '$48.2K',
      statusColor: 'green',
      trend: '+18%'
    },
    {
      id: 'jobs-scheduled',
      icon: <Calendar className="w-6 h-6" />,
      label: 'Jobs Scheduled',
      value: '12',
      statusColor: 'blue',
      trend: 'Today'
    }
  ];

  const getStatusColor = (color: KPICard['statusColor']) => {
    switch (color) {
      case 'green': return 'text-green-600 bg-green-50 border-green-200';
      case 'red': return 'text-red-600 bg-red-50 border-red-200';
      case 'blue': return 'text-blue-600 bg-blue-50 border-blue-200';
      case 'yellow': return 'text-yellow-600 bg-yellow-50 border-yellow-200';
      default: return 'text-gray-600 bg-gray-50 border-gray-200';
    }
  };

  const getIconColor = (color: KPICard['statusColor']) => {
    switch (color) {
      case 'green': return 'text-green-600';
      case 'red': return 'text-red-600';
      case 'blue': return 'text-blue-600';
      case 'yellow': return 'text-yellow-600';
      default: return 'text-gray-600';
    }
  };

  return (
    <div className="grid grid-cols-2 gap-2">
      {kpiData.map((card) => (
        <button
          key={card.id}
          onClick={() => onCardClick?.(card.id)}
          className={`p-3 rounded-lg border transition-all duration-200 hover:shadow-md ${getStatusColor(card.statusColor)}`}
          style={{ minHeight: '120px' }}
        >
          <div className="flex flex-col items-start space-y-2">
            <div className={`${getIconColor(card.statusColor)}`}>
              {card.icon}
            </div>
            <div className="text-left">
              <div className="text-xs text-muted-foreground mb-1">
                {card.label}
              </div>
              <div className="text-2xl font-semibold">
                {card.value}
              </div>
              {card.trend && (
                <div className="text-xs text-muted-foreground mt-1">
                  {card.trend}
                </div>
              )}
            </div>
          </div>
        </button>
      ))}
    </div>
  );
}