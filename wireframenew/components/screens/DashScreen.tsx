import { useState } from 'react';
import { Home } from 'lucide-react';
import { CalendarSticky } from '../CalendarSticky';
import { SummaryBar } from '../SummaryBar';
import { ScheduleList } from '../ScheduleList';
import { KPIGrid } from '../KPIGrid';
import { QuickActions } from '../QuickActions';
import { HeatmapMini } from '../HeatmapMini';
import { SalesSparkline } from '../SalesSparkline';
import { FeedbackFooter } from '../FeedbackFooter';

export function DashScreen() {
  const [selectedDate, setSelectedDate] = useState(new Date());

  // Mock data
  const mockJobs = [
    {
      id: '1',
      customerName: 'Sarah Johnson',
      phoneNumber: '(555) 123-4567',
      address: '123 Oak Street, Springfield, IL 62701',
      time: '9:00 AM',
      status: 'scheduled' as const
    },
    {
      id: '2',
      customerName: 'Mike Chen',
      phoneNumber: '(555) 987-6543',
      address: '456 Pine Avenue, Downtown, Chicago, IL 60601',
      time: '11:30 AM',
      status: 'in-progress' as const
    },
    {
      id: '3',
      customerName: 'Emily Rodriguez',
      phoneNumber: '(555) 456-7890',
      address: '789 Maple Drive, Westside, Aurora, IL 60502',
      time: '2:00 PM',
      status: 'scheduled' as const
    },
    {
      id: '4',
      customerName: 'David Wilson',
      phoneNumber: '(555) 321-0987',
      address: '321 Elm Street, Northgate, Naperville, IL 60540',
      time: '4:30 PM',
      status: 'completed' as const
    }
  ];

  const handleDateChange = (date: Date) => {
    setSelectedDate(date);
  };

  const handleSummaryTap = () => {
    console.log('Summary bar tapped');
  };

  const handleKPICardClick = (cardId: string) => {
    console.log('KPI card clicked:', cardId);
  };

  const handleQuickAction = (action: string) => {
    console.log('Quick action:', action);
  };

  const handleHeatmapTap = () => {
    console.log('Heatmap tapped');
  };

  const handleSparklineTap = () => {
    console.log('Sparkline tapped');
  };

  const handleFeedbackClick = () => {
    console.log('Feedback clicked');
  };

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <div className="flex-shrink-0 bg-surface border-b border-stroke navbar-safe py-3">
        <div className="flex items-center space-x-2">
          <Home className="w-5 h-5 text-primary" />
          <h1 className="text-gray-900">Dashboard</h1>
        </div>
      </div>

      {/* Sticky Calendar Strip */}
      <div className="flex-shrink-0 bg-background border-b border-stroke px-4 py-2">
        <CalendarSticky onDateChange={handleDateChange} />
      </div>
      
      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="flex flex-col space-y-2 p-4 pb-20">
          
          {/* Today Summary Bar */}
          <SummaryBar
            jobsCount={mockJobs.length}
            quotesCount={8}
            pipeline={48200}
            onTap={handleSummaryTap}
          />
          
          {/* Schedule List */}
          <div className="space-y-2">
            <ScheduleList jobs={mockJobs} />
          </div>
          
          {/* KPI Grid */}
          <div className="pt-2">
            <KPIGrid onCardClick={handleKPICardClick} />
          </div>
          
          {/* Quick Actions Row */}
          <div className="pt-2">
            <QuickActions
              onAddLead={() => handleQuickAction('add-lead')}
              onAddQuote={() => handleQuickAction('add-quote')}
              onAddJob={() => handleQuickAction('add-job')}
            />
          </div>
          
          {/* Area Heat-map Mini */}
          <div className="pt-2">
            <HeatmapMini onTap={handleHeatmapTap} />
          </div>
          
          {/* Sales Trend Sparkline */}
          <div className="pt-2">
            <SalesSparkline onTap={handleSparklineTap} />
          </div>
          
          {/* Feedback Footer */}
          <div className="pt-4">
            <FeedbackFooter onFeedbackClick={handleFeedbackClick} />
          </div>
          
        </div>
      </div>
    </div>
  );
}