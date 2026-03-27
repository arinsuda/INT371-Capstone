"use client"

import { useState, useEffect } from "react"
import { ParallaxProvider } from "react-scroll-parallax"
import { NavProvider } from "@/data/contexts/nav-context"
import { SmoothScrollProvider } from "@/core/providers/smooth-scroll-provider"
import { QueryClientProvider } from "@tanstack/react-query"
import { queryClient } from "@/core/libs/react-query"

export function ClientProviders({ children }: { children: React.ReactNode }) {
  const [isMounted, setIsMounted] = useState(false)

  useEffect(() => {
    setIsMounted(true)
  }, [])

  return (
    <QueryClientProvider client={queryClient}>
      <ParallaxProvider>
        <NavProvider>
          <div className="flex-col flex justify-between">
            <SmoothScrollProvider>{children}</SmoothScrollProvider>
          </div>
        </NavProvider>
      </ParallaxProvider>
    </QueryClientProvider>
  )
}
