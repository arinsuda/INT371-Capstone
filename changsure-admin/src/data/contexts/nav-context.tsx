"use client";
import { createContext, useContext, useState } from "react";

export enum NavSection {
  WELCOME = "welcome",
  WHO_WE_ARE = "who-we-are",
  CONTACT = "contact",
  OUR_PROJECT = "our-project",
}

interface NavContextType {
  isNavVisible: boolean;
  setIsNavVisible: (value: boolean) => void;
  scrollProgress: number;
  setScrollProgress: (value: number) => void;
  currentSection: NavSection | "";
  setCurrentSection: (value: NavSection | "") => void;
}

const NavContext = createContext<NavContextType>({
  isNavVisible: false,
  setIsNavVisible: () => {},
  scrollProgress: 0,
  setScrollProgress: () => {},
  currentSection: "",
  setCurrentSection: () => {},
});

export const NavProvider = ({ children }: { children: React.ReactNode }) => {
  const [isNavVisible, setIsNavVisible] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  const [currentSection, setCurrentSection] = useState<NavSection | "">("");

  return (
    <NavContext.Provider
      value={{
        isNavVisible,
        setIsNavVisible,
        scrollProgress,
        setScrollProgress,
        currentSection,
        setCurrentSection,
      }}
    >
      {children}
    </NavContext.Provider>
  );
};

export const useNav = () => useContext(NavContext);
