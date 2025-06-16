import { useState } from 'react';
import { Image, Video, Camera, Upload, Search, Download, Trash2, Eye } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface MediaItem {
  id: string;
  name: string;
  type: 'image' | 'video';
  size: string;
  dateCreated: string;
  jobId?: string;
  jobName?: string;
  thumbnail?: string;
}

export function MediaTab() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  const mockMedia: MediaItem[] = [
    {
      id: '1',
      name: 'Before_Wilson_Building_001.jpg',
      type: 'image',
      size: '2.4 MB',
      dateCreated: '2 hours ago',
      jobId: 'job-001',
      jobName: 'Wilson Building Roof'
    },
    {
      id: '2',
      name: 'Damage_Assessment_Thompson.mp4',
      type: 'video',
      size: '15.2 MB',
      dateCreated: '1 day ago',
      jobId: 'job-002',
      jobName: 'Thompson Residence'
    },
    {
      id: '3',
      name: 'After_Garcia_Estate_Final.jpg',
      type: 'image',
      size: '1.8 MB',
      dateCreated: '3 days ago',
      jobId: 'job-003',
      jobName: 'Garcia Estate'
    },
    {
      id: '4',
      name: 'Progress_Miller_House_Day3.jpg',
      type: 'image',
      size: '2.1 MB',
      dateCreated: '1 week ago',
      jobId: 'job-004',
      jobName: 'Miller House'
    },
    {
      id: '5',
      name: 'Storm_Damage_Davis_Home.mp4',
      type: 'video',
      size: '8.7 MB',
      dateCreated: '2 weeks ago',
      jobId: 'job-005',
      jobName: 'Davis Home'
    },
    {
      id: '6',
      name: 'Material_Delivery_Johnson.jpg',
      type: 'image',
      size: '1.5 MB',
      dateCreated: '3 weeks ago',
      jobId: 'job-006',
      jobName: 'Johnson Property'
    }
  ];

  const mediaTypes = [
    { id: 'all', label: 'All', count: mockMedia.length },
    { id: 'image', label: 'Photos', count: mockMedia.filter(m => m.type === 'image').length },
    { id: 'video', label: 'Videos', count: mockMedia.filter(m => m.type === 'video').length }
  ];

  const filteredMedia = mockMedia.filter(media => {
    const matchesSearch = media.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         media.jobName?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = selectedType === 'all' || media.type === selectedType;
    return matchesSearch && matchesType;
  });

  const renderGridView = () => (
    <div className="grid grid-cols-2 gap-3 p-4">
      {filteredMedia.map((media) => (
        <div
          key={media.id}
          className="bg-card rounded-lg border border-stroke overflow-hidden hover:bg-accent/50 transition-colors"
        >
          {/* Thumbnail */}
          <div className="aspect-video bg-gray-100 flex items-center justify-center relative">
            {media.type === 'image' ? (
              <Image size={32} className="text-muted-foreground" />
            ) : (
              <Video size={32} className="text-muted-foreground" />
            )}
            <div className="absolute top-2 right-2">
              <Badge variant="secondary" className="text-xs">
                {media.type}
              </Badge>
            </div>
          </div>
          
          {/* Content */}
          <div className="p-3">
            <div className="font-medium text-sm truncate mb-1">
              {media.name}
            </div>
            <div className="text-xs text-muted-foreground truncate mb-2">
              {media.jobName}
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>{media.size}</span>
              <span>{media.dateCreated}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  const renderListView = () => (
    <div className="p-4 space-y-3">
      {filteredMedia.map((media) => (
        <div
          key={media.id}
          className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
        >
          <div className="flex-shrink-0 w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
            {media.type === 'image' ? (
              <Image size={20} className="text-muted-foreground" />
            ) : (
              <Video size={20} className="text-muted-foreground" />
            )}
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="font-medium text-sm truncate">
              {media.name}
            </div>
            <div className="text-xs text-muted-foreground truncate">
              {media.jobName}
            </div>
            <div className="flex items-center space-x-2 mt-1">
              <Badge variant="secondary" className="text-xs">
                {media.type}
              </Badge>
              <span className="text-xs text-muted-foreground">
                {media.size}
              </span>
              <span className="text-xs text-muted-foreground">
                •
              </span>
              <span className="text-xs text-muted-foreground">
                {media.dateCreated}
              </span>
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
  );

  return (
    <div className="flex flex-col h-full">
      {/* Search and Actions */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search photos & videos..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <Camera size={16} className="mr-2" />
            Capture
          </Button>
          <Button size="sm" variant="outline" className="px-3">
            <Upload size={16} />
          </Button>
        </div>

        {/* Media Type Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {mediaTypes.map((type) => (
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

      {/* Content */}
      <div className="flex-1 overflow-y-auto scrollable">
        {viewMode === 'grid' ? renderGridView() : renderListView()}
      </div>
    </div>
  );
}