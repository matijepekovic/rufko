import { useRef, useEffect } from 'react';
import { Tag, Wrench, Package } from 'lucide-react';

interface Board {
  id: string;
  name: string;
  color: string;
  icon: 'tag' | 'wrench' | 'package';
  selected: boolean;
}

interface BoardSwitcherProps {
  boards: Board[];
  onBoardSelect: (boardId: string) => void;
}

export function BoardSwitcher({ boards, onBoardSelect }: BoardSwitcherProps) {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  
  // Auto-scroll to center the selected button
  useEffect(() => {
    const selectedBoard = boards.find(board => board.selected);
    if (selectedBoard && scrollContainerRef.current) {
      const container = scrollContainerRef.current;
      const selectedButton = container.querySelector(`[data-board-id="${selectedBoard.id}"]`) as HTMLElement;
      
      if (selectedButton) {
        const containerRect = container.getBoundingClientRect();
        const buttonRect = selectedButton.getBoundingClientRect();
        const containerCenter = containerRect.width / 2;
        const buttonCenter = buttonRect.left - containerRect.left + buttonRect.width / 2;
        const scrollLeft = container.scrollLeft + buttonCenter - containerCenter;
        
        container.scrollTo({
          left: scrollLeft,
          behavior: 'smooth'
        });
      }
    }
  }, [boards]);

  const handleBoardSelect = (boardId: string) => {
    onBoardSelect(boardId);
  };

  return (
    <div className="w-full bg-surface border-b border-stroke">
      <div 
        ref={scrollContainerRef}
        className="flex space-x-2 px-4 py-3 overflow-x-auto"
        style={{
          scrollbarWidth: 'none',
          msOverflowStyle: 'none'
        }}
      >
        {boards.map((board) => (
          <button
            key={board.id}
            data-board-id={board.id}
            onClick={() => handleBoardSelect(board.id)}
            className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 whitespace-nowrap ${
              board.selected 
                ? 'text-white shadow-md transform scale-105' 
                : 'text-gray-600 bg-gray-100 hover:bg-gray-200 hover:scale-105'
            }`}
            style={{ 
              backgroundColor: board.selected ? board.color : undefined,
              minHeight: '36px'
            }}
          >
            {board.name}
          </button>
        ))}
        
        {/* Hide scrollbar using CSS-in-JS for WebKit browsers */}
        <style dangerouslySetInnerHTML={{
          __html: `
            .overflow-x-auto::-webkit-scrollbar {
              display: none;
            }
          `
        }} />
      </div>
    </div>
  );
}