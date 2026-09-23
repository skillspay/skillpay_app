import React from "react";
import Footer from "./Footer";

interface TableOfContentItem {
  id: string;
  title: string;
}

interface ComplianceLayoutProps {
  title: string;
  subtitle: string;
  lastUpdated: string;
  sections: TableOfContentItem[];
  children: React.ReactNode;
}

export default function ComplianceLayout({
  title,
  subtitle,
  lastUpdated,
  sections,
  children,
}: ComplianceLayoutProps) {
  const scrollToSection = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100 flex flex-col font-sans">
      {/* Top Header / Nav Bar */}
      <header className="sticky top-0 z-40 bg-black/80 backdrop-blur-md border-b border-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3.5 flex justify-between items-center">
          <a href="#home" className="flex items-center space-x-2">
            <img
              src="/logo.png"
              alt="SkillPay"
              className="h-9 w-auto object-contain"
            />
          </a>

          <div className="flex items-center space-x-4">
            <a
              href="#home"
              className="text-sm font-medium text-gray-300 hover:text-white flex items-center space-x-1.5 transition-colors"
            >
              <svg
                className="w-4 h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M10 19l-7-7m0 0l7-7m-7 7h18"
                />
              </svg>
              <span>Back to Home</span>
            </a>
          </div>
        </div>
      </header>

      {/* Hero Banner */}
      <div className="bg-gradient-to-b from-black to-gray-900 border-b border-gray-800 py-12 md:py-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center md:text-left">
          <div className="inline-flex items-center space-x-2 bg-yellow-400/10 border border-yellow-400/20 px-3 py-1 rounded-full text-yellow-400 text-xs font-semibold uppercase tracking-wider mb-4">
            <span className="w-1.5 h-1.5 rounded-full bg-yellow-400"></span>
            <span>SkillPay Legal & Compliance</span>
          </div>
          <h1 className="text-3xl md:text-5xl font-extrabold text-white tracking-tight">
            {title}
          </h1>
          <p className="mt-3 text-base md:text-lg text-gray-400 max-w-2xl">
            {subtitle}
          </p>
          <div className="mt-6 flex flex-wrap items-center gap-4 text-xs text-gray-400">
            <span className="bg-gray-800/80 px-3 py-1 rounded-md border border-gray-700">
              Last updated: {lastUpdated}
            </span>
            <span className="bg-gray-800/80 px-3 py-1 rounded-md border border-gray-700">
              Status: Active & Binding
            </span>
          </div>
        </div>
      </div>

      {/* Main Content Area with Sidebar Table of Contents */}
      <div className="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 md:py-14 w-full">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
          {/* Sticky Table of Contents (Desktop) */}
          <aside className="hidden lg:block lg:col-span-3">
            <div className="sticky top-24 bg-gray-800/40 border border-gray-800 rounded-xl p-5 backdrop-blur-sm">
              <h2 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">
                Contents
              </h2>
              <nav className="space-y-1">
                {sections.map((sec, idx) => (
                  <button
                    key={sec.id}
                    onClick={() => scrollToSection(sec.id)}
                    className="w-full text-left px-2.5 py-1.5 rounded-lg text-xs font-medium text-gray-400 hover:text-white hover:bg-gray-800 transition-colors flex items-center space-x-2"
                  >
                    <span className="text-yellow-400/60 font-mono text-[11px]">
                      0{idx + 1}.
                    </span>
                    <span className="truncate">{sec.title}</span>
                  </button>
                ))}
              </nav>

              <div className="mt-6 pt-5 border-t border-gray-800 text-xs text-gray-400 space-y-2">
                <p className="font-semibold text-gray-300">Need clarification?</p>
                <p className="text-gray-400 text-[11px] leading-relaxed">
                  Questions regarding our policies? Contact our legal counsel at{" "}
                  <a
                    href="mailto:legal@skillpay.com"
                    className="text-yellow-400 hover:underline"
                  >
                    legal@skillpay.com
                  </a>
                </p>
              </div>
            </div>
          </aside>

          {/* Document Content */}
          <main className="lg:col-span-9 bg-gray-800/20 border border-gray-800/80 rounded-2xl p-6 sm:p-10 md:p-12 shadow-xl backdrop-blur-sm">
            <div className="space-y-10 text-gray-300 leading-relaxed text-sm md:text-base">
              {children}
            </div>
          </main>
        </div>
      </div>

      {/* Footer */}
      <Footer />
    </div>
  );
}
