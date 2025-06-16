import { useState } from 'react';
import { FileText, Upload, Plus, GripVertical, Eye, Download } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { KanbanCardData } from '../KanbanCard';

interface InspectionTabProps {
  customer: KanbanCardData;
}

interface InspectionField {
  id: string;
  label: string;
  type: 'text' | 'textarea' | 'select' | 'checkbox';
  value: string;
  options?: string[];
  required: boolean;
}

interface InspectionDocument {
  id: string;
  name: string;
  type: 'pdf' | 'image' | 'note';
  uploadDate: string;
  size?: string;
}

export function InspectionTab({ customer }: InspectionTabProps) {
  const [newNote, setNewNote] = useState('');

  const [inspectionFields] = useState<InspectionField[]>([
    {
      id: '1',
      label: 'Roof Condition',
      type: 'select',
      value: 'Fair',
      options: ['Excellent', 'Good', 'Fair', 'Poor', 'Critical'],
      required: true
    },
    {
      id: '2',
      label: 'Gutter System',
      type: 'select',
      value: 'Needs Replacement',
      options: ['Excellent', 'Good', 'Needs Repair', 'Needs Replacement'],
      required: true
    },
    {
      id: '3',
      label: 'Safety Concerns',
      type: 'textarea',
      value: 'Loose shingles on northeast corner. Recommend immediate attention.',
      required: false
    },
    {
      id: '4',
      label: 'Access Issues',
      type: 'checkbox',
      value: 'true',
      required: false
    },
    {
      id: '5',
      label: 'Additional Notes',
      type: 'textarea',
      value: 'Customer has two large dogs in backyard. Schedule accordingly.',
      required: false
    }
  ]);

  const [inspectionDocs] = useState<InspectionDocument[]>([
    {
      id: '1',
      name: 'Roof Inspection Photos',
      type: 'image',
      uploadDate: '2 days ago',
      size: '15 photos'
    },
    {
      id: '2',
      name: 'Damage Assessment Report',
      type: 'pdf',
      uploadDate: '2 days ago',
      size: '2.1 MB'
    },
    {
      id: '3',
      name: 'Insurance Documentation',
      type: 'pdf',
      uploadDate: '1 week ago',
      size: '1.8 MB'
    }
  ]);

  const renderField = (field: InspectionField) => {
    switch (field.type) {
      case 'text':
        return (
          <Input
            value={field.value}
            onChange={(e) => console.log('Update field:', field.id, e.target.value)}
            required={field.required}
          />
        );
      case 'textarea':
        return (
          <Textarea
            value={field.value}
            onChange={(e) => console.log('Update field:', field.id, e.target.value)}
            required={field.required}
            className="min-h-[80px]"
          />
        );
      case 'select':
        return (
          <select
            value={field.value}
            onChange={(e) => console.log('Update field:', field.id, e.target.value)}
            required={field.required}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
          >
            {field.options?.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        );
      case 'checkbox':
        return (
          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={field.value === 'true'}
              onChange={(e) => console.log('Update field:', field.id, e.target.checked)}
              className="w-4 h-4 text-primary border-gray-300 rounded focus:ring-primary"
            />
            <span className="text-sm text-gray-700">Yes</span>
          </div>
        );
      default:
        return null;
    }
  };

  const getDocumentIcon = (type: string) => {
    switch (type) {
      case 'pdf': return <FileText className="w-5 h-5 text-red-500" />;
      case 'image': return <Upload className="w-5 h-5 text-blue-500" />;
      case 'note': return <FileText className="w-5 h-5 text-gray-500" />;
      default: return <FileText className="w-5 h-5 text-gray-500" />;
    }
  };

  const handleAddNote = () => {
    if (newNote.trim()) {
      console.log('Adding inspection note:', newNote);
      setNewNote('');
    }
  };

  const handleUploadDocument = () => {
    console.log('Upload document clicked');
  };

  if (inspectionFields.length === 0) {
    return (
      <div className="p-4">
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
            <FileText className="w-8 h-8 text-gray-400" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No inspection fields</h3>
          <p className="text-sm text-gray-500 mb-4 max-w-sm">
            Create custom inspection fields to standardize your inspection process.
          </p>
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Create Inspection Fields
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-6">
      {/* Inspection Fields */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Inspection Details</CardTitle>
        </CardHeader>
        <CardContent className="pt-0">
          <div className="space-y-4">
            {inspectionFields.map((field) => (
              <div key={field.id} className="flex items-start space-x-3">
                <div className="flex-shrink-0 mt-2">
                  <GripVertical className="w-4 h-4 text-gray-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {field.label}
                    {field.required && <span className="text-red-500 ml-1">*</span>}
                  </label>
                  {renderField(field)}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Add Note Section */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Add Inspection Note</CardTitle>
        </CardHeader>
        <CardContent className="pt-0">
          <Textarea
            placeholder="Add inspection notes or observations..."
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            className="mb-3"
          />
          <Button 
            onClick={handleAddNote}
            disabled={!newNote.trim()}
            className="w-full"
          >
            <Plus className="w-4 h-4 mr-2" />
            Add Note
          </Button>
        </CardContent>
      </Card>

      {/* Inspection Documents */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Inspection Documents</CardTitle>
            <Button 
              variant="outline" 
              size="sm"
              onClick={handleUploadDocument}
            >
              <Upload className="w-4 h-4 mr-2" />
              Upload
            </Button>
          </div>
        </CardHeader>
        <CardContent className="pt-0">
          {/* Document List */}
          <div className="space-y-2">
            {inspectionDocs.map((doc) => (
              <div key={doc.id} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg">
                <div className="flex items-center space-x-3">
                  {getDocumentIcon(doc.type)}
                  <div>
                    <p className="text-sm font-medium text-gray-900">{doc.name}</p>
                    <p className="text-xs text-gray-500">
                      {doc.uploadDate} • {doc.size}
                    </p>
                  </div>
                </div>
                <div className="flex items-center space-x-1">
                  <Button variant="ghost" size="sm">
                    <Eye className="w-4 h-4" />
                  </Button>
                  <Button variant="ghost" size="sm">
                    <Download className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}