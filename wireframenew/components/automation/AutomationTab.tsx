import { useState } from "react";
import {
  Play,
  Pause,
  Zap,
  Users,
  Calendar,
  TrendingUp,
  AlertCircle,
  CheckCircle,
  Clock,
  ArrowRight,
} from "lucide-react";
import { Button } from "../ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "../ui/card";
import { Badge } from "../ui/badge";
import { Switch } from "../ui/switch";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "../ui/dialog";
import { Progress } from "../ui/progress";
import { Label } from "../ui/label";

interface AutomationTabProps {
  searchQuery: string;
}

interface Automation {
  id: string;
  name: string;
  description: string;
  trigger: string;
  actions: string[];
  isActive: boolean;
  successRate: number;
  executionCount: number;
  lastRun: Date;
  createdAt: Date;
  status: "running" | "paused" | "error" | "completed";
}

export function AutomationTab({
  searchQuery,
}: AutomationTabProps) {
  const [selectedAutomation, setSelectedAutomation] =
    useState<Automation | null>(null);

  // Mock automation data
  const automations: Automation[] = [
    {
      id: "1",
      name: "Lead Follow-up Sequence",
      description:
        "Automatically follow up with new leads after 24 hours, 3 days, and 1 week",
      trigger: "New lead created",
      actions: [
        "Send welcome email",
        "Schedule follow-up call",
        "Add to CRM pipeline",
      ],
      isActive: true,
      successRate: 87,
      executionCount: 156,
      lastRun: new Date("2024-06-15T10:30:00"),
      createdAt: new Date("2024-05-01"),
      status: "running",
    },
    {
      id: "2",
      name: "Appointment Reminders",
      description:
        "Send SMS and email reminders 24 hours and 2 hours before appointments",
      trigger: "Appointment scheduled",
      actions: [
        "Send 24h reminder email",
        "Send 2h reminder SMS",
        "Update calendar",
      ],
      isActive: true,
      successRate: 94,
      executionCount: 89,
      lastRun: new Date("2024-06-15T08:15:00"),
      createdAt: new Date("2024-05-10"),
      status: "running",
    },
    {
      id: "3",
      name: "Estimate Ready Notification",
      description:
        "Notify customers when their estimate is ready for review",
      trigger: 'Estimate status changed to "Ready"',
      actions: [
        "Send email notification",
        "Send SMS alert",
        "Schedule presentation call",
      ],
      isActive: false,
      successRate: 76,
      executionCount: 34,
      lastRun: new Date("2024-06-14T16:45:00"),
      createdAt: new Date("2024-05-20"),
      status: "paused",
    },
    {
      id: "4",
      name: "Weekly Progress Reports",
      description:
        "Generate and send weekly progress reports to project stakeholders",
      trigger: "Every Monday at 9 AM",
      actions: [
        "Generate report",
        "Send to customer",
        "Save to project files",
      ],
      isActive: true,
      successRate: 100,
      executionCount: 12,
      lastRun: new Date("2024-06-10T09:00:00"),
      createdAt: new Date("2024-06-01"),
      status: "running",
    },
  ];

  const filteredAutomations = automations.filter(
    (automation) =>
      automation.name
        .toLowerCase()
        .includes(searchQuery.toLowerCase()) ||
      automation.description
        .toLowerCase()
        .includes(searchQuery.toLowerCase()) ||
      automation.trigger
        .toLowerCase()
        .includes(searchQuery.toLowerCase()),
  );

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "running":
        return <Play className="w-4 h-4 text-green-600" />;
      case "paused":
        return <Pause className="w-4 h-4 text-yellow-600" />;
      case "error":
        return <AlertCircle className="w-4 h-4 text-red-600" />;
      case "completed":
        return (
          <CheckCircle className="w-4 h-4 text-blue-600" />
        );
      default:
        return <Clock className="w-4 h-4 text-gray-600" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "running":
        return "bg-green-100 text-green-700 border-green-200";
      case "paused":
        return "bg-yellow-100 text-yellow-700 border-yellow-200";
      case "error":
        return "bg-red-100 text-red-700 border-red-200";
      case "completed":
        return "bg-blue-100 text-blue-700 border-blue-200";
      default:
        return "bg-gray-100 text-gray-700 border-gray-200";
    }
  };

  const getSuccessRateColor = (rate: number) => {
    if (rate >= 90) return "text-green-600";
    if (rate >= 70) return "text-yellow-600";
    return "text-red-600";
  };

  const handleToggleAutomation = (automation: Automation) => {
    console.log("Toggling automation:", automation.name);
    // Add toggle logic here
  };

  const handleViewDetails = (automation: Automation) => {
    setSelectedAutomation(automation);
  };

  const activeAutomations = automations.filter(
    (a) => a.isActive,
  );
  const totalExecutions = automations.reduce(
    (sum, a) => sum + a.executionCount,
    0,
  );
  const avgSuccessRate = Math.round(
    automations.reduce((sum, a) => sum + a.successRate, 0) /
      automations.length,
  );

  return (
    <div className="h-full overflow-auto">
      <div className="p-4 space-y-4">
        {/* Quick Stats */}
        <div className="grid grid-cols-2 gap-3">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 rounded-lg bg-green-100">
                  <Play className="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-600">
                    Active
                  </p>
                  <p className="text-2xl font-semibold">
                    {activeAutomations.length}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 rounded-lg bg-primary/10">
                  <TrendingUp className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-gray-600">
                    Success Rate
                  </p>
                  <p className="text-2xl font-semibold">
                    {avgSuccessRate}%
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Performance Overview */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Zap className="w-5 h-5 text-primary" />
              <span>Performance Overview</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 gap-4">
              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm text-gray-600">
                    Total Executions
                  </span>
                  <span className="font-semibold">
                    {totalExecutions}
                  </span>
                </div>
                <Progress value={75} className="h-2" />
              </div>
              <div className="text-xs text-gray-500 space-y-1">
                <p>
                  • {activeAutomations.length} automations
                  currently running
                </p>
                <p>
                  • Last 30 days:{" "}
                  {Math.round(totalExecutions * 0.4)} executions
                </p>
                <p>• Average response time: 2.3 seconds</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Automations List */}
        <div className="space-y-3">
          {filteredAutomations.map((automation) => (
            <Card
              key={automation.id}
              className="cursor-pointer hover:shadow-md transition-shadow border border-gray-200"
              onClick={() => handleViewDetails(automation)}
            >
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <h3 className="font-medium">
                        {automation.name}
                      </h3>
                      <Badge
                        className={`${getStatusColor(automation.status)} border`}
                      >
                        <div className="flex items-center space-x-1">
                          {getStatusIcon(automation.status)}
                          <span className="capitalize">
                            {automation.status}
                          </span>
                        </div>
                      </Badge>
                    </div>
                    <p className="text-sm text-gray-600 mb-3">
                      {automation.description}
                    </p>

                    <div className="space-y-2">
                      <div className="flex items-center space-x-2">
                        <span className="text-xs font-medium text-gray-500">
                          Trigger:
                        </span>
                        <span className="text-xs text-gray-700 bg-gray-100 px-2 py-1 rounded">
                          {automation.trigger}
                        </span>
                      </div>

                      <div className="flex items-start space-x-2">
                        <span className="text-xs font-medium text-gray-500 mt-1">
                          Actions:
                        </span>
                        <div className="flex-1">
                          <div className="flex items-center space-x-1 flex-wrap">
                            {automation.actions
                              .slice(0, 2)
                              .map((action, index) => (
                                <span
                                  key={index}
                                  className="text-xs text-gray-700 bg-blue-50 px-2 py-1 rounded"
                                >
                                  {action}
                                </span>
                              ))}
                            {automation.actions.length > 2 && (
                              <span className="text-xs text-gray-500">
                                +{automation.actions.length - 2}{" "}
                                more
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center space-x-4 mt-3 text-xs text-gray-500">
                      <span>
                        Success rate:
                        <span
                          className={`ml-1 font-medium ${getSuccessRateColor(automation.successRate)}`}
                        >
                          {automation.successRate}%
                        </span>
                      </span>
                      <span>•</span>
                      <span>
                        Executed {automation.executionCount}{" "}
                        times
                      </span>
                      <span>•</span>
                      <span>
                        Last run:{" "}
                        {automation.lastRun.toLocaleDateString()}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2 ml-3">
                    <Switch
                      checked={automation.isActive}
                      onCheckedChange={() =>
                        handleToggleAutomation(automation)
                      }
                      onClick={(e) => e.stopPropagation()}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {filteredAutomations.length === 0 && (
          <div className="text-center py-12">
            <Zap className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="font-medium text-gray-900 mb-2">
              No automations found
            </h3>
            <p className="text-gray-500 mb-4">
              {searchQuery
                ? "Try adjusting your search terms"
                : "Create your first automation to streamline your workflow"}
            </p>
            <Button>Create Automation</Button>
          </div>
        )}
      </div>

      {/* Automation Details Dialog */}
      <Dialog
        open={!!selectedAutomation}
        onOpenChange={() => setSelectedAutomation(null)}
      >
        <DialogContent className="sm:max-w-md max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center space-x-2">
              {selectedAutomation &&
                getStatusIcon(selectedAutomation.status)}
              <span>{selectedAutomation?.name}</span>
            </DialogTitle>
            <DialogDescription>
              Automation workflow details and performance
              metrics
            </DialogDescription>
          </DialogHeader>

          {selectedAutomation && (
            <div className="space-y-4">
              <div className="space-y-3">
                <Badge
                  className={`${getStatusColor(selectedAutomation.status)} border w-fit`}
                >
                  <div className="flex items-center space-x-1">
                    {getStatusIcon(selectedAutomation.status)}
                    <span className="capitalize">
                      {selectedAutomation.status}
                    </span>
                  </div>
                </Badge>

                <p className="text-sm text-gray-600">
                  {selectedAutomation.description}
                </p>

                <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                  <div>
                    <Label className="text-xs text-gray-500 uppercase tracking-wide">
                      Trigger
                    </Label>
                    <p className="text-sm mt-1 font-medium">
                      {selectedAutomation.trigger}
                    </p>
                  </div>

                  <div>
                    <Label className="text-xs text-gray-500 uppercase tracking-wide">
                      Actions
                    </Label>
                    <div className="mt-2 space-y-2">
                      {selectedAutomation.actions.map(
                        (action, index) => (
                          <div
                            key={index}
                            className="flex items-center space-x-2"
                          >
                            <span className="text-sm text-gray-400">
                              {index + 1}.
                            </span>
                            <span className="text-sm">
                              {action}
                            </span>
                            {index <
                              selectedAutomation.actions
                                .length -
                                1 && (
                              <ArrowRight className="w-3 h-3 text-gray-400" />
                            )}
                          </div>
                        ),
                      )}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-blue-50 rounded-lg p-3">
                    <p className="text-sm text-blue-600 font-medium">
                      Success Rate
                    </p>
                    <p className="text-2xl font-semibold text-blue-700">
                      {selectedAutomation.successRate}%
                    </p>
                  </div>
                  <div className="bg-green-50 rounded-lg p-3">
                    <p className="text-sm text-green-600 font-medium">
                      Executions
                    </p>
                    <p className="text-2xl font-semibold text-green-700">
                      {selectedAutomation.executionCount}
                    </p>
                  </div>
                </div>

                <div className="text-sm space-y-1">
                  <div className="flex justify-between">
                    <span className="text-gray-500">
                      Created:
                    </span>
                    <span className="font-medium">
                      {selectedAutomation.createdAt.toLocaleDateString()}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">
                      Last Run:
                    </span>
                    <span className="font-medium">
                      {selectedAutomation.lastRun.toLocaleString()}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">
                      Status:
                    </span>
                    <span className="font-medium capitalize">
                      {selectedAutomation.status}
                    </span>
                  </div>
                </div>
              </div>

              <div className="flex space-x-3 pt-2">
                <Button
                  onClick={() => setSelectedAutomation(null)}
                  variant="outline"
                  className="flex-1"
                >
                  Close
                </Button>
                <Button
                  onClick={() => {
                    console.log(
                      "Editing automation:",
                      selectedAutomation.name,
                    );
                    setSelectedAutomation(null);
                  }}
                  className="flex-1"
                >
                  Edit Automation
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}