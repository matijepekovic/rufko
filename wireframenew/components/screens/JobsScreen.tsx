import { useState } from 'react';
import { Calendar } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { ActiveTab } from '../jobs/ActiveTab';
import { ScheduledTab } from '../jobs/ScheduledTab';
import { CompleteTab } from '../jobs/CompleteTab';
import { JobRoutesTab } from '../jobs/JobRoutesTab';
import { DoorKnockingTab } from '../jobs/DoorKnockingTab';

export function JobsScreen() {
  const [activeTab, setActiveTab] = useState('scheduled');

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <div className="flex-shrink-0 bg-surface border-b border-stroke navbar-safe py-3">
        <div className="flex items-center space-x-2">
          <Calendar className="w-5 h-5 text-primary" />
          <h1 className="text-gray-900">Jobs</h1>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="flex-1 flex flex-col">
        <div className="flex-shrink-0 bg-surface border-b border-stroke">
          <TabsList className="grid w-full grid-cols-5 bg-transparent p-0 h-auto">
            <TabsTrigger 
              value="active" 
              className="relative py-3 px-1 text-xs data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Active
            </TabsTrigger>
            <TabsTrigger 
              value="scheduled" 
              className="relative py-3 px-1 text-xs data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Scheduled
            </TabsTrigger>
            <TabsTrigger 
              value="complete" 
              className="relative py-3 px-1 text-xs data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Complete
            </TabsTrigger>
            <TabsTrigger 
              value="routes" 
              className="relative py-3 px-1 text-xs data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Job Routes
            </TabsTrigger>
            <TabsTrigger 
              value="door-knocking" 
              className="relative py-3 px-1 text-xs data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Door Knocking
            </TabsTrigger>
          </TabsList>
        </div>

        <div className="flex-1">
          <TabsContent value="active" className="m-0 h-full">
            <ActiveTab />
          </TabsContent>
          
          <TabsContent value="scheduled" className="m-0 h-full">
            <ScheduledTab />
          </TabsContent>
          
          <TabsContent value="complete" className="m-0 h-full">
            <CompleteTab />
          </TabsContent>

          <TabsContent value="routes" className="m-0 h-full">
            <JobRoutesTab />
          </TabsContent>

          <TabsContent value="door-knocking" className="m-0 h-full">
            <DoorKnockingTab />
          </TabsContent>
        </div>
      </Tabs>
    </div>
  );
}