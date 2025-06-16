interface SummaryBarProps {
  jobsCount: number;
  quotesCount: number;
  pipeline: number;
  onTap?: () => void;
}

export function SummaryBar({ jobsCount, quotesCount, pipeline, onTap }: SummaryBarProps) {
  return (
    <button 
      onClick={onTap}
      className="w-full h-8 flex items-center justify-center text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
    >
      {jobsCount} jobs · {quotesCount} quotes · ${pipeline.toLocaleString()} pipeline
    </button>
  );
}