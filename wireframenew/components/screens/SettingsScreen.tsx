import { Settings, ArrowRight } from 'lucide-react';
import { Card, CardContent } from '../ui/card';
import { Switch } from '../ui/switch';

export function SettingsScreen() {
  const settingsGroups = [
    {
      title: 'Notifications',
      settings: [
        { name: 'Email notifications', description: 'Receive email alerts', enabled: true },
        { name: 'SMS notifications', description: 'Receive SMS alerts', enabled: false },
        { name: 'Push notifications', description: 'Mobile app notifications', enabled: true }
      ]
    },
    {
      title: 'Automation',
      settings: [
        { name: 'Auto follow-up', description: 'Automatically follow up with leads', enabled: true },
        { name: 'Smart scheduling', description: 'Auto-schedule appointments', enabled: false },
        { name: 'Report generation', description: 'Generate weekly reports', enabled: true }
      ]
    },
    {
      title: 'Account',
      settings: [
        { name: 'Data backup', description: 'Backup data to cloud', enabled: true },
        { name: 'Sync across devices', description: 'Keep data in sync', enabled: true }
      ]
    }
  ];

  return (
    <div className="h-full flex flex-col bg-background">
      {/* Header */}
      <div className="border-b border-gray-200 bg-background">
        <div className="flex items-center justify-between p-4 pb-2">
          <div className="flex items-center space-x-3">
            <div className="p-2 rounded-lg bg-primary/10">
              <Settings className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h1 className="font-medium text-lg">Settings</h1>
              <p className="text-sm text-gray-500">App preferences</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-4">
        <div className="space-y-6">
          {settingsGroups.map((group, groupIndex) => (
            <div key={groupIndex}>
              <h2 className="font-medium text-gray-900 mb-3">{group.title}</h2>
              <Card>
                <CardContent className="p-0">
                  {group.settings.map((setting, index) => (
                    <div key={index} className={`p-4 ${index < group.settings.length - 1 ? 'border-b border-gray-100' : ''}`}>
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <h3 className="font-medium text-sm">{setting.name}</h3>
                          <p className="text-xs text-gray-500 mt-1">{setting.description}</p>
                        </div>
                        <Switch checked={setting.enabled} />
                      </div>
                    </div>
                  ))}
                </CardContent>
              </Card>
            </div>
          ))}

          {/* Additional Settings */}
          <div>
            <h2 className="font-medium text-gray-900 mb-3">More</h2>
            <Card>
              <CardContent className="p-0">
                {[
                  { name: 'About', description: 'App version and info' },
                  { name: 'Privacy Policy', description: 'View privacy policy' },
                  { name: 'Terms of Service', description: 'View terms of service' },
                  { name: 'Help & Support', description: 'Get help and support' }
                ].map((item, index) => (
                  <div key={index} className={`p-4 cursor-pointer hover:bg-gray-50 ${index < 3 ? 'border-b border-gray-100' : ''}`}>
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <h3 className="font-medium text-sm">{item.name}</h3>
                        <p className="text-xs text-gray-500 mt-1">{item.description}</p>
                      </div>
                      <ArrowRight className="w-4 h-4 text-gray-400" />
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}