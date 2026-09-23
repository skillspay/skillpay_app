import ComplianceLayout from "../components/ComplianceLayout";

export default function DisclaimerPage() {
  const sections = [
    { id: "intermediary", title: "Technology Intermediary Disclaimer" },
    { id: "no-guarantee", title: "No Warranty of Services" },
    { id: "screening", title: "Background & Credentials Disclaimer" },
    { id: "safety", title: "Job Site Safety & Hazardous Work" },
    { id: "liability-cap", title: "Damages & Financial Cap" },
  ];

  return (
    <ComplianceLayout
      title="Legal Disclaimers & Compliance"
      subtitle="Important legal limitations, marketplace intermediary notices, and warranty exclusions for SkillPay users."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="intermediary" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>Technology Intermediary Disclaimer</span>
        </h2>
        <p className="text-gray-300">
          SkillPay is a technology platform that enables peer-to-peer contracting between independent Customers and independent Artisans. 
          SkillPay does not own, manage, or operate manual contracting companies, electrical installations, plumbing services, or cleaning agencies. 
          Artisans are not employees, agents, or subcontractors of SkillPay.
        </p>
      </section>

      <section id="no-guarantee" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>No Warranty of Third-Party Work</span>
        </h2>
        <p className="text-gray-300">
          All services booked through SkillPay are provided on an &ldquo;as is&rdquo; and &ldquo;as available&rdquo; basis. 
          While SkillPay operates an escrow protection mechanism to withhold customer funds until completion verification, 
          SkillPay disclaims all express or implied warranties regarding artisan skill level, punctuality, fitness for a particular purpose, or perfection of trade output.
        </p>
      </section>

      <section id="screening" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Background & Credentials Disclosure</span>
        </h2>
        <p className="text-gray-300">
          SkillPay conducts electronic identity verification and qualification audits during artisan onboarding. 
          However, SkillPay does not warrant the continuous accuracy of public criminal databases or trade registry checks. 
          Customers are advised to exercise reasonable caution, verify physical identification upon arrival, and supervise residential work.
        </p>
      </section>

      <section id="safety" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Job Site Safety & Hazardous Work</span>
        </h2>
        <p className="text-gray-300">
          Neither Customers nor Artisans should request or perform illegal, hazardous, or unpermitted tasks violating local building regulations. 
          SkillPay disclaims all liability for accidental property damage, structural collapse, electrical fires, or injuries occurring during on-site activities.
        </p>
      </section>

      <section id="liability-cap" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Limitation of Damages & Financial Cap</span>
        </h2>
        <p className="text-gray-300">
          To the maximum extent permissible under applicable legal statutes, SkillPay&rsquo;s total aggregate liability arising out of 
          or related to any job dispute or platform interaction shall be strictly limited to the total platform service fee received 
          by SkillPay for the specific booking in dispute.
        </p>
      </section>
    </ComplianceLayout>
  );
}
