const logos = [
  'pier',
  'okta',
  'ATLASSIAN',
  'Deloitte.',
  'shopify',
]

const categories = [
  'Handymen',
  'Electrical',
  'HVAC',
  'Plumbing',
  'Flooring',
  'Lawn Care',
  'Painting',
  'Windows',
  'Appliances',
  'Remodeling',
  'Roofing',
  'Masseuse',
]

export default function ServicesSection() {
  return (
    <section className="bg-white text-gray-900 py-16 md:py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        <div className="space-y-6">
          <h3 className="text-sm uppercase tracking-wide text-gray-500 text-center">
            Trusted by top companies and contractors
          </h3>
          <div className="relative overflow-hidden max-w-4xl mx-auto">
            <div className="flex animate-scroll gap-12">
              {[...logos, ...logos].map((logo, index) => (
                <span
                  key={`${logo}-${index}`}
                  className="text-base font-semibold text-gray-400 whitespace-nowrap"
                >
                  {logo}
                </span>
              ))}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
          <div className="space-y-4">
            <h2 className="text-3xl md:text-4xl font-semibold leading-tight">
              Get the right local pro
              <br />
              for any home project.
            </h2>
          </div>

          <div className="text-gray-500 text-sm leading-relaxed max-w-xl">
            <p>
              From routine repairs and seasonal property maintenance to major renovations and commercial facility upgrades, SkillPay connects you directly with top-tier professionals ready to get the job done right.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          {categories.map((category) => (
            <div
              key={category}
              className="flex items-center gap-2 border border-gray-200 rounded-lg px-4 py-3 text-sm font-medium shadow-[0_1px_3px_rgba(0,0,0,0.04)]"
            >
              <span className="w-2 h-2 rounded-full bg-gray-300"></span>
              <span>{category}</span>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-gray-100 rounded-2xl p-6 md:p-8 flex flex-col justify-between">
            <div className="space-y-4">
              <h3 className="text-2xl font-semibold text-gray-900">
                For professional
                <br />
                skilled workers
              </h3>
              <p className="text-sm text-gray-600 leading-relaxed">
                Expand your reach, discover verified job opportunities near you, build your reputation, and receive guaranteed on-time payments through our protected escrow system.
              </p>
              <div>
                <button className="text-sm font-semibold text-gray-900 inline-flex items-center gap-2">
                  Register now
                  <span aria-hidden>→</span>
                </button>
              </div>
            </div>
            <div className="rounded-xl overflow-hidden mt-6">
              <img
                src="/hero3.jpg"
                alt="Professional worker"
                className="w-full h-72 sm:h-80 md:h-96 object-cover object-top"
              />
            </div>
          </div>

          <div className="bg-yellow-400 rounded-2xl p-6 md:p-8 flex flex-col justify-between">
            <div className="space-y-4">
              <h3 className="text-2xl font-semibold text-gray-900">
                For homeowners
                <br />
                and companies
              </h3>
              <p className="text-sm text-gray-800 leading-relaxed">
                Find and hire insured, pre-screened artisans for urgent repairs or planned projects with transparent pricing, live tracking, and guaranteed customer satisfaction.
              </p>
              <div>
                <button className="text-sm font-semibold text-gray-900 inline-flex items-center gap-2">
                  Get Started
                  <span aria-hidden>→</span>
                </button>
              </div>
            </div>
            <div className="rounded-xl overflow-hidden mt-6">
              <img
                src="/masseuse.jpg"
                alt="Homeowner working"
                className="w-full h-72 sm:h-80 md:h-96 object-cover object-top"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

