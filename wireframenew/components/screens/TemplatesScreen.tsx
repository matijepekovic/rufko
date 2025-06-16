import { FileText, Plus, Search, ArrowRight } from 'lucide-react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Card, CardContent } from '../ui/card';

export function TemplatesScreen() {
  const templates = [
    {
      id: '1',
      name: 'Welcome Email',
      type: 'Email',
      description: 'Welcome new customers',
      lastUsed: '2 days ago'
    },
    {
      id: '2',
      name: 'Follow-up SMS',
      type: 'SMS',
      description: 'Follow up after consultation',
      lastUsed: '1 week ago'
    },
    {
      id: '3',
      name: 'Estimate Ready',
      type: 'Email',
      description: 'Notify when estimate is complete',
      lastUsed: '3 days ago'
    },
    {
      id: '4',
      name: 'Appointment Reminder',
      type: 'SMS',
      description: 'Remind about upcoming appointment',
      lastUsed: '1 day ago'
    }
  ];

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="border-b border-gray-200 bg-background">
        <div className="flex items-center justify-between p-4 pb-2">
          <div className="flex items-center space-x-3">
            <div className="p-2 rounded-lg bg-primary/10">
              <FileText className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h1 className="font-medium text-lg">Templates</h1>
              <p className="text-sm text-gray-500">Message templates</p>
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
              placeholder="Search templates..."
              className="pl-10 bg-gray-50 border-gray-200"
            />
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        <div className="space-y-3">
          {templates.map((template) => (
            <Card key={template.id} className="cursor-pointer hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-1">
                      <h3 className="font-medium">{template.name}</h3>
                      <span className={`text-xs px-2 py-1 rounded-full ${
                        template.type === 'Email' 
                          ? 'bg-blue-100 text-blue-700' 
                          : 'bg-green-100 text-green-700'
                      }`}>
                        {template.type}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{template.description}</p>
                    <p className="text-xs text-gray-500">Last used {template.lastUsed}</p>
                  </div>
                  <ArrowRight className="w-5 h-5 text-gray-400" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {templates.length === 0 && (
          <div className="text-center py-12">
            <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-medium text-gray-900 mb-2">No templates yet</h3>
            <p className="text-gray-500 mb-4">Create your first template to get started</p>
            <Button>
              <Plus className="w-4 h-4 mr-2" />
              Create Template
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}