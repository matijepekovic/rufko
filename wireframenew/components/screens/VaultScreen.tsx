import { useState } from 'react';
import { Archive } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { CatalogTab } from '../vault/CatalogTab';
import { InventoryTab } from '../vault/InventoryTab';
import { SubsTab } from '../vault/SubsTab';

export function VaultScreen() {
  const [activeTab, setActiveTab] = useState('catalog');

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <div className="flex-shrink-0 bg-surface border-b border-stroke navbar-safe py-3">
        <div className="flex items-center space-x-2">
          <Archive className="w-5 h-5 text-primary" />
          <h1 className="text-gray-900">Vault</h1>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="flex-1 flex flex-col">
        <div className="flex-shrink-0 bg-surface border-b border-stroke">
          <TabsList className="grid w-full grid-cols-3 bg-transparent p-0 h-auto">
            <TabsTrigger 
              value="catalog" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Catalog
            </TabsTrigger>
            <TabsTrigger 
              value="inventory" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Inventory
            </TabsTrigger>
            <TabsTrigger 
              value="subs" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Sub-contractors
            </TabsTrigger>
          </TabsList>
        </div>

        <div className="flex-1">
          <TabsContent value="catalog" className="m-0 h-full">
            <CatalogTab />
          </TabsContent>
          
          <TabsContent value="inventory" className="m-0 h-full">
            <InventoryTab />
          </TabsContent>
          
          <TabsContent value="subs" className="m-0 h-full">
            <SubsTab />
          </TabsContent>
        </div>
      </Tabs>
    </div>
  );
}