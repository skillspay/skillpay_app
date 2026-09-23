import ComplianceLayout from "../components/ComplianceLayout";

export default function ArtisanTerms() {
  const sections = [
    { id: "relationship", title: "Independent Contractor Relationship" },
    { id: "credentials", title: "Registration & Credentials Verification" },
    { id: "fees", title: "Service Fees & Payout Schedules" },
    { id: "quality", title: "Workmanship & Professional Standards" },
    { id: "safety", title: "Safety, Equipment & Insurance" },
    { id: "disputes", title: "Escrow Adjudication & Disputes" },
    { id: "suspension", title: "Deactivation & Suspension" },
  ];

  return (
    <ComplianceLayout
      title="Artisan Terms of Service"
      subtitle="Specific contractual terms, obligations, payout policies, and service standards governing registered workers and artisans on SkillPay."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="relationship" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>Independent Contractor Relationship</span>
        </h2>
        <p className="text-gray-300">
          You expressly acknowledge and agree that your legal status on the SkillPay platform is that of an independent freelance service contractor. 
          Nothing in this agreement constitutes an employer-employee relationship, agency, partnership, or joint venture between SkillPay and you. 
          You retain full discretion over your working hours, acceptable job proposals, and trade methodologies.
        </p>
      </section>

      <section id="credentials" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>Registration & Credentials Verification</span>
        </h2>
        <p className="text-gray-300">
          To maintain marketplace trust, Artisans must complete mandatory identity verification, background screening, 
          and provide valid trade certifications or references. Providing fraudulent documentation or impersonating another tradesperson 
          results in immediate account revocation, escrow forfeiture, and potential civil or criminal referral.
        </p>
      </section>

      <section id="fees" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Service Fees & Payout Schedules</span>
        </h2>
        <div className="space-y-3 text-gray-300">
          <p>
            Customer payments are held in escrow until job sign-off. SkillPay deducts an agreed marketplace platform commission 
            from each completed milestone to cover platform hosting, customer discovery, escrow maintenance, and payment processing fees.
          </p>
          <ul className="list-disc list-inside space-y-1.5 pl-2 text-gray-400">
            <li>Completed funds are automatically swept to your linked bank account within 24–48 business hours.</li>
            <li>Artisans are responsible for all personal, local, and national income taxes on received disbursements.</li>
          </ul>
        </div>
      </section>

      <section id="quality" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Workmanship & Professional Standards</span>
        </h2>
        <p className="text-gray-300">
          Artisans agree to arrive promptly, communicate respectfully, adhere to building safety codes, 
          and provide a minimum 14-day warranty against defects in manual workmanship for all completed projects.
        </p>
      </section>

      <section id="safety" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Safety, Equipment & Insurance</span>
        </h2>
        <p className="text-gray-300">
          You are responsible for supplying your own commercial-grade tools, personal protective equipment (PPE), and safety gear. 
          SkillPay strongly recommends maintaining comprehensive third-party public liability insurance appropriate for your trade.
        </p>
      </section>

      <section id="disputes" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">06.</span>
          <span>Escrow Adjudication & Disputes</span>
        </h2>
        <p className="text-gray-300">
          If a customer initiates a formal dispute alleging non-completion or substandard work, you must provide photo/video proof 
          and itemized task logs within 48 hours. SkillPay dispute resolution teams will mediate and issue binding escrow determinations.
        </p>
      </section>

      <section id="suspension" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">07.</span>
          <span>Deactivation & Suspension</span>
        </h2>
        <p className="text-gray-300">
          SkillPay may suspend or terminate an Artisan profile for repeated low ratings (below 3.5 stars), 
          unjustified job cancellations, solicitation of off-platform payments, or abusive interactions.
        </p>
      </section>
    </ComplianceLayout>
  );
}
