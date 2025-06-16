interface FeedbackFooterProps {
  onFeedbackClick?: () => void;
}

export function FeedbackFooter({ onFeedbackClick }: FeedbackFooterProps) {
  return (
    <div className="h-6 flex items-center justify-center">
      <button
        onClick={onFeedbackClick}
        className="text-xs text-muted-foreground hover:text-foreground transition-colors underline"
      >
        Got 30 sec? Suggest a feature
      </button>
    </div>
  );
}