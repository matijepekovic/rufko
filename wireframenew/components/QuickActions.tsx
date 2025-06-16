import { Button } from './ui/button';
import { Plus, Users, FileText, Calendar } from 'lucide-react';

interface QuickActionsProps {
  onAddLead?: () => void;
  onAddQuote?: () => void;
  onAddJob?: () => void;
}

export function QuickActions({ onAddLead, onAddQuote, onAddJob }: QuickActionsProps) {
  return (
    <div className="flex space-x-3">
      <Button
        onClick={onAddLead}
        className="flex-1 h-10 rounded-[20px] bg-primary hover:bg-primary/90 text-primary-foreground"
      >
        <Users className="w-4 h-4 mr-2" />
        Lead
      </Button>
      
      <Button
        onClick={onAddQuote}
        className="flex-1 h-10 rounded-[20px] bg-primary hover:bg-primary/90 text-primary-foreground"
      >
        <FileText className="w-4 h-4 mr-2" />
        Quote
      </Button>
      
      <Button
        onClick={onAddJob}
        className="flex-1 h-10 rounded-[20px] bg-primary hover:bg-primary/90 text-primary-foreground"
      >
        <Calendar className="w-4 h-4 mr-2" />
        Job
      </Button>
    </div>
  );
}