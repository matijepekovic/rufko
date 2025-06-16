import { useState } from 'react';
import { Camera, Upload, FileText, Image, Trash2, CheckSquare, X } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Checkbox } from '../ui/checkbox';
import { KanbanCardData } from '../KanbanCard';

interface MediaTabProps {
  customer: KanbanCardData;
  isSelectionMode: boolean;
  onSelectionModeChange: (mode: boolean) => void;
}

interface MediaItem {
  id: string;
  type: 'photo' | 'document';
  name: string;
  category: string;
  url: string;
  uploadDate: string;
  size: string;
  thumbnail?: string;
}

type MediaFilter = 'all' | 'photos' | 'documents';

export function MediaTab({ customer, isSelectionMode, onSelectionModeChange }: MediaTabProps) {
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [activeFilter, setActiveFilter] = useState<MediaFilter>('all');
  
  const mediaItems: MediaItem[] = [
    {
      id: '1',
      type: 'photo',
      name: 'Roof Damage - Northeast Corner',
      category: 'Damage Assessment',
      url: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=300&h=200&fit=crop',
      uploadDate: '2 days ago',
      size: '2.1 MB',
      thumbnail: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=150&h=100&fit=crop'
    },
    {
      id: '2',
      type: 'photo',
      name: 'Gutter System Overview',
      category: 'Damage Assessment',
      url: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=300&h=200&fit=crop',
      uploadDate: '2 days ago',
      size: '1.8 MB',
      thumbnail: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=150&h=100&fit=crop'
    },
    {
      id: '3',
      type: 'photo',
      name: 'Interior Water Damage',
      category: 'Before Photos',
      url: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=300&h=200&fit=crop',
      uploadDate: '3 days ago',
      size: '1.5 MB',
      thumbnail: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=150&h=100&fit=crop'
    },
    {
      id: '4',
      type: 'document',
      name: 'Insurance Claim Form',
      category: 'Documentation',
      url: '/documents/insurance-claim.pdf',
      uploadDate: '1 week ago',
      size: '892 KB'
    },
    {
      id: '5',
      type: 'document',
      name: 'Material Specifications',
      category: 'Project Documents',
      url: '/documents/material-specs.pdf',
      uploadDate: '1 week ago',
      size: '1.2 MB'
    }
  ];

  const photos = mediaItems.filter(item => item.type === 'photo');
  const documents = mediaItems.filter(item => item.type === 'document');

  // Filter items based on active filter
  const filteredItems = mediaItems.filter(item => {
    switch (activeFilter) {
      case 'photos':
        return item.type === 'photo';
      case 'documents':
        return item.type === 'document';
      case 'all':
      default:
        return true;
    }
  });

  const photosByCategory = photos.reduce((acc, photo) => {
    if (!acc[photo.category]) {
      acc[photo.category] = [];
    }
    acc[photo.category].push(photo);
    return acc;
  }, {} as Record<string, MediaItem[]>);

  const handleItemSelection = (itemId: string) => {
    setSelectedItems(prev =>
      prev.includes(itemId)
        ? prev.filter(id => id !== itemId)
        : [...prev, itemId]
    );
  };

  const handleSelectAll = () => {
    setSelectedItems(filteredItems.map(item => item.id));
  };

  const handleDeselectAll = () => {
    setSelectedItems([]);
  };

  const handleDeleteSelected = () => {
    console.log('Deleting items:', selectedItems);
    setSelectedItems([]);
    onSelectionModeChange(false);
  };

  const handleFilterClick = (filter: MediaFilter) => {
    setActiveFilter(filter);
    setSelectedItems([]); // Clear selection when changing filter
  };

  if (mediaItems.length === 0) {
    return (
      <div className="p-4">
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
            <Image className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No media yet</h3>
          <p className="text-sm text-gray-500 mb-6 max-w-sm">
            Start adding photos and documents to keep track of your project progress.
          </p>
          <div className="flex space-x-2">
            <Button>
              <Camera className="w-4 h-4 mr-2" />
              Take Photo
            </Button>
            <Button variant="outline">
              <Upload className="w-4 h-4 mr-2" />
              Choose File
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Selection Toolbar */}
      {isSelectionMode && (
        <div className="flex items-center justify-between p-4 bg-primary text-primary-foreground">
          <div className="flex items-center space-x-4">
            <span className="text-sm font-medium">
              {selectedItems.length} selected
            </span>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleSelectAll}
              className="text-primary-foreground hover:bg-primary/80"
            >
              Select All
            </Button>
          </div>
          <div className="flex items-center space-x-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={handleDeleteSelected}
              disabled={selectedItems.length === 0}
              className="text-primary-foreground hover:bg-primary/80"
            >
              <Trash2 className="w-4 h-4 mr-1" />
              Delete
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onSelectionModeChange(false)}
              className="text-primary-foreground hover:bg-primary/80"
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        </div>
      )}

      <div className="flex-1 overflow-y-auto p-4">
        {/* Filter Chips */}
        <div className="flex justify-center space-x-2 mb-6">
          <button
            onClick={() => handleFilterClick('all')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all min-h-[44px] flex items-center ${
              activeFilter === 'all'
                ? 'bg-primary text-primary-foreground shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            <span className="mr-2">{mediaItems.length}</span>
            <span>All Files</span>
          </button>
          
          <button
            onClick={() => handleFilterClick('photos')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all min-h-[44px] flex items-center ${
              activeFilter === 'photos'
                ? 'bg-primary text-primary-foreground shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            <Image className="w-4 h-4 mr-2" />
            <span className="mr-2">{photos.length}</span>
            <span>Photos</span>
          </button>
          
          <button
            onClick={() => handleFilterClick('documents')}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all min-h-[44px] flex items-center ${
              activeFilter === 'documents'
                ? 'bg-primary text-primary-foreground shadow-md'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            <FileText className="w-4 h-4 mr-2" />
            <span className="mr-2">{documents.length}</span>
            <span>Documents</span>
          </button>
        </div>

        {/* Content based on active filter */}
        {activeFilter === 'all' || activeFilter === 'photos' ? (
          /* Photos by Category */
          Object.entries(photosByCategory).map(([category, categoryPhotos]) => (
            <div key={category} className="mb-6">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-medium text-gray-900">{category}</h3>
                <Button variant="ghost" size="sm">
                  View All ({categoryPhotos.length})
                </Button>
              </div>
              <div className="grid grid-cols-2 gap-2">
                {categoryPhotos.slice(0, activeFilter === 'photos' ? categoryPhotos.length : 4).map((photo) => (
                  <div key={photo.id} className="relative">
                    <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden">
                      <img
                        src={photo.thumbnail || photo.url}
                        alt={photo.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    {isSelectionMode && (
                      <div className="absolute top-2 right-2">
                        <Checkbox
                          checked={selectedItems.includes(photo.id)}
                          onCheckedChange={() => handleItemSelection(photo.id)}
                          className="bg-white border-2 border-white shadow-md"
                        />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          ))
        ) : null}

        {(activeFilter === 'all' || activeFilter === 'documents') && documents.length > 0 && (
          /* Documents */
          <div className="mb-6">
            <h3 className="font-medium text-gray-900 mb-3">Documents</h3>
            <div className="space-y-2">
              {documents.map((doc) => (
                <Card key={doc.id} className="cursor-pointer hover:shadow-sm transition-shadow">
                  <CardContent className="p-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        {isSelectionMode && (
                          <Checkbox
                            checked={selectedItems.includes(doc.id)}
                            onCheckedChange={() => handleItemSelection(doc.id)}
                          />
                        )}
                        <div className="flex-shrink-0">
                          <FileText className="w-5 h-5 text-red-500" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {doc.name}
                          </p>
                          <p className="text-xs text-gray-500">
                            {doc.uploadDate} • {doc.size}
                          </p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        )}

        {/* Empty state for filtered results */}
        {filteredItems.length === 0 && (
          <div className="flex flex-col items-center justify-center py-12 text-center">
            <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-4">
              {activeFilter === 'photos' ? (
                <Image className="w-6 h-6 text-gray-400" />
              ) : (
                <FileText className="w-6 h-6 text-gray-400" />
              )}
            </div>
            <p className="text-sm text-gray-500">
              No {activeFilter === 'photos' ? 'photos' : activeFilter === 'documents' ? 'documents' : 'items'} found
            </p>
          </div>
        )}
      </div>

      {/* Actions Footer */}
      {!isSelectionMode && (
        <div className="p-4 border-t border-gray-200 bg-background">
          <div className="flex space-x-2">
            <Button className="flex-1">
              <Camera className="w-4 h-4 mr-2" />
              Take Photo
            </Button>
            <Button variant="outline" className="flex-1">
              <Upload className="w-4 h-4 mr-2" />
              Upload
            </Button>
            <Button 
              variant="outline" 
              onClick={() => onSelectionModeChange(true)}
              disabled={filteredItems.length === 0}
            >
              <CheckSquare className="w-4 h-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}