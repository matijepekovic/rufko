import { useState } from 'react';
import { Settings, Bell, Mail, MessageSquare, Calendar, Shield, Database, Smartphone, Globe, Clock } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Switch } from '../ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Separator } from '../ui/separator';
import { Badge } from '../ui/badge';

interface SettingsTabProps {
  searchQuery: string;
}

interface SettingItem {
  id: string;
  category: string;
  name: string;
  description: string;
  type: 'toggle' | 'select' | 'input' | 'time';
  value: any;
  options?: string[];
  icon: any;
}

export function SettingsTab({ searchQuery }: SettingsTabProps) {
  const [settings, setSettings] = useState<SettingItem[]>([
    // Notification Settings
    {
      id: 'email-notifications',
      category: 'Notifications',
      name: 'Email Notifications',
      description: 'Receive email notifications for automation events',
      type: 'toggle',
      value: true,
      icon: Mail
    },
    {
      id: 'sms-notifications',
      category: 'Notifications',
      name: 'SMS Notifications',
      description: 'Receive SMS alerts for critical automation failures',
      type: 'toggle',
      value: false,
      icon: MessageSquare
    },
    {
      id: 'notification-frequency',
      category: 'Notifications',
      name: 'Notification Frequency',
      description: 'How often to receive digest notifications',
      type: 'select',
      value: 'daily',
      options: ['immediate', 'hourly', 'daily', 'weekly'],
      icon: Clock
    },
    {
      id: 'quiet-hours-start',
      category: 'Notifications',
      name: 'Quiet Hours Start',
      description: 'When to stop sending notifications (24-hour format)',
      type: 'time',
      value: '22:00',
      icon: Bell
    },
    {
      id: 'quiet-hours-end',
      category: 'Notifications',
      name: 'Quiet Hours End',
      description: 'When to resume sending notifications (24-hour format)',
      type: 'time',
      value: '08:00',
      icon: Bell
    },

    // Communication Settings
    {
      id: 'default-email-sender',
      category: 'Communication',
      name: 'Default Email Sender',
      description: 'Default "from" address for automated emails',
      type: 'input',
      value: 'noreply@company.com',
      icon: Mail
    },
    {
      id: 'email-signature',
      category: 'Communication',
      name: 'Email Signature',
      description: 'Default signature for automated emails',
      type: 'input',
      value: 'Best regards,\nYour Roofing Team',
      icon: Mail
    },
    {
      id: 'sms-sender-id',
      category: 'Communication',
      name: 'SMS Sender ID',
      description: 'Custom sender ID for SMS messages',
      type: 'input',
      value: 'ROOFING',
      icon: MessageSquare
    },
    {
      id: 'business-hours-start',
      category: 'Communication',
      name: 'Business Hours Start',
      description: 'When business hours begin for scheduling',
      type: 'time',
      value: '08:00',
      icon: Clock
    },
    {
      id: 'business-hours-end',
      category: 'Communication',
      name: 'Business Hours End',
      description: 'When business hours end for scheduling',
      type: 'time',
      value: '17:00',
      icon: Clock
    },

    // Security Settings
    {
      id: 'require-approval',
      category: 'Security',
      name: 'Require Approval',
      description: 'Require manual approval for high-value automations',
      type: 'toggle',
      value: true,
      icon: Shield
    },
    {
      id: 'approval-threshold',
      category: 'Security',
      name: 'Approval Threshold',
      description: 'Dollar amount requiring approval (leave empty for all)',
      type: 'input',
      value: '5000',
      icon: Shield
    },
    {
      id: 'data-retention',
      category: 'Security',
      name: 'Data Retention Period',
      description: 'How long to keep automation logs and data',
      type: 'select',
      value: '1-year',
      options: ['30-days', '90-days', '6-months', '1-year', '2-years', 'indefinite'],
      icon: Database
    },
    {
      id: 'encryption-enabled',
      category: 'Security',
      name: 'Data Encryption',
      description: 'Encrypt sensitive customer data in automation workflows',
      type: 'toggle',
      value: true,
      icon: Shield
    },

    // Integration Settings
    {
      id: 'calendar-sync',
      category: 'Integrations',
      name: 'Calendar Sync',
      description: 'Sync appointments with external calendar systems',
      type: 'toggle',
      value: true,
      icon: Calendar
    },
    {
      id: 'crm-integration',
      category: 'Integrations',
      name: 'CRM Integration',
      description: 'Automatically update CRM records from automations',
      type: 'toggle',
      value: false,
      icon: Database
    },
    {
      id: 'mobile-app-sync',
      category: 'Integrations',
      name: 'Mobile App Sync',
      description: 'Sync automation data with mobile applications',
      type: 'toggle',
      value: true,
      icon: Smartphone
    },
    {
      id: 'webhook-url',
      category: 'Integrations',
      name: 'Webhook URL',
      description: 'External webhook for automation events',
      type: 'input',
      value: '',
      icon: Globe
    }
  ]);

  const filteredSettings = settings.filter(setting =>
    setting.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    setting.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
    setting.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const categories = [...new Set(settings.map(s => s.category))];
  const filteredCategories = categories.filter(category =>
    filteredSettings.some(setting => setting.category === category)
  );

  const updateSetting = (id: string, newValue: any) => {
    setSettings(prev =>
      prev.map(setting =>
        setting.id === id ? { ...setting, value: newValue } : setting
      )
    );
  };

  const renderSettingControl = (setting: SettingItem) => {
    switch (setting.type) {
      case 'toggle':
        return (
          <Switch
            checked={setting.value}
            onCheckedChange={(checked) => updateSetting(setting.id, checked)}
          />
        );
      
      case 'select':
        return (
          <Select value={setting.value} onValueChange={(value) => updateSetting(setting.id, value)}>
            <SelectTrigger className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {setting.options?.map((option) => (
                <SelectItem key={option} value={option}>
                  {option.replace('-', ' ').split(' ').map(word => 
                    word.charAt(0).toUpperCase() + word.slice(1)
                  ).join(' ')}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        );
      
      case 'input':
        return (
          <Input
            value={setting.value}
            onChange={(e) => updateSetting(setting.id, e.target.value)}
            placeholder={`Enter ${setting.name.toLowerCase()}`}
          />
        );
      
      case 'time':
        return (
          <input
            type="time"
            value={setting.value}
            onChange={(e) => updateSetting(setting.id, e.target.value)}
            className="w-full p-2 border border-gray-200 rounded-lg bg-white focus:border-primary focus:ring-1 focus:ring-primary outline-none"
          />
        );
      
      default:
        return null;
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'Notifications':
        return <Bell className="w-5 h-5" />;
      case 'Communication':
        return <MessageSquare className="w-5 h-5" />;
      case 'Security':
        return <Shield className="w-5 h-5" />;
      case 'Integrations':
        return <Globe className="w-5 h-5" />;
      default:
        return <Settings className="w-5 h-5" />;
    }
  };

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'Notifications':
        return 'bg-blue-100 text-blue-700';
      case 'Communication':
        return 'bg-green-100 text-green-700';
      case 'Security':
        return 'bg-red-100 text-red-700';
      case 'Integrations':
        return 'bg-purple-100 text-purple-700';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  return (
    <div className="h-full overflow-auto">
      <div className="p-4 space-y-4">
        {/* Quick Overview */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Settings className="w-5 h-5 text-primary" />
              <span>Configuration Overview</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div className="text-center">
                <p className="text-2xl font-semibold text-primary">{settings.filter(s => s.type === 'toggle' && s.value).length}</p>
                <p className="text-sm text-gray-600">Features Enabled</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-semibold text-primary">{categories.length}</p>
                <p className="text-sm text-gray-600">Setting Categories</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Settings by Category */}
        {filteredCategories.map((category) => (
          <Card key={category}>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <div className={`p-2 rounded-lg ${getCategoryColor(category)}`}>
                  {getCategoryIcon(category)}
                </div>
                <span>{category}</span>
                <Badge variant="outline" className="ml-auto">
                  {filteredSettings.filter(s => s.category === category).length}
                </Badge>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              {filteredSettings
                .filter(setting => setting.category === category)
                .map((setting, index, arr) => {
                  const IconComponent = setting.icon;
                  return (
                    <div key={setting.id}>
                      <div className="flex items-start justify-between space-x-4">
                        <div className="flex items-start space-x-3 flex-1">
                          <div className="p-1 rounded-lg bg-gray-100 mt-1">
                            <IconComponent className="w-4 h-4 text-gray-600" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <Label className="text-sm font-medium">{setting.name}</Label>
                            <p className="text-xs text-gray-600 mt-1">{setting.description}</p>
                          </div>
                        </div>
                        <div className="flex-shrink-0 w-32">
                          {renderSettingControl(setting)}
                        </div>
                      </div>
                      {index < arr.length - 1 && <Separator className="mt-4" />}
                    </div>
                  );
                })}
            </CardContent>
          </Card>
        ))}

        {filteredSettings.length === 0 && (
          <div className="text-center py-12">
            <Settings className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-medium text-gray-900 mb-2">No settings found</h3>
            <p className="text-gray-500 mb-4">
              {searchQuery ? 'Try adjusting your search terms' : 'All settings are configured'}
            </p>
          </div>
        )}

        {/* Save Actions */}
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium">Settings Changes</p>
                <p className="text-sm text-gray-600">Save your configuration changes</p>
              </div>
              <div className="flex space-x-2">
                <Button variant="outline" size="sm">
                  Reset to Defaults
                </Button>
                <Button size="sm">
                  Save Changes
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}