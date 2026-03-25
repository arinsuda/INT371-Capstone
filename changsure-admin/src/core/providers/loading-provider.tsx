"use client";
import React, { createContext, useContext, useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

interface LoadingContextType {
  isLoading: boolean;
  setIsLoading: (loading: boolean) => void;
}

const LoadingContext = createContext<LoadingContextType | undefined>(undefined);

export function LoadingProvider({ children }: { children: React.ReactNode }) {
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1500);

    return () => clearTimeout(timer);
  }, []);

  return (
    <LoadingContext.Provider value={{ isLoading, setIsLoading }}>
      <AnimatePresence mode="wait">
        {isLoading ? (
          <motion.div
            className="fixed inset-0 flex items-center justify-center bg-navy-primary z-50"
            initial={{ y: 0 }}
            animate={{ y: 0 }}
            exit={{
              y: "-100%",
              transition: {
                duration: 0.8,
                ease: [0.22, 1, 0.36, 1],
              },
            }}
          >
            <motion.div
              initial={{ scale: 0.5, opacity: 0 }}
              animate={{
                scale: 1,
                opacity: 1,
                transition: {
                  duration: 0.3,
                },
              }}
              className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-white-900"
            />
          </motion.div>
        ) : (
          <motion.div
            initial={{ paddingTop: 0 }}
            animate={{
              paddingTop: 70,
              transition: {
                duration: 0.5,
                ease: [0.22, 1, 0.36, 1],
              },
            }}
          >
            {children}
          </motion.div>
        )}
      </AnimatePresence>
    </LoadingContext.Provider>
  );
}

export const useLoading = () => {
  const context = useContext(LoadingContext);
  if (context === undefined) {
    throw new Error("useLoading must be used within a LoadingProvider");
  }
  return context;
};
