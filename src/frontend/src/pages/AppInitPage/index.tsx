import { useEffect, useState } from "react";
import { Outlet } from "react-router-dom";
import { useGetAutoLogin } from "@/controllers/API/queries/auth";
import { useGetConfig } from "@/controllers/API/queries/config/use-get-config";
import { useGetBasicExamplesQuery } from "@/controllers/API/queries/flows/use-get-basic-examples";
import { useGetFoldersQuery } from "@/controllers/API/queries/folders/use-get-folders";
import { useGetTagsQuery } from "@/controllers/API/queries/store";
import { useGetGlobalVariables } from "@/controllers/API/queries/variables";
import { useGetVersionQuery } from "@/controllers/API/queries/version";
import { CustomLoadingPage } from "@/customization/components/custom-loading-page";
import { useCustomPrimaryLoading } from "@/customization/hooks/use-custom-primary-loading";
// useDarkStore import removed - no longer fetching Discord/GitHub data
import useFlowsManagerStore from "@/stores/flowsManagerStore";
import { LoadingPage } from "../LoadingPage";

export function AppInitPage() {
  // API calls disabled - no longer fetching Discord/GitHub data
  // const refreshStars = useDarkStore((state) => state.refreshStars);
  // const refreshDiscordCount = useDarkStore(
  //   (state) => state.refreshDiscordCount,
  // );
  const isLoading = useFlowsManagerStore((state) => state.isLoading);
  const [forceProceed, setForceProceed] = useState(false);

  // Add timeout to prevent infinite loading - proceed after 2 seconds
  useEffect(() => {
    const timer = setTimeout(() => {
      console.log("Force proceeding after timeout");
      setForceProceed(true);
    }, 2000); // 2 second timeout

    return () => clearTimeout(timer);
  }, []);

  const { isFetched: isLoaded } = useCustomPrimaryLoading();

  const { isFetched: isAutoLoginFetched, isError: isAutoLoginError } = useGetAutoLogin({ enabled: isLoaded });
  const isFetched = isAutoLoginFetched || isAutoLoginError; // Proceed even if auto-login fails
  
  useEffect(() => {
    console.log("Loading state:", {
      isLoaded,
      isAutoLoginFetched,
      isAutoLoginError,
      isFetched,
      forceProceed
    });
  }, [isLoaded, isAutoLoginFetched, isAutoLoginError, isFetched, forceProceed]);
  
  useGetVersionQuery({ enabled: isFetched });
  const { isFetched: isConfigFetched, isError: isConfigError } = useGetConfig({ enabled: isFetched });
  useGetGlobalVariables({ enabled: isFetched });
  useGetTagsQuery({ enabled: isFetched });
  useGetFoldersQuery({ enabled: isFetched });
  const { isFetched: isExamplesFetched, isError: isExamplesError, refetch: refetchExamples } =
    useGetBasicExamplesQuery();

  useEffect(() => {
    // API calls disabled
    // if (isFetched) {
    //   refreshStars();
    //   refreshDiscordCount();
    // }

    if (isConfigFetched || isConfigError) {
      refetchExamples();
    }
  }, [isFetched, isConfigFetched, isConfigError, refetchExamples]);

  // Allow app to proceed even if some queries fail - only wait for auto-login
  // Also allow proceeding after timeout
  const canProceed = forceProceed || (isFetched && (isExamplesFetched || isExamplesError || isConfigFetched || isConfigError));

  // More lenient loading condition - don't wait forever
  const shouldShowLoading = !forceProceed && (isLoaded 
    ? (isLoading && isFetched) || (!isFetched && !isAutoLoginError) || (!isExamplesFetched && !isExamplesError && !isConfigFetched && !isConfigError)
    : true);

  return (
    //need parent component with width and height
    <>
      {shouldShowLoading ? (
        isLoaded ? (
          <LoadingPage overlay />
        ) : (
          <CustomLoadingPage />
        )
      ) : null}
      {canProceed && <Outlet />}
    </>
  );
}
