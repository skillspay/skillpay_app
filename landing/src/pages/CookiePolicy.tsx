import ComplianceLayout from "../components/ComplianceLayout";

export default function CookiePolicy() {
  const sections = [
    { id: "what-are-cookies", title: "What Are Cookies" },
    { id: "types-used", title: "Types of Cookies We Use" },
    { id: "third-party", title: "Third-Party Cookies" },
    { id: "managing", title: "Managing & Opting Out" },
    { id: "updates", title: "Updates to This Policy" },
  ];

  return (
    <ComplianceLayout
      title="Cookie Policy"
      subtitle="Details regarding how SkillPay uses cookies, local storage, and related tracking technologies to improve our platform experience."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="what-are-cookies" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>What Are Cookies</span>
        </h2>
        <p className="text-gray-300">
          Cookies are small text data files placed on your browser or device when you visit our website or use our web application. 
          They allow us to recognize your device, remember preferences, maintain secure login sessions, and evaluate site performance.
        </p>
      </section>

      <section id="types-used" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>Types of Cookies We Use</span>
        </h2>
        <div className="space-y-4">
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Strictly Necessary Cookies</h3>
            <p className="text-sm text-gray-300">
              Essential for authentication, security tokens, account routing, and session persistence. Without these, the web platform cannot function.
            </p>
          </div>
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Performance & Analytics Cookies</h3>
            <p className="text-sm text-gray-300">
              Collect aggregated, anonymized metrics on page traffic, load latencies, and conversion funnels to help us optimize speed and usability.
            </p>
          </div>
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Functional Preferences</h3>
            <p className="text-sm text-gray-300">
              Store localized choices such as preferred language, currency, and collapsed sidebars.
            </p>
          </div>
        </div>
      </section>

      <section id="third-party" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Third-Party Analytics & Services</span>
        </h2>
        <p className="text-gray-300">
          We may permit trusted technical partners such as Google Analytics, Stripe, or CDN providers to set cookies 
          for fraud mitigation and service telemetry. These third parties adhere to independent data protection standards.
        </p>
      </section>

      <section id="managing" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Managing & Opting Out</span>
        </h2>
        <p className="text-gray-300">
          You can restrict or block cookies through your browser settings (Chrome, Safari, Firefox, Edge). 
          Please note that disabling strictly necessary cookies will prevent login sessions and checkout flows from operating correctly.
        </p>
      </section>

      <section id="updates" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Updates to This Policy</span>
        </h2>
        <p className="text-gray-300">
          We may periodically update this Cookie Policy. Substantial changes will be reflected with a revised &ldquo;Last updated&rdquo; timestamp.
        </p>
      </section>
    </ComplianceLayout>
  );
}
