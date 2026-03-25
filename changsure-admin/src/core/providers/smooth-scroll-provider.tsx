"use client";
import { useScrollSmooth } from "@/core/libs/useScrollSmooth";
import { useEffect } from "react";

export const SmoothScrollProvider = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  // useScrollSmooth();
  return <>{children}</>;
};
