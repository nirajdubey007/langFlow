import { create } from "zustand";
// API imports removed - no longer fetching Discord/GitHub data
import type { DarkStoreType } from "../types/zustand/dark";

const startedStars = Number(window.localStorage.getItem("githubStars")) ?? 0;

export const useDarkStore = create<DarkStoreType>((set, get) => ({
  dark: true, // Always dark theme
  stars: startedStars,
  version: "",
  latestVersion: "",
  refreshLatestVersion: (v: string) => {
    set(() => ({ latestVersion: v }));
  },
  setDark: (dark) => {
    // Always set to dark theme, ignore the input
    set(() => ({ dark: true }));
    window.localStorage.setItem("isDark", "true");
  },
  refreshVersion: (v) => {
    set(() => ({ version: v }));
  },
  refreshStars: () => {
    // API calls disabled - no longer fetching GitHub stars
      return;
  },
  discordCount: 0,
  refreshDiscordCount: () => {
    // API calls disabled - no longer fetching Discord count
    return;
  },
}));
