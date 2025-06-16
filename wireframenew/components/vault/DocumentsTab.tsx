import { useState } from 'react';
import { FileText, Download, Eye, Trash2, Upload, Search } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Avatar } from '../ui/avatar';

interface Document {
  id: string;
  name: string;
  type: 'contract' | 'invoice' | 'quote' | 'form' | 'other';
  size: string;
  dateModified: string;
  owner: string;
  isShared: boolean;
}

export function DocumentsTab() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState<string>('all');

  const mockDocuments: Document[] = [
    {
      id: '1',
      name: 'Wilson Building Contract.pdf',
      type: 'contract',
      size: '2.4 MB',
      dateModified: '2 hours ago',
      owner: 'You',
      isShared: true
    },
    {
      id: '2',
      name: 'Thompson Residence Quote.pdf',
      type: 'quote',
      size: '1.2 MB',
      dateModified: '1 day ago',
      owner: 'You',
      isShared: false
    },
    {
      id: '3',
      name: 'Insurance Claim Form - Garcia.pdf',
      type: 'form',
      size: '856 KB',
      dateModified: '3 days ago',
      owner: 'Sarah Johnson',
      isShared: true
    },
    {
      id: '4',
      name: 'Invoice #1247 - Miller House.pdf',
      type: 'invoice',
      size: '945 KB',
      dateModified: '1 week ago',
      owner: 'You',
      isShared: false
    },
    {
      id: '5',
      name: 'Permit Application - Davis Home.pdf',
      type: 'form',
      size: '1.8 MB',
      dateModified: '2 weeks ago',
      owner: 'Mike Chen',
      isShared: true
    }
  ];

  const documentTypes = [
    { id: 'all', label: 'All', count: mockDocuments.length },
    { id: 'contract', label: 'Contracts', count: mockDocuments.filter(d => d.type === 'contract').length },
    { id: 'quote', label: 'Quotes', count: mockDocuments.filter(d => d.type === 'quote').length },
    { id: 'invoice', label: 'Invoices', count: mockDocuments.filter(d => d.type === 'invoice').length },
    { id: 'form', label: 'Forms', count: mockDocuments.filter(d => d.type === 'form').length }
  ];

  const getTypeColor = (type: Document['type']) => {
    switch (type) {
      case 'contract': return 'bg-blue-100 text-blue-800';
      case 'quote': return 'bg-green-100 text-green-800';
      case 'invoice': return 'bg-purple-100 text-purple-800';
      case 'form': return 'bg-orange-100 text-orange-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getTypeIcon = (type: Document['type']) => {
    return <FileText size={20} className="text-muted-foreground" />;
  };

  const filteredDocuments = mockDocuments.filter(doc => {
    const matchesSearch = doc.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = selectedType === 'all' || doc.type === selectedType;
    return matchesSearch && matchesType;
  });

  return (
    <div className="flex flex-col h-full">
      {/* Search and Upload */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <Upload size={16} className="mr-2" />
            Upload
          </Button>
        </div>

        {/* Document Type Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {documentTypes.map((type) => (
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

      {/* Documents List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredDocuments.map((doc) => (
            <div
              key={doc.id}
              className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              <div className="flex-shrink-0">
                {getTypeIcon(doc.type)}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="font-medium text-sm truncate">
                  {doc.name}
                </div>
                <div className="flex items-center space-x-2 mt-1">
                  <Badge className={`text-xs px-2 py-0.5 ${getTypeColor(doc.type)}`}>
                    {doc.type}
                  </Badge>
                  <span className="text-xs text-muted-foreground">
                    {doc.size}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    •
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {doc.dateModified}
                  </span>
                </div>
                <div className="flex items-center space-x-2 mt-1">
                  <span className="text-xs text-muted-foreground">
                    {doc.owner}
                  </span>
                  {doc.isShared && (
                    <Badge variant="secondary" className="text-xs">
                      Shared
                    </Badge>
                  )}
                </div>
              </div>
              
              <div className="flex items-center space-x-1">
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Eye size={16} />
                </Button>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Download size={16} />
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