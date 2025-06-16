import { TrendingUp } from 'lucide-react';

interface SalesSparklineProps {
  onTap?: () => void;
}

export function SalesSparkline({ onTap }: SalesSparklineProps) {
  // Mock data for the last 7 days
  const salesData = [4200, 3800, 5100, 4600, 6200, 5800, 7100];
  const maxValue = Math.max(...salesData);
  const minValue = Math.min(...salesData);
  
  // Calculate points for the sparkline
  const points = salesData.map((value, index) => {
    const x = (index / (salesData.length - 1)) * 100;
    const y = 100 - ((value - minValue) / (maxValue - minValue)) * 100;
    return `${x},${y}`;
  }).join(' ');

  const currentValue = salesData[salesData.length - 1];
  const previousValue = salesData[salesData.length - 2];
  const trend = ((currentValue - previousValue) / previousValue) * 100;

  return (
    <button
      onClick={onTap}
      className="w-full h-20 bg-card rounded-lg border border-stroke p-3 hover:shadow-md transition-all duration-200"
    >
      <div className="flex items-center justify-between mb-2">
        <div className="text-left">
          <div className="text-xs text-muted-foreground">Last 7 days sales</div>
          <div className="text-lg font-semibold">${currentValue.toLocaleString()}</div>
        </div>
        <div className="flex items-center text-xs text-green-600">
          <TrendingUp className="w-3 h-3 mr-1" />
          +{trend.toFixed(1)}%
        </div>
      </div>
      
      {/* Sparkline Chart */}
      <div className="h-8 w-full">
        <svg width="100%" height="100%" viewBox="0 0 100 100" className="overflow-visible">
          <polyline
            points={points}
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-primary"
          />
          {/* Data points */}
          {salesData.map((value, index) => {
            const x = (index / (salesData.length - 1)) * 100;
            const y = 100 - ((value - minValue) / (maxValue - minValue)) * 100;
            return (
              <circle
                key={index}
                cx={x}
                cy={y}
                r="1.5"
                fill="currentColor"
                className="text-primary"
              />
            );
          })}
        </svg>
      </div>
    </button>
  );
}