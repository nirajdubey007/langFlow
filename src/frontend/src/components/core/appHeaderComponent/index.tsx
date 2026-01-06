// Logos and header elements removed
import { CustomOrgSelector } from "@/customization/components/custom-org-selector";
import useTheme from "@/customization/hooks/use-custom-theme";
import FlowMenu from "./components/FlowMenu";

export default function AppHeader(): JSX.Element {
  useTheme();

  return (
    <div
      className={`z-10 flex h-[48px] w-full items-center justify-between border-b pr-5 pl-2.5 dark:bg-background`}
      data-testid="app-header"
    >
      {/* Left Section */}
      <div
        className={`z-30 flex shrink-0 items-center gap-2`}
        data-testid="header_left_section_wrapper"
      >
        {/* Logo removed */}
        {/* <Button
          unstyled
          onClick={() => navigate("/")}
          className="mr-1 flex h-8 w-8 items-center"
          data-testid="icon-ChevronLeft"
        >
          <LangflowLogo className="h-5 w-5" />
        </Button> */}
        <CustomOrgSelector />
      </div>

      {/* Middle Section */}
      <div className="absolute left-1/2 -translate-x-1/2">
        <FlowMenu />
      </div>

      {/* Right Section - Removed social icons, notifications, and account menu */}
      <div
        className={`relative left-3 z-30 flex shrink-0 items-center gap-3`}
        data-testid="header_right_section_wrapper"
      >
        {/* All header right elements removed */}
      </div>
    </div>
  );
}
