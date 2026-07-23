export default function Header() {
  return (
    <header className="bg-black min-h-screen flex items-center">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full pt-20 md:pt-0 md:-mt-24">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left Side - Content */}
          <div className="space-y-8">
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-yellow-400 rounded-full"></div>
              <span className="text-white text-sm">
                Connecting artisans to homeowners →
              </span>
            </div>

            <h1 className="text-5xl md:text-6xl font-bold text-white leading-tight">
              Find professional skilled workers on SkillPay.
            </h1>

            <p className="text-white text-lg md:text-xl text-gray-300">
              We provide trained professionals for ongoing maintenance,
              workforce support, and large-scale projects.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 pt-4">
              <button className="bg-yellow-400 text-gray-900 px-6 py-3 rounded-lg font-semibold hover:bg-yellow-300 transition-colors flex items-center justify-center space-x-2">
                <svg
                  className="w-6 h-6"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.5,12.92 20.16,13.19L6.05,21.34L14.54,12.85L20.16,10.81M20.16,10.81L14.54,12.85L6.05,4.66L20.16,10.81Z" />
                </svg>
                <span>GET IT ON Google Play</span>
              </button>

              <button className="bg-gray-800 text-white px-6 py-3 rounded-lg font-semibold hover:bg-gray-700 transition-colors flex items-center justify-center space-x-2">
                <svg
                  className="w-6 h-6"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                >
                  <path d="M18.71,19.5C17.88,20.74 17,21.95 15.66,21.97C14.32,22 13.89,21.18 12.37,21.18C10.84,21.18 10.37,21.95 9.1,22C7.79,22.05 6.8,20.68 5.96,19.47C4.25,17 2.94,12.45 4.7,9.39C5.57,7.87 7.13,6.91 8.82,6.88C10.1,6.86 11.32,7.75 12.11,7.75C12.89,7.75 14.37,6.68 15.92,6.84C16.57,6.87 18.39,7.1 19.56,8.82C19.47,8.88 17.39,10.1 17.41,12.63C17.44,15.65 20.06,16.66 20.09,16.67C20.06,16.74 19.67,18.11 18.71,19.5M13,3.5C13.73,2.67 14.94,2.04 15.94,2C16.07,3.17 15.6,4.35 14.9,5.19C14.21,6.04 13.07,6.7 11.95,6.61C11.8,5.46 12.36,4.26 13,3.5Z" />
                </svg>
                <span>Download on the App Store</span>
              </button>
            </div>
          </div>

          {/* Right Side - Image Grid */}
          <div className="grid grid-cols-2 gap-4 max-w-lg">
            <div className="-mt-6 space-y-4">
              {["hero1.jpg", "hero3.jpg"].map((src) => (
                <div
                  key={src}
                  className="rounded-lg overflow-hidden aspect-square"
                >
                  <img
                    src={`/${src}`}
                    alt="Skilled worker"
                    className="w-full h-full object-cover"
                  />
                </div>
              ))}
            </div>
            <div className="mt-6 space-y-4">
              {["hero2.jpg", "hero4.jpg"].map((src) => (
                <div
                  key={src}
                  className="rounded-lg overflow-hidden aspect-square"
                >
                  <img
                    src={`/${src}`}
                    alt="Skilled worker"
                    className="w-full h-full object-cover"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
