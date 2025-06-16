import { Home, Handshake, Calendar, Archive, Settings } from 'lucide-react';

interface BottomNavigationProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export function BottomNavigation({ activeTab, onTabChange }: BottomNavigationProps) {
  const tabs = [
    { id: 'dash', label: 'Dash', icon: Home },
    { id: 'sales', label: 'Sales', icon: Handshake },
    { id: 'jobs', label: 'Jobs', icon: Calendar },
    { id: 'vault', label: 'Vault', icon: Archive },
    { id: 'tools', label: 'Tools', icon: Settings },
  ];

  return (
    <div 
      className="fixed bottom-0 left-0 right-0 bg-surface border-t border-stroke z-50 shadow-lg"
      style={{ height: '56px' }}
    >
      <div className="flex justify-around items-center h-full max-w-md mx-auto">
        {tabs.map(({ id, label, icon: Icon }) => {
          const isActive = activeTab === id;
          return (
            <button
              key={id}
              onClick={() => onTabChange(id)}
              className={`flex flex-col items-center justify-center min-h-12 min-w-12 px-2 py-1 rounded-lg transition-colors ${
                isActive 
                  ? 'text-primary bg-primary/10' 
                  : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'
              }`}
            >
              <Icon size={20} className="mb-1" />
              <span className="text-xs leading-none">{label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}