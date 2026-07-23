import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Required for Railway deployment — output standalone bundle
  output: "standalone",
};

export default nextConfig;
