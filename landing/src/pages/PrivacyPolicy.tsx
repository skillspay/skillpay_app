import ComplianceLayout from "../components/ComplianceLayout";

export default function PrivacyPolicy() {
  const sections = [
    { id: "collection", title: "Information We Collect" },
    { id: "usage", title: "How We Use Data" },
    { id: "geolocation", title: "Geolocation & Tracking" },
    { id: "sharing", title: "Data Sharing & Disclosures" },
    { id: "security", title: "Data Security & Storage" },
    { id: "retention", title: "Data Retention & Deletion" },
    { id: "rights", title: "Your Privacy Rights" },
    { id: "contact", title: "Contact Our DPO" },
  ];

  return (
    <ComplianceLayout
      title="Privacy Policy"
      subtitle="How SkillPay collects, processes, protects, and handles personal data across our web platform and mobile applications."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="collection" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>Information We Collect</span>
        </h2>
        <div className="space-y-3 text-gray-300">
          <p>We collect personal information necessary to deliver marketplace services, including:</p>
          <ul className="list-disc list-inside space-y-1.5 pl-2 text-gray-400">
            <li><strong className="text-white">Account Details:</strong> Full name, verified email, telephone number, and encrypted password.</li>
            <li><strong className="text-white">Verification Data:</strong> Government identity cards, business certificates, facial photographs (for artisans).</li>
            <li><strong className="text-white">Payment Records:</strong> Payment gateway tokens, payout bank details, and transaction invoices.</li>
            <li><strong className="text-white">Communication Records:</strong> In-app chat logs, customer care tickets, and call records.</li>
          </ul>
        </div>
      </section>

      <section id="usage" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>How We Use Data</span>
        </h2>
        <p className="text-gray-300">
          Personal data is used exclusively to facilitate customer-artisan matching, maintain escrow security, 
          prevent fraud, execute automated bank payouts, deliver status push notifications, and comply with legal regulatory obligations.
        </p>
      </section>

      <section id="geolocation" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Geolocation & Tracking</span>
        </h2>
        <p className="text-gray-300">
          With explicit permission, our mobile applications collect approximate and precise GPS coordinates 
          to identify nearest available artisans, calculate accurate transit times, and verify physical arrival on job sites. 
          You can toggle location permissions at any time through your operating system settings.
        </p>
      </section>

      <section id="sharing" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Data Sharing & Third Parties</span>
        </h2>
        <p className="text-gray-300">
          We do not sell personal information to advertising brokers. Data is shared strictly with:
        </p>
        <ul className="list-disc list-inside space-y-1.5 pl-2 text-gray-400 mt-2">
          <li>Counterparties to a confirmed booking (e.g. sharing service address with the dispatched artisan).</li>
          <li>Certified payment processors (Stripe, Paystack) for fund transfers and escrow management.</li>
          <li>Cloud hosting, security infrastructure, and push notification providers (Firebase, Supabase).</li>
          <li>Law enforcement agencies when mandated by binding judicial court subpoenas.</li>
        </ul>
      </section>

      <section id="security" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Data Security & Storage</span>
        </h2>
        <p className="text-gray-300">
          We employ bank-grade security protocols, including AES-256 encryption at rest, TLS 1.3 encryption in transit, 
          role-based access controls, and periodic automated vulnerability assessments.
        </p>
      </section>

      <section id="retention" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">06.</span>
          <span>Data Retention & Account Deactivation</span>
        </h2>
        <p className="text-gray-300">
          Account data is retained for the duration of your active account plus required statutory tax retention windows (e.g., 7 years for financial ledger entries). 
          Users may request account deactivation at any time via the mobile app settings or profile screen.
        </p>
      </section>

      <section id="rights" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">07.</span>
          <span>Your Privacy Rights</span>
        </h2>
        <p className="text-gray-300">
          Depending on your jurisdiction (GDPR, CCPA, NDPR), you possess rights to access your data, request rectification of inaccuracies, 
          request erasure, object to specific processing, and receive an export of your information in a portable format.
        </p>
      </section>

      <section id="contact" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">08.</span>
          <span>Contact Our Data Protection Officer</span>
        </h2>
        <p className="text-gray-300">
          For any data protection inquiries, email our Data Protection Officer at{" "}
          <a href="mailto:privacy@skillpay.com" className="text-yellow-400 underline">
            privacy@skillpay.com
          </a>.
        </p>
      </section>
    </ComplianceLayout>
  );
}
