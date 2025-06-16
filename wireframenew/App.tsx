import { useState } from "react";
import { BottomNavigation } from "./components/BottomNavigation";
import { DashScreen } from "./components/screens/DashScreen";
import { SalesScreen } from "./components/screens/SalesScreen";
import { JobsScreen } from "./components/screens/JobsScreen";
import { VaultScreen } from "./components/screens/VaultScreen";
import { ToolsScreen } from "./components/screens/ToolsScreen";
import { CustomerDetailScreen } from "./components/screens/CustomerDetailScreen";
import { KanbanCardData } from "./components/KanbanCard";

export default function App() {
  const [activeTab, setActiveTab] = useState("dash");
  const [navigationStack, setNavigationStack] = useState<
    string[]
  >([]);
  const [selectedCustomer, setSelectedCustomer] =
    useState<KanbanCardData | null>(null);

  const navigateToCustomerDetail = (
    customer: KanbanCardData,
  ) => {
    setSelectedCustomer(customer);
    setNavigationStack((prev) => [...prev, "customer-detail"]);
  };

  const navigateBack = () => {
    setNavigationStack((prev) => {
      const newStack = [...prev];
      newStack.pop();

      if (newStack.length === 0) {
        setSelectedCustomer(null);
      }

      return newStack;
    });
  };

  const renderScreen = () => {
    if (navigationStack.length > 0) {
      const currentScreen =
        navigationStack[navigationStack.length - 1];

      switch (currentScreen) {
        case "customer-detail":
          return (
            <CustomerDetailScreen
              customer={selectedCustomer}
              onBack={navigateBack}
            />
          );
        default:
          return renderMainScreen();
      }
    }

    return renderMainScreen();
  };

  const renderMainScreen = () => {
    switch (activeTab) {
      case "dash":
        return <DashScreen />;
      case "sales":
        return (
          <SalesScreen
            onNavigateToCustomer={navigateToCustomerDetail}
          />
        );
      case "jobs":
        return <JobsScreen />;
      case "vault":
        return <VaultScreen />;
      case "tools":
        return <ToolsScreen />;
      default:
        return <DashScreen />;
    }
  };

  return (
    <div className="w-full h-screen flex justify-center bg-background overflow-hidden">
      <div
        className="w-full bg-background relative flex flex-col h-full overflow-hidden"
        style={{ maxWidth: "412px" }}
      >
        {/* Main content area */}
        <div className="flex-1 overflow-hidden">{renderScreen()}</div>

        {/* Bottom navigation with safe area */}
        {navigationStack.length === 0 && (
          <div className="flex-shrink-0 safe-area-bottom">
            <BottomNavigation
              activeTab={activeTab}
              onTabChange={setActiveTab}
            />
          </div>
        )}
      </div>
    </div>
  );
}