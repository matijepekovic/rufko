import { useState } from 'react';
import { Handshake } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { LeadsList } from '../LeadsList';
import { KanbanBoard } from '../KanbanBoard';
import { QuotesList } from '../QuotesList';
import { KanbanCardData } from '../KanbanCard';

interface SalesScreenProps {
  onNavigateToCustomer?: (customer: KanbanCardData) => void;
}

export function SalesScreen({ onNavigateToCustomer }: SalesScreenProps) {
  const [activeTab, setActiveTab] = useState('leads');

  const handleCall = (phone: string) => {
    console.log('Calling:', phone);
  };

  const handleNote = (cardId: string) => {
    console.log('Adding note to card:', cardId);
  };

  const handleTask = (cardId: string) => {
    console.log('Adding task to card:', cardId);
  };

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <div className="flex-shrink-0 bg-surface border-b border-stroke navbar-safe py-3">
        <div className="flex items-center space-x-2">
          <Handshake className="w-5 h-5 text-primary" />
          <h1 className="text-gray-900">Sales</h1>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="flex-1 flex flex-col">
        <div className="flex-shrink-0 bg-surface border-b border-stroke">
          <TabsList className="grid w-full grid-cols-3 bg-transparent p-0 h-auto">
            <TabsTrigger 
              value="leads" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Leads
            </TabsTrigger>
            <TabsTrigger 
              value="kanban" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Kanban
            </TabsTrigger>
            <TabsTrigger 
              value="quotes" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Quotes
            </TabsTrigger>
          </TabsList>
        </div>

        <div className="flex-1">
          <TabsContent value="leads" className="m-0 h-full">
            <LeadsList />
          </TabsContent>
          
          <TabsContent value="kanban" className="m-0 h-full">
            <KanbanBoard 
              onCall={handleCall}
              onNote={handleNote}
              onTask={handleTask}
              onNavigateToCustomer={onNavigateToCustomer}
            />
          </TabsContent>
          
          <TabsContent value="quotes" className="m-0 h-full">
            <QuotesList />
          </TabsContent>
        </div>
      </Tabs>
    </div>
  );
}