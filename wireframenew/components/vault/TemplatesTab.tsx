import { useState } from 'react';
import { FileText, Copy, Edit, Trash2, Search, Plus } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface Template {
  id: string;
  name: string;
  type: 'quote' | 'contract' | 'invoice' | 'form' | 'email';
  description: string;
  lastUsed: string;
  usageCount: number;
  isDefault: boolean;
}

export function TemplatesTab() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState<string>('all');

  const mockTemplates: Template[] = [
    {
      id: '1',
      name: 'Standard Roofing Quote',
      type: 'quote',
      description: 'Complete roofing estimate with materials and labor breakdown',
      lastUsed: '2 days ago',
      usageCount: 45,
      isDefault: true
    },
    {
      id: '2',
      name: 'Residential Service Contract',
      type: 'contract',
      description: 'Standard contract template for residential roofing projects',
      lastUsed: '1 week ago',
      usageCount: 23,
      isDefault: false
    },
    {
      id: '3',
      name: 'Emergency Repair Invoice',
      type: 'invoice',
      description: 'Quick invoice template for emergency repair services',
      lastUsed: '3 days ago',
      usageCount: 18,
      isDefault: false
    },
    {
      id: '4',
      name: 'Insurance Claim Form',
      type: 'form',
      description: 'Standardized form for insurance claim documentation',
      lastUsed: '1 day ago',
      usageCount: 12,
      isDefault: true
    },
    {
      id: '5',
      name: 'Follow-up Email',
      type: 'email',
      description: 'Professional follow-up email for completed projects',
      lastUsed: '5 days ago',
      usageCount: 67,
      isDefault: false
    },
    {
      id: '6',
      name: 'Commercial Quote Template',
      type: 'quote',
      description: 'Detailed quote template for commercial roofing projects',
      lastUsed: '2 weeks ago',
      usageCount: 8,
      isDefault: false
    }
  ];

  const templateTypes = [
    { id: 'all', label: 'All', count: mockTemplates.length },
    { id: 'quote', label: 'Quotes', count: mockTemplates.filter(t => t.type === 'quote').length },
    { id: 'contract', label: 'Contracts', count: mockTemplates.filter(t => t.type === 'contract').length },
    { id: 'invoice', label: 'Invoices', count: mockTemplates.filter(t => t.type === 'invoice').length },
    { id: 'form', label: 'Forms', count: mockTemplates.filter(t => t.type === 'form').length },
    { id: 'email', label: 'Emails', count: mockTemplates.filter(t => t.type === 'email').length }
  ];

  const getTypeColor = (type: Template['type']) => {
    switch (type) {
      case 'quote': return 'bg-green-100 text-green-800';
      case 'contract': return 'bg-blue-100 text-blue-800';
      case 'invoice': return 'bg-purple-100 text-purple-800';
      case 'form': return 'bg-orange-100 text-orange-800';
      case 'email': return 'bg-pink-100 text-pink-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const filteredTemplates = mockTemplates.filter(template => {
    const matchesSearch = template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         template.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = selectedType === 'all' || template.type === selectedType;
    return matchesSearch && matchesType;
  });

  return (
    <div className="flex flex-col h-full">
      {/* Search and Create */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search templates..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <Plus size={16} className="mr-2" />
            Create
          </Button>
        </div>

        {/* Template Type Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {templateTypes.map((type) => (
            <button
              key={type.id}
              onClick={() => setSelectedType(type.id)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedType === type.id
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {type.label} ({type.count})
            </button>
          ))}
        </div>
      </div>

      {/* Templates List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredTemplates.map((template) => (
            <div
              key={template.id}
              className="flex items-start space-x-3 p-4 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              <div className="flex-shrink-0 mt-1">
                <FileText size={20} className="text-muted-foreground" />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center space-x-2 mb-1">
                  <div className="font-medium text-sm truncate">
                    {template.name}
                  </div>
                  {template.isDefault && (
                    <Badge variant="secondary" className="text-xs">
                      Default
                    </Badge>
                  )}
                </div>
                
                <div className="text-xs text-muted-foreground mb-2 line-clamp-2">
                  {template.description}
                </div>
                
                <div className="flex items-center space-x-3">
                  <Badge className={`text-xs px-2 py-0.5 ${getTypeColor(template.type)}`}>
                    {template.type}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    Used {template.usageCount} times
                  </span>
                  <span className="text-xs text-muted-foreground">
                    •
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {template.lastUsed}
                  </span>
                </div>
              </div>
              
              <div className="flex items-center space-x-1">
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Copy size={16} />
                </Button>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Edit size={16} />
                </Button>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-destructive hover:text-destructive">
                  <Trash2 size={16} />
                </Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}