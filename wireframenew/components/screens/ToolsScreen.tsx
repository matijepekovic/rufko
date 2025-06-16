import { useState } from 'react';
import { Calculator, FileText, Calendar, Settings, Zap, Camera, MapPin, Users, BarChart3, Search, MessageSquare, Bell, Shield, Cloud, Smartphone, ChevronRight } from 'lucide-react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Card, CardContent } from '../ui/card';
import { Switch } from '../ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';

export function ToolsScreen() {
  const [searchQuery, setSearchQuery] = useState('');
  const [settings, setSettings] = useState({
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    autoFollowUp: true,
    smartScheduling: false,
    reportGeneration: true,
    dataBackup: true,
    syncAcrossDevices: true,
  });

  const tools = [
    {
      id: 'calculator',
      name: 'Calculator',
      description: 'Calculate materials and costs',
      icon: Calculator,
      color: 'bg-green-100 text-green-600',
      category: 'Tools'
    },
    {
      id: 'scheduler',
      name: 'Scheduler',
      description: 'Manage appointments',
      icon: Calendar,
      color: 'bg-orange-100 text-orange-600',
      category: 'Planning'
    },
    {
      id: 'automation',
      name: 'Automation',
      description: 'Workflow automation',
      icon: Zap,
      color: 'bg-purple-100 text-purple-600',
      category: 'Productivity'
    },
    {
      id: 'templates',
      name: 'Templates',
      description: 'Message templates',
      icon: MessageSquare,
      color: 'bg-blue-100 text-blue-600',
      category: 'Communication'
    },
    {
      id: 'camera',
      name: 'Camera',
      description: 'Capture photos',
      icon: Camera,
      color: 'bg-pink-100 text-pink-600',
      category: 'Tools'
    },
    {
      id: 'maps',
      name: 'Maps',
      description: 'Navigate to locations',
      icon: MapPin,
      color: 'bg-blue-100 text-blue-600',
      category: 'Navigation'
    },
    {
      id: 'contacts',
      name: 'Contacts',
      description: 'Manage customer contacts',
      icon: Users,
      color: 'bg-purple-100 text-purple-600',
      category: 'CRM'
    },
    {
      id: 'reports',
      name: 'Reports',
      description: 'Generate business reports',
      icon: BarChart3,
      color: 'bg-indigo-100 text-indigo-600',
      category: 'Analytics'
    }
  ];

  const settingsGroups = [
    {
      title: 'Notifications',
      icon: Bell,
      settings: [
        { 
          key: 'emailNotifications',
          name: 'Email notifications', 
          description: 'Receive email alerts for important events',
        },
        { 
          key: 'smsNotifications',
          name: 'SMS notifications', 
          description: 'Get text messages for urgent updates',
        },
        { 
          key: 'pushNotifications',
          name: 'Push notifications', 
          description: 'Mobile app notifications and alerts',
        }
      ]
    },
    {
      title: 'Automation',
      icon: Zap,
      settings: [
        { 
          key: 'autoFollowUp',
          name: 'Auto follow-up', 
          description: 'Automatically follow up with leads after set time',
        },
        { 
          key: 'smartScheduling',
          name: 'Smart scheduling', 
          description: 'Auto-schedule appointments based on availability',
        },
        { 
          key: 'reportGeneration',
          name: 'Weekly reports', 
          description: 'Generate and send weekly performance reports',
        }
      ]
    },
    {
      title: 'Account & Data',
      icon: Cloud,
      settings: [
        { 
          key: 'dataBackup',
          name: 'Cloud backup', 
          description: 'Automatically backup your data to the cloud',
        },
        { 
          key: 'syncAcrossDevices',
          name: 'Device sync', 
          description: 'Keep your data synchronized across all devices',
        }
      ]
    }
  ];

  const handleSettingToggle = (key: string) => {
    setSettings(prev => ({
      ...prev,
      [key]: !prev[key as keyof typeof prev]
    }));
  };

  const filteredTools = tools.filter(tool =>
    tool.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    tool.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
    tool.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const otherSettings = [
    { name: 'Account & Profile', description: 'Manage your account settings', icon: Users },
    { name: 'Privacy & Security', description: 'Control your privacy settings', icon: Shield },
    { name: 'Data & Storage', description: 'Manage app data and storage', icon: Smartphone },
    { name: 'About', description: 'App version and information', icon: Settings },
  ];

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="flex-shrink-0 bg-surface border-b border-stroke navbar-safe py-3">
        <div className="flex items-center space-x-2">
          <Settings className="w-5 h-5 text-primary" />
          <h1 className="text-gray-900">Tools</h1>
        </div>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="tools" className="flex-1 flex flex-col">
        <div className="flex-shrink-0 bg-surface border-b border-stroke">
          <TabsList className="grid w-full grid-cols-2 bg-transparent p-0 h-auto">
            <TabsTrigger 
              value="tools" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Tools
            </TabsTrigger>
            <TabsTrigger 
              value="settings" 
              className="relative py-3 px-4 data-[state=active]:bg-transparent data-[state=active]:shadow-none data-[state=active]:after:absolute data-[state=active]:after:bottom-0 data-[state=active]:after:left-0 data-[state=active]:after:right-0 data-[state=active]:after:h-0.5 data-[state=active]:after:bg-primary data-[state=active]:text-primary"
            >
              Settings
            </TabsTrigger>
          </TabsList>
        </div>

        {/* Tools Tab */}
        <TabsContent value="tools" className="flex-1 overflow-auto p-4 m-0">
          {/* Search */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search tools..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 bg-background border-stroke"
            />
          </div>

          {/* Tools Grid */}
          <div className="grid grid-cols-2 gap-3">
            {filteredTools.map((tool) => {
              const IconComponent = tool.icon;
              return (
                <Card 
                  key={tool.id}
                  className="cursor-pointer hover:shadow-md transition-shadow border border-stroke"
                >
                  <CardContent className="p-4">
                    <div className="text-center space-y-3">
                      <div className={`p-3 rounded-xl ${tool.color} mx-auto w-fit`}>
                        <IconComponent className="w-6 h-6" />
                      </div>
                      <div>
                        <h3 className="font-medium text-sm">{tool.name}</h3>
                        <p className="text-xs text-muted-foreground mt-1">{tool.description}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {filteredTools.length === 0 && (
            <div className="text-center py-12">
              <Settings className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="font-medium text-gray-900 mb-2">No tools found</h3>
              <p className="text-gray-500 mb-4">
                Try adjusting your search terms
              </p>
            </div>
          )}
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="flex-1 overflow-auto m-0">
          <div className="p-4 space-y-6">
            {/* Settings Groups */}
            {settingsGroups.map((group, groupIndex) => (
              <div key={groupIndex} className="space-y-3">
                <div className="flex items-center space-x-2 mb-3">
                  <group.icon className="w-5 h-5 text-primary" />
                  <h2 className="font-medium text-gray-900">{group.title}</h2>
                </div>
                
                <div className="space-y-2">
                  {group.settings.map((setting) => (
                    <div 
                      key={setting.key} 
                      className="flex items-center justify-between p-4 bg-surface rounded-xl border border-stroke hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex-1 pr-4">
                        <div className="flex items-center space-x-3">
                          <div>
                            <p className="font-medium text-sm text-gray-900">{setting.name}</p>
                            <p className="text-xs text-gray-500 mt-1">{setting.description}</p>
                          </div>
                        </div>
                      </div>
                      <Switch 
                        checked={settings[setting.key as keyof typeof settings]}
                        onCheckedChange={() => handleSettingToggle(setting.key)}
                      />
                    </div>
                  ))}
                </div>
              </div>
            ))}

            {/* Other Settings */}
            <div className="space-y-3">
              <div className="flex items-center space-x-2 mb-3">
                <Settings className="w-5 h-5 text-primary" />
                <h2 className="font-medium text-gray-900">More</h2>
              </div>
              
              <div className="space-y-2">
                {otherSettings.map((item, index) => (
                  <div 
                    key={index} 
                    className="flex items-center justify-between p-4 bg-surface rounded-xl border border-stroke hover:bg-gray-50 transition-colors cursor-pointer"
                  >
                    <div className="flex items-center space-x-3">
                      <div className="p-2 bg-gray-100 rounded-lg">
                        <item.icon className="w-4 h-4 text-gray-600" />
                      </div>
                      <div>
                        <p className="font-medium text-sm text-gray-900">{item.name}</p>
                        <p className="text-xs text-gray-500 mt-1">{item.description}</p>
                      </div>
                    </div>
                    <ChevronRight className="w-4 h-4 text-gray-400" />
                  </div>
                ))}
              </div>
            </div>

            {/* App Info */}
            <div className="pt-4 border-t border-stroke">
              <div className="text-center text-xs text-gray-500">
                <p>RoofCRM Pro v2.1.0</p>
                <p className="mt-1">© 2024 RoofCRM. All rights reserved.</p>
              </div>
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}