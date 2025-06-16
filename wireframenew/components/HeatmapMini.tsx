import { MapPin, TrendingUp } from 'lucide-react';

interface HeatmapMiniProps {
  onTap?: () => void;
}

export function HeatmapMini({ onTap }: HeatmapMiniProps) {
  return (
    <button
      onClick={onTap}
      className="w-full h-35 bg-card rounded-lg border border-stroke p-3 hover:shadow-md transition-all duration-200"
    >
      <div className="flex items-center justify-between mb-3">
        <h3 className="font-semibold text-left">Route Hotspots</h3>
        <MapPin className="w-5 h-5 text-primary" />
      </div>
      
      {/* Map Placeholder */}
      <div className="w-full h-24 bg-gradient-to-br from-blue-100 to-green-100 rounded-lg relative overflow-hidden">
        {/* Mock heat spots */}
        <div className="absolute top-4 left-6 w-3 h-3 bg-red-500 rounded-full opacity-70"></div>
        <div className="absolute top-8 right-8 w-2 h-2 bg-yellow-500 rounded-full opacity-70"></div>
        <div className="absolute bottom-6 left-12 w-4 h-4 bg-red-600 rounded-full opacity-70"></div>
        <div className="absolute bottom-4 right-6 w-2 h-2 bg-orange-500 rounded-full opacity-70"></div>
        <div className="absolute top-12 left-1/2 w-3 h-3 bg-red-400 rounded-full opacity-70"></div>
        
        {/* Overlay gradient */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/10 to-transparent"></div>
      </div>
      
      <div className="flex items-center justify-between mt-2 text-xs text-muted-foreground">
        <span>High activity areas</span>
        <div className="flex items-center">
          <TrendingUp className="w-3 h-3 mr-1" />
          <span>View routes</span>
        </div>
      </div>
    </button>
  );
}