import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",

  assetPrefix: "/capstone25/cp25ssa1", 

  images: {
    domains: ["i.pravatar.cc", "picsum.photos"],
  },
};

export default nextConfig;