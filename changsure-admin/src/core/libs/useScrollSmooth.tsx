import { useEffect } from "react";
import Lenis from "@studio-freight/lenis";
import { gsap } from "gsap";
import { usePathname } from "next/navigation";

type LenisOptions = {
  duration: number;
  wheelMultiplier: number;
  lerp: number;
};

let lenisInstance: Lenis | null = null;

export const useScrollSmooth = () => {
  const pathname = usePathname();

  useEffect(() => {
    if (!lenisInstance) {
      lenisInstance = new Lenis({
        duration: 3.5,
        easing: (t) => Math.min(1, 1.001 - Math.pow(2, -15 * t)),
        orientation: "vertical",
        smoothWheel: true,
        wheelMultiplier: 0.5,
        lerp: 0.05,
      });

      lenisInstance.on("scroll", ({ scroll }: { scroll: number }) => {
        if (scroll <= 500) {
          (lenisInstance as any).options = {
            ...(lenisInstance as any).options,
            duration: 3.5,
            wheelMultiplier: 0.5,
            lerp: 0.05,
          };
        } else {
          (lenisInstance as any).options = {
            ...(lenisInstance as any).options,
            duration: 1.2,
            wheelMultiplier: 1,
            lerp: 0.1,
          };
        }
      });

      gsap.ticker.add((time) => {
        lenisInstance?.raf(time * 1000);
      });
    }

    window.scrollTo(0, 0);
    lenisInstance?.scrollTo(0, { immediate: true });

    return () => {
      if (lenisInstance) {
        lenisInstance.destroy();
        gsap.ticker.remove(lenisInstance.raf);
        lenisInstance = null;
      }
    };
  }, [pathname]);

  return {
    scrollTo: (target: number | string | HTMLElement) => {
      lenisInstance?.scrollTo(target);
    },
    lenis: lenisInstance,
  };
};
