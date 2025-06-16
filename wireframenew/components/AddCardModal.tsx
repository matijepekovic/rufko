import { useState } from 'react';
import { X } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { KanbanCardData } from './KanbanCard';

interface AddCardModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (card: Omit<KanbanCardData, 'id'>) => void;
  defaultStage?: string;
  boardColor?: string;
}

export function AddCardModal({ isOpen, onClose, onSave, defaultStage, boardColor }: AddCardModalProps) {
  const [formData, setFormData] = useState({
    title: '',
    phone: '',
    value: '',
    stage: defaultStage || 'Lead'
  });

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim()) return;
    
    const newCard: Omit<KanbanCardData, 'id'> = {
      title: formData.title.trim(),
      phone: formData.phone.trim() || undefined,
      value: parseFloat(formData.value) || 0,
      stage: formData.stage,
      daysIdle: 0,
      nextDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
      boardColor
    };
    
    onSave(newCard);
    
    // Reset form
    setFormData({
      title: '',
      phone: '',
      value: '',
      stage: defaultStage || 'Lead'
    });
    
    onClose();
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div className="fixed inset-0 z-50 bg-black bg-opacity-50 flex items-center justify-center p-4">
      <div 
        className="bg-white rounded-2xl shadow-xl w-full max-w-sm"
        style={{ width: '320px', height: '420px' }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 className="font-semibold text-lg">Add New Card</h2>
          <Button variant="ghost" size="sm" onClick={onClose} className="h-8 w-8 p-0">
            <X className="w-4 h-4" />
          </Button>
        </div>
        
        {/* Form */}
        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          <div>
            <Label htmlFor="title" className="text-sm font-medium text-gray-700">
              Customer Name *
            </Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => handleInputChange('title', e.target.value)}
              placeholder="Enter customer name"
              className="mt-1"
              required
            />
          </div>
          
          <div>
            <Label htmlFor="phone" className="text-sm font-medium text-gray-700">
              Phone Number
            </Label>
            <Input
              id="phone"
              value={formData.phone}
              onChange={(e) => handleInputChange('phone', e.target.value)}
              placeholder="(555) 123-4567"
              className="mt-1"
            />
          </div>
          
          <div>
            <Label htmlFor="value" className="text-sm font-medium text-gray-700">
              Deal Value
            </Label>
            <Input
              id="value"
              type="number"
              value={formData.value}
              onChange={(e) => handleInputChange('value', e.target.value)}
              placeholder="5000"
              className="mt-1"
            />
          </div>
          
          <div>
            <Label htmlFor="stage" className="text-sm font-medium text-gray-700">
              Stage
            </Label>
            <Select value={formData.stage} onValueChange={(value) => handleInputChange('stage', value)}>
              <SelectTrigger className="mt-1">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="Lead">Lead</SelectItem>
                <SelectItem value="Qualified">Qualified</SelectItem>
                <SelectItem value="Proposal">Proposal</SelectItem>
                <SelectItem value="Negotiation">Negotiation</SelectItem>
                <SelectItem value="Closed Won">Closed Won</SelectItem>
                <SelectItem value="Closed Lost">Closed Lost</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div className="flex space-x-3 pt-4">
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
            <Button type="submit" className="flex-1">
              Save
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}