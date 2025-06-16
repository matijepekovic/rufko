import { useState } from 'react';
import { FileText, Copy, Edit, Trash2, Star, Calendar, MessageSquare, Mail, Phone, Clock } from 'lucide-react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Label } from '../ui/label';
import { Input } from '../ui/input';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';

interface TemplatesTabProps {
  searchQuery: string;
}

interface Template {
  id: string;
  name: string;
  description: string;
  type: 'email' | 'sms' | 'call' | 'appointment';
  category: 'follow-up' | 'initial' | 'reminder' | 'proposal';
  content: string;
  isFavorite: boolean;
  usageCount: number;
  lastUsed: Date;
  createdAt: Date;
}

export function TemplatesTab({ searchQuery }: TemplatesTabProps) {
  const [selectedTemplate, setSelectedTemplate] = useState<Template | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  // Mock templates data
  const templates: Template[] = [
    {
      id: '1',
      name: 'Initial Consultation Follow-up',
      description: 'Send after first meeting with potential customer',
      type: 'email',
      category: 'follow-up',
      content: 'Hi {customerName}, thank you for taking the time to meet with us today. We\'re excited about the opportunity to work on your {projectType} project...',
      isFavorite: true,
      usageCount: 47,
      lastUsed: new Date('2024-06-14'),
      createdAt: new Date('2024-05-01')
    },
    {
      id: '2',
      name: 'Estimate Ready SMS',
      description: 'Quick notification when estimate is complete',
      type: 'sms',
      category: 'reminder',
      content: 'Hi {customerName}! Your roofing estimate is ready. Please check your email or call us at (555) 123-4567 to discuss. Thanks!',
      isFavorite: false,
      usageCount: 23,
      lastUsed: new Date('2024-06-13'),
      createdAt: new Date('2024-05-15')
    },
    {
      id: '3',
      name: 'Appointment Confirmation',
      description: 'Confirm upcoming inspection appointments',
      type: 'email',
      category: 'appointment',
      content: 'This is to confirm your roof inspection appointment on {appointmentDate} at {appointmentTime}. Our team will arrive within the scheduled window...',
      isFavorite: true,
      usageCount: 89,
      lastUsed: new Date('2024-06-15'),
      createdAt: new Date('2024-04-20')
    },
    {
      id: '4',
      name: 'Proposal Presentation',
      description: 'Schedule proposal review meeting',
      type: 'call',
      category: 'proposal',
      content: 'Call script for scheduling proposal presentations and answering initial questions about the estimate.',
      isFavorite: false,
      usageCount: 15,
      lastUsed: new Date('2024-06-10'),
      createdAt: new Date('2024-06-01')
    }
  ];

  const filteredTemplates = templates.filter(template =>
    template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    template.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
    template.type.toLowerCase().includes(searchQuery.toLowerCase()) ||
    template.category.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'email':
        return <Mail className="w-4 h-4" />;
      case 'sms':
        return <MessageSquare className="w-4 h-4" />;
      case 'call':
        return <Phone className="w-4 h-4" />;
      case 'appointment':
        return <Calendar className="w-4 h-4" />;
      default:
        return <FileText className="w-4 h-4" />;
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'email':
        return 'bg-blue-100 text-blue-700 border-blue-200';
      case 'sms':
        return 'bg-green-100 text-green-700 border-green-200';
      case 'call':
        return 'bg-purple-100 text-purple-700 border-purple-200';
      case 'appointment':
        return 'bg-orange-100 text-orange-700 border-orange-200';
      default:
        return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'follow-up':
        return 'bg-primary/10 text-primary border-primary/20';
      case 'initial':
        return 'bg-green-50 text-green-600 border-green-200';
      case 'reminder':
        return 'bg-yellow-50 text-yellow-600 border-yellow-200';
      case 'proposal':
        return 'bg-purple-50 text-purple-600 border-purple-200';
      default:
        return 'bg-gray-50 text-gray-600 border-gray-200';
    }
  };

  const handleTemplateClick = (template: Template) => {
    setSelectedTemplate(template);
    setIsEditMode(false);
  };

  const handleEdit = (template: Template) => {
    setSelectedTemplate(template);
    setIsEditMode(true);
  };

  const handleDuplicate = (template: Template) => {
    console.log('Duplicating template:', template.name);
    // Add duplication logic here
  };

  const handleDelete = (template: Template) => {
    console.log('Deleting template:', template.name);
    // Add deletion logic here
  };

  const handleToggleFavorite = (template: Template) => {
    console.log('Toggling favorite for:', template.name);
    // Add favorite toggle logic here
  };

  return (
    <div className="h-full overflow-auto">
      <div className="p-4 space-y-4">
        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-3">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 rounded-lg bg-primary/10">
                  <FileText className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-gray-600">Total Templates</p>
                  <p className="text-2xl font-semibold">{templates.length}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 rounded-lg bg-yellow-100">
                  <Star className="w-5 h-5 text-yellow-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-600">Favorites</p>
                  <p className="text-2xl font-semibold">{templates.filter(t => t.isFavorite).length}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Templates List */}
        <div className="space-y-3">
          {filteredTemplates.map((template) => (
            <Card 
              key={template.id}
              className="cursor-pointer hover:shadow-md transition-shadow border border-gray-200"
              onClick={() => handleTemplateClick(template)}
            >
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <h3 className="font-medium">{template.name}</h3>
                      {template.isFavorite && (
                        <Star className="w-4 h-4 text-yellow-500 fill-current" />
                      )}
                    </div>
                    <p className="text-sm text-gray-600 mb-3">{template.description}</p>
                    
                    <div className="flex items-center space-x-2 mb-3">
                      <Badge className={`${getTypeColor(template.type)} border`}>
                        <div className="flex items-center space-x-1">
                          {getTypeIcon(template.type)}
                          <span className="capitalize">{template.type}</span>
                        </div>
                      </Badge>
                      <Badge className={`${getCategoryColor(template.category)} border`}>
                        {template.category.replace('-', ' ')}
                      </Badge>
                    </div>

                    <div className="flex items-center space-x-4 text-xs text-gray-500">
                      <span>Used {template.usageCount} times</span>
                      <span>•</span>
                      <span>Last used {template.lastUsed.toLocaleDateString()}</span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-1 ml-3">
                    <Button
                      variant="ghost"
                      size="sm"
                      className="p-1 h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleToggleFavorite(template);
                      }}
                    >
                      <Star className={`w-4 h-4 ${template.isFavorite ? 'text-yellow-500 fill-current' : 'text-gray-400'}`} />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="p-1 h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDuplicate(template);
                      }}
                    >
                      <Copy className="w-4 h-4 text-gray-500" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="p-1 h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleEdit(template);
                      }}
                    >
                      <Edit className="w-4 h-4 text-gray-500" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="p-1 h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(template);
                      }}
                    >
                      <Trash2 className="w-4 h-4 text-red-500" />
                    </Button>
                  </div>
                </div>

                {/* Preview of content */}
                <div className="bg-gray-50 rounded-lg p-3 mt-3">
                  <p className="text-sm text-gray-700 line-clamp-2">
                    {template.content.substring(0, 150)}...
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {filteredTemplates.length === 0 && (
          <div className="text-center py-12">
            <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-medium text-gray-900 mb-2">No templates found</h3>
            <p className="text-gray-500 mb-4">
              {searchQuery ? 'Try adjusting your search terms' : 'Create your first template to get started'}
            </p>
            <Button onClick={() => setShowCreateDialog(true)}>
              Create Template
            </Button>
          </div>
        )}
      </div>

      {/* Template Detail/Edit Dialog */}
      <Dialog open={!!selectedTemplate} onOpenChange={() => setSelectedTemplate(null)}>
        <DialogContent className="sm:max-w-md max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              {selectedTemplate && getTypeIcon(selectedTemplate.type)}
              <span>{isEditMode ? 'Edit Template' : selectedTemplate?.name}</span>
            </DialogTitle>
            <DialogDescription>
              {isEditMode ? 'Modify template content and settings' : 'Template details and content preview'}
            </DialogDescription>
          </DialogHeader>
          
          {selectedTemplate && (
            <div className="space-y-4">
              {isEditMode ? (
                // Edit Form
                <>
                  <div>
                    <Label htmlFor="template-name">Template Name</Label>
                    <Input
                      id="template-name"
                      defaultValue={selectedTemplate.name}
                      className="mt-2"
                    />
                  </div>
                  
                  <div>
                    <Label htmlFor="template-description">Description</Label>
                    <Input
                      id="template-description"
                      defaultValue={selectedTemplate.description}
                      className="mt-2"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <Label htmlFor="template-type">Type</Label>
                      <Select defaultValue={selectedTemplate.type}>
                        <SelectTrigger className="mt-2">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="email">Email</SelectItem>
                          <SelectItem value="sms">SMS</SelectItem>
                          <SelectItem value="call">Call Script</SelectItem>
                          <SelectItem value="appointment">Appointment</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                    
                    <div>
                      <Label htmlFor="template-category">Category</Label>
                      <Select defaultValue={selectedTemplate.category}>
                        <SelectTrigger className="mt-2">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="initial">Initial Contact</SelectItem>
                          <SelectItem value="follow-up">Follow-up</SelectItem>
                          <SelectItem value="reminder">Reminder</SelectItem>
                          <SelectItem value="proposal">Proposal</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div>
                    <Label htmlFor="template-content">Template Content</Label>
                    <Textarea
                      id="template-content"
                      defaultValue={selectedTemplate.content}
                      className="mt-2 min-h-[100px]"
                      placeholder="Enter your template content... Use {customerName}, {projectType}, etc. for variables"
                    />
                  </div>

                  <div className="flex space-x-3 pt-2">
                    <Button 
                      onClick={() => setIsEditMode(false)}
                      variant="outline" 
                      className="flex-1"
                    >
                      Cancel
                    </Button>
                    <Button 
                      onClick={() => {
                        console.log('Saving template changes');
                        setSelectedTemplate(null);
                        setIsEditMode(false);
                      }}
                      className="flex-1"
                    >
                      Save Changes
                    </Button>
                  </div>
                </>
              ) : (
                // View Mode
                <>
                  <div className="space-y-3">
                    <div className="flex items-center space-x-2">
                      <Badge className={`${getTypeColor(selectedTemplate.type)} border`}>
                        <div className="flex items-center space-x-1">
                          {getTypeIcon(selectedTemplate.type)}
                          <span className="capitalize">{selectedTemplate.type}</span>
                        </div>
                      </Badge>
                      <Badge className={`${getCategoryColor(selectedTemplate.category)} border`}>
                        {selectedTemplate.category.replace('-', ' ')}
                      </Badge>
                    </div>

                    <p className="text-sm text-gray-600">{selectedTemplate.description}</p>

                    <div className="bg-gray-50 rounded-lg p-4">
                      <Label className="text-xs text-gray-500 uppercase tracking-wide">Template Content</Label>
                      <p className="text-sm mt-2 whitespace-pre-wrap">{selectedTemplate.content}</p>
                    </div>

                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-gray-500">Usage Count:</span>
                        <span className="ml-2 font-medium">{selectedTemplate.usageCount}</span>
                      </div>
                      <div>
                        <span className="text-gray-500">Last Used:</span>
                        <span className="ml-2 font-medium">{selectedTemplate.lastUsed.toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex space-x-3 pt-2">
                    <Button 
                      onClick={() => setSelectedTemplate(null)}
                      variant="outline" 
                      className="flex-1"
                    >
                      Close
                    </Button>
                    <Button 
                      onClick={() => setIsEditMode(true)}
                      className="flex-1"
                    >
                      <Edit className="w-4 h-4 mr-2" />
                      Edit Template
                    </Button>
                  </div>
                </>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}