"use client";

import * as React from "react";
import * as SwitchPrimitive from "@radix-ui/react-switch@1.1.3";
import { cn } from "./utils";

const Switch = React.forwardRef<
  React.ElementRef<typeof SwitchPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof SwitchPrimitive.Root>
>(({ className, ...props }, ref) => (
  <SwitchPrimitive.Root
    className={cn(
      // Material Design 3 Track: 52dp x 32dp
      "peer inline-flex h-1 w-[32px] shrink-0 cursor-pointer items-center transition-colors",
      "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",
      "disabled:cursor-not-allowed disabled:opacity-50",
      // M3 Colors: Outline when unchecked, Primary when checked
      "data-[state=unchecked]:bg-switch-background data-[state=checked]:bg-primary",
      // M3 Track border
      "data-[state=unchecked]:border-2 data-[state=unchecked]:border-muted-foreground data-[state=checked]:border-0",
      className,
    )}
    {...props}
    ref={ref}
  >
    <SwitchPrimitive.Thumb
      className={cn(
        // Material Design 3 Thumb: 16dp unselected, 24dp selected
        "pointer-events-none block rounded-full bg-white shadow-md transition-all",
        // Unselected state: 16dp thumb with 8dp offset from edge
        "data-[state=unchecked]:h-4 data-[state=unchecked]:w-4 data-[state=unchecked]:translate-x-2",
        // Selected state: 24dp thumb with 4dp offset from edge
        "data-[state=checked]:h-6 data-[state=checked]:w-6 data-[state=checked]:translate-x-6",
      )}
    />
  </SwitchPrimitive.Root>
));

Switch.displayName = SwitchPrimitive.Root.displayName;

export { Switch };