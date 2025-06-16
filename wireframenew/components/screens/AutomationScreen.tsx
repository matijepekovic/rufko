import { Zap, Plus, Search, ArrowRight } from 'lucide-react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Card, CardContent } from '../ui/card';

export function AutomationScreen() {
  const automationItems = [
    {
      id: '1',
      name: 'Lead Follow-up',
      description: 'Automatically follow up with new leads',
      status: 'Active',
      count: 12
    },
    {
      id: '2',
      name: 'Appointment Reminders',
      description: 'Send reminders before appointments',
      status: 'Active',
      count: 8
    },
    {
      id: '3',
      name: 'Estimate Notifications',
      description: 'Notify when estimates are ready',
      status: 'Paused',
      count: 5
    },
    {
      id: '4',
      name: 'Weekly Reports',
      description: 'Generate weekly progress reports',
      status: 'Active',
      count: 3
    }
  ];

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="border-b border-gray-200 bg-background">
        <div className="flex items-center justify-between p-4 pb-2">
          <div className="flex items-center space-x-3">
            <div className="p-2 rounded-lg bg-primary/10">
              <Zap className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h1 className="font-medium text-lg">Automation</h1>
              <p className="text-sm text-gray-500">Workflow automation</p>
            </div>
          </div>
          <Button size="sm">
            <Plus className="w-4 h-4 mr-2" />
            New
          </Button>
        </div>

        {/* Search */}
        <div className="px-4 pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <Input
              placeholder="Search automations..."
              className="pl-10 bg-gray-50 border-gray-200"
            />
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        <div className="space-y-3">
          {automationItems.map((item) => (
            <Card key={item.id} className="cursor-pointer hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-1">
                      <h3 className="font-medium">{item.name}</h3>
                      <span className={`text-xs px-2 py-1 rounded-full ${
                        item.status === 'Active' 
                          ? 'bg-green-100 text-green-700' 
                          : 'bg-yellow-100 text-yellow-700'
                      }`}>
                        {item.status}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{item.description}</p>
                    <p className="text-xs text-gray-500">{item.count} executions this month</p>
                  </div>
                  <ArrowRight className="w-5 h-5 text-gray-400" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {automationItems.length === 0 && (
          <div className="text-center py-12">
            <Zap className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-medium text-gray-900 mb-2">No automations yet</h3>
            <p className="text-gray-500 mb-4">Create your first automation to get started</p>
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Create Automation
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}