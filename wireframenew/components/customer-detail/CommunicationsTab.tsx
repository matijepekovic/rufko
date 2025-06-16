import { useState } from "react";
import {
  MessageCircle,
  Phone,
  Mail,
  Plus,
  Send,
  MoreVertical,
  Search,
  PhoneCall,
  Voicemail,
} from "lucide-react";
import { Button } from "../ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Input } from "../ui/input";
import { Textarea } from "../ui/textarea";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { Badge } from "../ui/badge";
import { KanbanCardData } from "../KanbanCard";

interface CommunicationsTabProps {
  customer: KanbanCardData;
}

interface Message {
  id: string;
  type: "sms" | "call" | "voicemail";
  content?: string;
  timestamp: string;
  direction: "inbound" | "outbound";
  duration?: string;
  status?: "delivered" | "read" | "failed";
}

interface EmailThread {
  id: string;
  subject: string;
  lastMessage: string;
  timestamp: string;
  unreadCount: number;
  participants: string[];
}

type CommunicationType = "messages" | "emails";

export function CommunicationsTab({
  customer,
}: CommunicationsTabProps) {
  const [activeType, setActiveType] =
    useState<CommunicationType>("messages");
  const [newMessage, setNewMessage] = useState("");
  const [searchQuery, setSearchQuery] = useState("");

  // Safe access to customer properties
  const customerName = customer?.customerName || "Customer";

  const messages: Message[] = [
    {
      id: "1",
      type: "sms",
      content:
        "Hi! Just confirming our appointment for tomorrow at 2 PM.",
      timestamp: "2 hours ago",
      direction: "inbound",
      status: "read",
    },
    {
      id: "2",
      type: "sms",
      content:
        "Confirmed! See you tomorrow at 2 PM. Please have your insurance documents ready.",
      timestamp: "1 hour ago",
      direction: "outbound",
      status: "delivered",
    },
    {
      id: "3",
      type: "call",
      timestamp: "3 hours ago",
      direction: "outbound",
      duration: "8m 32s",
    },
    {
      id: "4",
      type: "voicemail",
      content:
        "Hey, this is Sarah. I wanted to follow up on the roof inspection quote. Give me a call back when you get a chance.",
      timestamp: "1 day ago",
      direction: "inbound",
    },
    {
      id: "5",
      type: "sms",
      content:
        "Thanks for the quick response! The quote looks good.",
      timestamp: "2 days ago",
      direction: "inbound",
      status: "read",
    },
    {
      id: "6",
      type: "sms",
      content:
        "Great! I'll prepare the paperwork and send it over by end of day.",
      timestamp: "2 days ago",
      direction: "outbound",
      status: "read",
    },
  ];

  const emailThreads: EmailThread[] = [
    {
      id: "1",
      subject: "Insurance Claim Documentation",
      lastMessage:
        "Here are the additional photos you requested for the claim...",
      timestamp: "1 hour ago",
      unreadCount: 2,
      participants: [
        "sarah.johnson@email.com",
        "claims@insurance.com",
      ],
    },
    {
      id: "2",
      subject: "Roof Inspection Quote - Follow Up",
      lastMessage:
        "Thank you for the detailed quote. I have a few questions about...",
      timestamp: "1 day ago",
      unreadCount: 0,
      participants: ["sarah.johnson@email.com"],
    },
    {
      id: "3",
      subject: "Scheduling Roof Repair",
      lastMessage:
        "What dates work best for your team to start the repair work?",
      timestamp: "3 days ago",
      unreadCount: 1,
      participants: [
        "sarah.johnson@email.com",
        "scheduling@company.com",
      ],
    },
  ];

  const filteredMessages = messages.filter(
    (message) =>
      !searchQuery ||
      message.content
        ?.toLowerCase()
        .includes(searchQuery.toLowerCase()) ||
      message.type
        .toLowerCase()
        .includes(searchQuery.toLowerCase()),
  );

  const filteredEmailThreads = emailThreads.filter(
    (thread) =>
      !searchQuery ||
      thread.subject
        .toLowerCase()
        .includes(searchQuery.toLowerCase()) ||
      thread.lastMessage
        .toLowerCase()
        .includes(searchQuery.toLowerCase()),
  );

  const handleSendMessage = () => {
    if (newMessage.trim()) {
      console.log("Sending message:", newMessage);
      setNewMessage("");
    }
  };

  const renderMessageBubble = (message: Message) => {
    const isOutbound = message.direction === "outbound";

    return (
      <div
        key={message.id}
        className={`flex ${isOutbound ? "justify-end" : "justify-start"} mb-3`}
      >
        <div
          className={`flex items-end space-x-2 max-w-[280px] ${isOutbound ? "flex-row-reverse space-x-reverse" : ""}`}
        >
          {!isOutbound && (
            <Avatar className="w-8 h-8 flex-shrink-0">
              <AvatarFallback className="bg-gray-200 text-gray-600 text-xs">
                {customerName
                  .split(" ")
                  .map((n) => n[0])
                  .join("")
                  .toUpperCase()}
              </AvatarFallback>
            </Avatar>
          )}

          <div
            className={`flex flex-col ${isOutbound ? "items-end" : "items-start"}`}
          >
            {/* Message Bubble */}
            <div
              className={`rounded-2xl px-4 py-2 ${
                message.type === "sms"
                  ? isOutbound
                    ? "bg-primary text-primary-foreground"
                    : "bg-gray-100 text-gray-900"
                  : message.type === "call"
                    ? "bg-green-100 text-green-800 border border-green-200"
                    : "bg-purple-100 text-purple-800 border border-purple-200"
              }`}
            >
              {message.type === "sms" && message.content && (
                <p className="text-sm">{message.content}</p>
              )}

              {message.type === "call" && (
                <div className="flex items-center space-x-2">
                  <PhoneCall className="w-4 h-4" />
                  <div>
                    <p className="text-sm font-medium">
                      {isOutbound
                        ? "Outgoing call"
                        : "Incoming call"}
                    </p>
                    {message.duration && (
                      <p className="text-xs opacity-75">
                        {message.duration}
                      </p>
                    )}
                  </div>
                </div>
              )}

              {message.type === "voicemail" && (
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <Voicemail className="w-4 h-4" />
                    <p className="text-sm font-medium">
                      Voicemail
                    </p>
                  </div>
                  {message.content && (
                    <p className="text-sm">{message.content}</p>
                  )}
                </div>
              )}
            </div>

            {/* Timestamp and Status */}
            <div
              className={`flex items-center space-x-2 mt-1 ${isOutbound ? "flex-row-reverse space-x-reverse" : ""}`}
            >
              <span className="text-xs text-gray-500">
                {message.timestamp}
              </span>
              {message.status &&
                message.type === "sms" &&
                isOutbound && (
                  <div className="flex items-center">
                    <div
                      className={`w-2 h-2 rounded-full ${
                        message.status === "delivered"
                          ? "bg-gray-400"
                          : message.status === "read"
                            ? "bg-blue-500"
                            : "bg-red-500"
                      }`}
                    />
                  </div>
                )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header with Search and Filters */}
      <div className="p-4 border-b border-gray-200 bg-background">
        <div className="flex items-center space-x-2 mb-3">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                placeholder="Search communications..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>
          </div>
          <Button variant="outline" size="sm">
            <MoreVertical className="w-4 h-4" />
          </Button>
        </div>

        {/* Communication Type Toggle */}
        <div className="flex bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => setActiveType("messages")}
            className={`flex-1 flex items-center justify-center py-2 px-4 rounded-md text-sm font-medium transition-all ${
              activeType === "messages"
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            <MessageCircle className="w-4 h-4 mr-2" />
            Messages & Calls
          </button>
          <button
            onClick={() => setActiveType("emails")}
            className={`flex-1 flex items-center justify-center py-2 px-4 rounded-md text-sm font-medium transition-all ${
              activeType === "emails"
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-600 hover:text-gray-900"
            }`}
          >
            <Mail className="w-4 h-4 mr-2" />
            Email Threads
          </button>
        </div>
      </div>

      {/* Content Area */}
      <div className="flex-1 overflow-y-auto">
        {activeType === "messages" ? (
          /* Messages and Calls - Chat Style */
          <div className="p-4 space-y-1">
            {filteredMessages.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                  <MessageCircle className="w-6 h-6 text-gray-400" />
                </div>
                <p className="text-sm text-gray-500">
                  {searchQuery
                    ? "No messages found"
                    : "No messages yet"}
                </p>
              </div>
            ) : (
              <div className="space-y-1">
                {filteredMessages.map(renderMessageBubble)}
              </div>
            )}
          </div>
        ) : (
          /* Email Threads */
          <div className="p-4">
            {filteredEmailThreads.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                  <Mail className="w-6 h-6 text-gray-400" />
                </div>
                <p className="text-sm text-gray-500">
                  {searchQuery
                    ? "No email threads found"
                    : "No email threads yet"}
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {filteredEmailThreads.map((thread) => (
                  <Card
                    key={thread.id}
                    className="cursor-pointer hover:shadow-sm transition-shadow"
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center space-x-2 mb-1">
                            <h4 className="font-medium text-gray-900 truncate">
                              {thread.subject}
                            </h4>
                            {thread.unreadCount > 0 && (
                              <Badge
                                variant="destructive"
                                className="text-xs"
                              >
                                {thread.unreadCount}
                              </Badge>
                            )}
                          </div>
                          <p className="text-sm text-gray-600 truncate mb-2">
                            {thread.lastMessage}
                          </p>
                          <div className="flex items-center justify-between">
                            <div className="flex items-center space-x-2">
                              <Mail className="w-3 h-3 text-gray-400" />
                              <span className="text-xs text-gray-500">
                                {thread.participants.length}{" "}
                                participant
                                {thread.participants.length > 1
                                  ? "s"
                                  : ""}
                              </span>
                            </div>
                            <span className="text-xs text-gray-500">
                              {thread.timestamp}
                            </span>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Quick Actions Footer */}
      <div className="p-4 border-t border-gray-200 bg-background">
        {activeType === "messages" ? (
          /* Message Composer */
          <div className="space-y-3">
            <div className="flex items-end space-x-2">
              <div className="flex-1">
                <Textarea
                  placeholder="Type your message..."
                  value={newMessage}
                  onChange={(e) =>
                    setNewMessage(e.target.value)
                  }
                  className="min-h-[44px] max-h-[120px] resize-none rounded-2xl border-gray-300 px-4 py-2"
                  rows={1}
                />
              </div>
              <Button
                onClick={handleSendMessage}
                disabled={!newMessage.trim()}
                className="rounded-full w-12 h-12 p-0 flex-shrink-0"
              >
                <Send className="w-5 h-5" />
              </Button>
            </div>
            <div className="flex space-x-2">
              <Button variant="outline" className="flex-1">
                <Phone className="w-4 h-4 mr-2" />
                Call
              </Button>
            </div>
          </div>
        ) : (
          /* Email Actions */
          <div className="flex space-x-2">
            <Button className="flex-1">
              <Mail className="w-4 h-4 mr-2" />
              Compose Email
            </Button>
            <Button variant="outline">
              <Plus className="w-4 h-4" />
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}