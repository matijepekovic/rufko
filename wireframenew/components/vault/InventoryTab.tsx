import { useState } from 'react';
import { Truck, Package, AlertTriangle, Search } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';

interface InventoryItem {
  id: string;
  name: string;
  quantity: number;
  reorderLevel: number;
  status: 'in-stock' | 'low' | 'out-of-stock';
}

export function InventoryTab() {
  const [inventoryTab, setInventoryTab] = useState<'stock' | 'deliveries' | 'low'>('stock');

  const mockInventory: InventoryItem[] = [
    {
      id: '1',
      name: 'Asphalt Shingles - Premium',
      quantity: 45,
      reorderLevel: 20,
      status: 'in-stock'
    },
    {
      id: '2',
      name: 'Aluminum Gutters 6"',
      quantity: 8,
      reorderLevel: 15,
      status: 'low'
    },
    {
      id: '3',
      name: 'Roofing Nails 1.5"',
      quantity: 0,
      reorderLevel: 10,
      status: 'out-of-stock'
    },
    {
      id: '4',
      name: 'Waterproof Membrane',
      quantity: 25,
      reorderLevel: 12,
      status: 'in-stock'
    },
    {
      id: '5',
      name: 'Ridge Vent System',
      quantity: 3,
      reorderLevel: 8,
      status: 'low'
    }
  ];

  const getStockStatusColor = (status: InventoryItem['status']) => {
    switch (status) {
      case 'in-stock': return 'bg-green-100 text-green-800';
      case 'low': return 'bg-yellow-100 text-yellow-800';
      case 'out-of-stock': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const lowStockItems = mockInventory.filter(item => item.status === 'low' || item.status === 'out-of-stock');

  return (
    <div className="flex flex-col h-full">
      {/* Search */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search inventory..."
            className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
          />
        </div>
      </div>

      {/* Inventory Tabs */}
      <Tabs value={inventoryTab} onValueChange={(value) => setInventoryTab(value as 'stock' | 'deliveries' | 'low')} className="flex-1 flex flex-col">
        <div className="flex-shrink-0 bg-surface border-b border-stroke">
          <TabsList className="grid w-full grid-cols-3 bg-transparent p-0 h-auto">
            <TabsTrigger 
              value="stock" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Stock
            </TabsTrigger>
            <TabsTrigger 
              value="deliveries" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Deliveries
            </TabsTrigger>
            <TabsTrigger 
              value="low" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Low Stock
              {lowStockItems.length > 0 && (
                <Badge className="ml-2 h-5 w-5 p-0 flex items-center justify-center text-xs bg-red-500">
                  {lowStockItems.length}
                </Badge>
              )}
            </TabsTrigger>
          </TabsList>
        </div>

        <div className="flex-1 overflow-y-auto scrollable">
          <TabsContent value="stock" className="m-0 p-4">
            <div className="space-y-3">
              {mockInventory.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke"
                >
                  <div className="flex-shrink-0">
                    <Package size={20} className="text-muted-foreground" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="font-medium text-sm truncate">
                      {item.name}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Reorder at: {item.reorderLevel} units
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <div className="font-semibold text-sm">
                      {item.quantity} units
                    </div>
                    <Badge className={`text-xs px-2 py-0.5 ${getStockStatusColor(item.status)}`}>
                      {item.status.replace('-', ' ')}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </TabsContent>
          
          <TabsContent value="deliveries" className="m-0 p-4">
            <div className="text-center py-8 text-muted-foreground">
              <Truck size={48} className="mx-auto mb-2" />
              <p className="text-sm">No deliveries scheduled</p>
            </div>
          </TabsContent>
          
          <TabsContent value="low" className="m-0 p-4">
            <div className="space-y-3">
              {lowStockItems.map((item) => (
                <div
                  key={item.id}
                  className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke"
                >
                  <div className="flex-shrink-0">
                    <AlertTriangle size={20} className="text-yellow-600" />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="font-medium text-sm truncate">
                      {item.name}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Reorder needed - Current: {item.quantity}, Min: {item.reorderLevel}
                    </div>
                  </div>
                  
                  <div className="text-right">
                    <Badge className={`text-xs px-2 py-0.5 ${getStockStatusColor(item.status)}`}>
                      {item.status.replace('-', ' ')}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </TabsContent>
        </div>
      </Tabs>
    </div>
  );
}