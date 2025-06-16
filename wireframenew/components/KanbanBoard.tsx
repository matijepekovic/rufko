import { useState, useRef } from 'react';
import { Button } from './ui/button';
import { BoardSwitcher } from './BoardSwitcher';
import { KanbanColumn, KanbanColumnData } from './KanbanColumn';
import { KanbanCardData } from './KanbanCard';
import { KanbanDragLayer } from './KanbanDragLayer';
import { AddCardModal } from './AddCardModal';
import { CardDrawer } from './CardDrawer';
import { SortOptions } from './KanbanSortDropdown';
import { sharedCustomers, getCustomerById } from '../hooks/useLeadData';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import { TouchBackend } from 'react-dnd-touch-backend';

interface KanbanBoardProps {
  onCall: (phone: string) => void;
  onNote: (cardId: string) => void;
  onTask: (cardId: string) => void;
  onNavigateToCustomer?: (customer: KanbanCardData) => void;
}

// Custom backend that combines HTML5 and Touch backends for better experience
const isTouchDevice = () => {
  return 'ontouchstart' in window || navigator.maxTouchPoints > 0;
};

export function KanbanBoard({ onCall, onNote, onTask, onNavigateToCustomer }: KanbanBoardProps) {
  const [selectedBoard, setSelectedBoard] = useState('sales');
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedColumn, setSelectedColumn] = useState<string | null>(null);
  const [selectedCard, setSelectedCard] = useState<KanbanCardData | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  
  // Sort state for each column
  const [columnSorts, setColumnSorts] = useState<Record<string, SortOptions | null>>({});

  const boards = [
    { 
      id: 'sales', 
      name: 'Sales Pipeline', 
      color: '#246BFD', 
      icon: 'tag' as const, 
      selected: selectedBoard === 'sales' 
    },
    { 
      id: 'warranty', 
      name: 'Warranty Claims', 
      color: '#00A876', 
      icon: 'wrench' as const, 
      selected: selectedBoard === 'warranty' 
    },
    { 
      id: 'projects', 
      name: 'Active Projects', 
      color: '#725BFF', 
      icon: 'package' as const, 
      selected: selectedBoard === 'projects' 
    },
    { 
      id: 'maintenance', 
      name: 'Maintenance', 
      color: '#FF6B35', 
      icon: 'wrench' as const, 
      selected: selectedBoard === 'maintenance' 
    },
    { 
      id: 'inspections', 
      name: 'Inspections', 
      color: '#8B5CF6', 
      icon: 'tag' as const, 
      selected: selectedBoard === 'inspections' 
    },
    { 
      id: 'quotes', 
      name: 'Pending Quotes', 
      color: '#EF4444', 
      icon: 'package' as const, 
      selected: selectedBoard === 'quotes' 
    },
    { 
      id: 'followups', 
      name: 'Follow-ups', 
      color: '#F59E0B', 
      icon: 'tag' as const, 
      selected: selectedBoard === 'followups' 
    },
    { 
      id: 'emergency', 
      name: 'Emergency Repairs', 
      color: '#DC2626', 
      icon: 'wrench' as const, 
      selected: selectedBoard === 'emergency' 
    }
  ];

  // Mock cards using shared customer data but maintaining original kanban structure
  const [mockCards, setMockCards] = useState<KanbanCardData[]>([
    {
      id: '1',
      title: getCustomerById('1')?.name || 'Thompson Residence',
      stage: 'Lead',
      value: 2500,
      daysIdle: 2,
      status: 'hot',
      tags: ['Roof Repair', 'Urgent'],
      phone: getCustomerById('1')?.phone || '(555) 123-4567',
      lastContact: '2 days ago',
      nextAction: 'Follow-up call scheduled',
      dateCreated: new Date(2024, 5, 10),
      lastInteractionDate: new Date(2024, 5, 12)
    },
    {
      id: '2',
      title: getCustomerById('2')?.name || 'Johnson Property',
      stage: 'Quote Sent',
      value: 5800,
      daysIdle: 5,
      status: 'warm',
      tags: ['Full Replacement'],
      phone: getCustomerById('2')?.phone || '(555) 987-6543',
      lastContact: '5 days ago',
      nextAction: 'Waiting for response',
      dateCreated: new Date(2024, 5, 5),
      lastInteractionDate: new Date(2024, 5, 7)
    },
    {
      id: '3',
      title: getCustomerById('3')?.name || 'Davis Home',
      stage: 'Negotiation',
      value: 3200,
      daysIdle: 1,
      status: 'hot',
      tags: ['Gutter Work', 'Insurance'],
      phone: getCustomerById('3')?.phone || '(555) 456-7890',
      lastContact: '1 day ago',
      nextAction: 'Contract review',
      dateCreated: new Date(2024, 2, 10),
      lastInteractionDate: new Date(2024, 5, 13)
    },
    {
      id: '4',
      title: getCustomerById('4')?.name || 'Wilson Building',
      stage: 'Won',
      value: 12000,
      daysIdle: 0,
      status: 'hot',
      tags: ['Commercial', 'Multi-unit'],
      phone: getCustomerById('4')?.phone || '(555) 321-0987',
      lastContact: 'Today',
      nextAction: 'Project kickoff',
      dateCreated: new Date(2024, 5, 11),
      lastInteractionDate: new Date(2024, 5, 14)
    },
    {
      id: '5',
      title: getCustomerById('5')?.name || 'Miller House',
      stage: 'Lead',
      value: 1800,
      daysIdle: 8,
      status: 'cold',
      tags: ['Small Repair'],
      phone: getCustomerById('5')?.phone || '(555) 555-0123',
      lastContact: '8 days ago',
      nextAction: 'Needs attention',
      dateCreated: new Date(2024, 3, 8),
      lastInteractionDate: new Date(2024, 3, 10)
    },
    {
      id: '6',
      title: getCustomerById('6')?.name || 'Garcia Estate',
      stage: 'Quote Sent',
      value: 15000,
      daysIdle: 12,
      status: 'dormant',
      tags: ['Premium', 'Large Project'],
      phone: getCustomerById('6')?.phone || '(555) 888-9999',
      lastContact: '12 days ago',
      nextAction: 'Follow-up required',
      dateCreated: new Date(2023, 11, 10),
      lastInteractionDate: new Date(2023, 11, 15)
    }
  ]);

  const getStageNameById = (columnId: string): string => {
    const stageMap: Record<string, string> = {
      'lead': 'Lead',
      'quote': 'Quote Sent',
      'negotiation': 'Negotiation',
      'won': 'Won'
    };
    return stageMap[columnId] || 'Lead';
  };

  const columns: KanbanColumnData[] = [
    { 
      id: 'lead', 
      title: 'Leads', 
      count: mockCards.filter(card => card.stage === 'Lead').length,
      cards: mockCards.filter(card => card.stage === 'Lead'),
      boardColor: '#246BFD'
    },
    { 
      id: 'quote', 
      title: 'Quote Sent', 
      count: mockCards.filter(card => card.stage === 'Quote Sent').length,
      cards: mockCards.filter(card => card.stage === 'Quote Sent'),
      boardColor: '#00A876'
    },
    { 
      id: 'negotiation', 
      title: 'Negotiation', 
      count: mockCards.filter(card => card.stage === 'Negotiation').length,
      cards: mockCards.filter(card => card.stage === 'Negotiation'),
      boardColor: '#725BFF'
    },
    { 
      id: 'won', 
      title: 'Won', 
      count: mockCards.filter(card => card.stage === 'Won').length,
      cards: mockCards.filter(card => card.stage === 'Won'),
      boardColor: '#10B981'
    }
  ];

  const handleAddCard = (columnId: string) => {
    setSelectedColumn(columnId);
    setShowAddModal(true);
  };

  const handleCardSelect = (card: KanbanCardData) => {
    // Navigate to customer detail instead of opening drawer
    if (onNavigateToCustomer) {
      onNavigateToCustomer(card);
    } else {
      // Fallback to drawer if navigation not available
      setSelectedCard(card);
      setDrawerOpen(true);
    }
  };

  const handleModalSubmit = (cardData: any) => {
    console.log('New card:', cardData, 'for column:', selectedColumn);
    setShowAddModal(false);
    setSelectedColumn(null);
  };

  const handleSortChange = (columnId: string, sortOptions: SortOptions | null) => {
    setColumnSorts(prev => ({
      ...prev,
      [columnId]: sortOptions
    }));
  };

  const handleCardMove = (cardId: string, targetColumnId: string) => {
    const targetStage = getStageNameById(targetColumnId);
    
    setMockCards(prevCards => 
      prevCards.map(card => 
        card.id === cardId 
          ? { ...card, stage: targetStage }
          : card
      )
    );
  };

  // Backend selection based on device capabilities
  const backend = isTouchDevice() ? TouchBackend : HTML5Backend;
  const backendOptions = isTouchDevice() 
    ? {
        enableMouseEvents: true,
        delayTouchStart: 200, // 200ms delay for touch start (press and hold)
        delayMouseStart: 0,
        touchSlop: 5,
      }
    : {};

  return (
    <DndProvider backend={backend} options={backendOptions}>
      <div className="flex flex-col h-full bg-background">
        {/* Board Switcher */}
        <BoardSwitcher 
          boards={boards}
          onBoardSelect={setSelectedBoard}
        />
        
        {/* Kanban Columns */}
        <div 
          ref={scrollContainerRef}
          className="flex-1 overflow-x-auto overflow-y-hidden scrollable"
        >
          <div className="flex h-full min-w-max px-4 py-4 space-x-4">
            {columns.map((column) => (
              <KanbanColumn
                key={column.id}
                column={column}
                onCardClick={handleCardSelect}
                onCall={onCall}
                onNote={onNote}
                onTask={onTask}
                sortOptions={columnSorts[column.id] || null}
                onSortChange={handleSortChange}
                onCardMove={handleCardMove}
              />
            ))}
          </div>
        </div>

        {/* Custom Drag Layer - Cards follow finger */}
        <KanbanDragLayer />

        {/* Add Card Modal */}
        <AddCardModal
          isOpen={showAddModal}
          onClose={() => {
            setShowAddModal(false);
            setSelectedColumn(null);
          }}
          onSubmit={handleModalSubmit}
          columnId={selectedColumn}
        />

        {/* Card Detail Drawer - Fallback only */}
        <CardDrawer
          card={selectedCard}
          isOpen={drawerOpen}
          onClose={() => {
            setDrawerOpen(false);
            setSelectedCard(null);
          }}
        />
      </div>
    </DndProvider>
  );
}