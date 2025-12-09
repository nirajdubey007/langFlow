// Custom Hook to manage theme logic

import { useEffect, useState } from "react";
import { useDarkStore } from "@/stores/darkStore";

const useTheme = () => {
  const [systemTheme, setSystemTheme] = useState(false);
  const { setDark, dark } = useDarkStore((state) => ({
    setDark: state.setDark,
    dark: state.dark,
  }));

  const handleSystemTheme = () => {
    if (typeof window !== "undefined") {
      const systemDarkMode = window.matchMedia(
        "(prefers-color-scheme: dark)",
      ).matches;
      setDark(systemDarkMode);
    }
  };

  useEffect(() => {
    // Always force dark mode - ignore localStorage and system preferences
    setDark(true);
    setSystemTheme(false);
    localStorage.setItem("themePreference", "dark");
    localStorage.setItem("isDark", "true");
  }, []);

  useEffect(() => {
    // Disabled system theme listener - always dark mode
    // No need to listen to system theme changes
  }, [systemTheme]);

  const setThemePreference = (theme) => {
    // Always force dark mode regardless of theme parameter
    setDark(true);
    setSystemTheme(false);
    localStorage.setItem("themePreference", "dark");
    localStorage.setItem("isDark", "true");
  };

  return { systemTheme, dark, setThemePreference };
};

export default useTheme;
