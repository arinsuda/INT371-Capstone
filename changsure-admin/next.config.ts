import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  basePath: "/capstone25/cp25ssa1",
  assetPrefix: "/capstone25/cp25ssa1",
  images: {
    domains: ["i.pravatar.cc", "picsum.photos"],
  },
};

export default nextConfig;