import { useEffect, useState } from "react";

const links = [
  { href: "#home", label: "Home" },
  { href: "#about", label: "About us" },
  { href: "#pricing", label: "Pricing" },
  { href: "#features", label: "Features" },
];

const Nav = () => {
  const [active, setActive] = useState("#home");
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const updateActive = () => {
      setActive(window.location.hash || "#home");
    };

    updateActive();
    window.addEventListener("hashchange", updateActive);
    return () => window.removeEventListener("hashchange", updateActive);
  }, []);

  const linkClass = (href: string) =>
    active === href
      ? "text-white font-semibold"
      : "text-gray-400 hover:text-white";

  const toggleMobileMenu = () => {
    setIsMobileMenuOpen(!isMobileMenuOpen);
  };

  const closeMobileMenu = () => {
    setIsMobileMenuOpen(false);
  };

  return (
    <>
      <nav className="bg-black relative z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <div className="flex items-center space-x-2">
                <img
                  src="/logo.png"
                  alt="Skill Pay"
                  className="h-12 w-12 md:h-10 md:w-10"
                />
              </div>
            </div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className={`${linkClass(link.href)} transition-colors`}
                >
                  {link.label}
                </a>
              ))}
            </div>

            {/* Desktop Buttons */}
            <div className="hidden md:flex items-center space-x-4">
              <button className="text-gray-400 hover:text-white transition-colors">
                Login
              </button>
              <button className="bg-gray-800 text-white px-6 py-2 rounded-lg hover:bg-gray-700 transition-colors">
                Join SkillPay
              </button>
            </div>

            {/* Mobile Menu Button */}
            <button
              onClick={toggleMobileMenu}
              className="md:hidden text-white p-2 z-50 relative"
              aria-label="Toggle menu"
            >
              {isMobileMenuOpen ? (
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              ) : (
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              )}
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile Menu Overlay */}
      {isMobileMenuOpen && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-black/50 z-40 md:hidden"
            onClick={closeMobileMenu}
          />
          {/* Menu */}
          <div className="fixed inset-x-0 top-16 bg-black z-50 md:hidden border-t border-gray-800">
            <div className="px-4 pt-4 pb-6 space-y-1">
              {links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={closeMobileMenu}
                  className={`${linkClass(
                    link.href
                  )} block px-3 py-2 rounded-md text-base transition-colors`}
                >
                  {link.label}
                </a>
              ))}
              <div className="pt-4 space-y-2">
                <button
                  onClick={closeMobileMenu}
                  className="w-full text-left text-gray-400 hover:text-white px-3 py-2 rounded-md transition-colors"
                >
                  Login
                </button>
                <button
                  onClick={closeMobileMenu}
                  className="w-full bg-gray-800 text-white px-3 py-2 rounded-lg hover:bg-gray-700 transition-colors"
                >
                  Join SkillPay
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
};

export default Nav;
