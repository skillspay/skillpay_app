import ComplianceLayout from "../components/ComplianceLayout";

export default function TermsOfService() {
  const sections = [
    { id: "acceptance", title: "Acceptance of Terms" },
    { id: "marketplace", title: "Marketplace Description" },
    { id: "accounts", title: "Accounts & Registration" },
    { id: "escrow", title: "Escrow & Payment Terms" },
    { id: "cancellations", title: "Cancellations & Refunds" },
    { id: "conduct", title: "User Conduct & Prohibited Acts" },
    { id: "ip", title: "Intellectual Property" },
    { id: "liability", title: "Limitation of Liability" },
    { id: "governing", title: "Governing Law & Jurisdiction" },
  ];

  return (
    <ComplianceLayout
      title="Terms of Service"
      subtitle="Standard terms and conditions governing the use of SkillPay platform, web portal, and mobile applications."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="acceptance" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>Acceptance of Terms</span>
        </h2>
        <p className="text-gray-300">
          Welcome to SkillPay (&ldquo;SkillPay&rdquo;, &ldquo;we&rdquo;, &ldquo;our&rdquo;, or &ldquo;us&rdquo;). 
          By downloading, accessing, browsing, or using our website, customer mobile application, or artisan mobile application, 
          you agree to be legally bound by these Terms of Service and all related policies incorporated herein. 
          If you do not accept these terms without qualification, you must immediately cease accessing or using our services.
        </p>
      </section>

      <section id="marketplace" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>Marketplace Description</span>
        </h2>
        <p className="text-gray-300">
          SkillPay provides a technology-enabled marketplace connecting homeowners and corporate clients (&ldquo;Customers&rdquo;) 
          seeking home repairs, maintenance, and facility services with independent skilled tradespersons, technicians, and contractors (&ldquo;Artisans&rdquo;). 
          SkillPay does not directly perform or supervise manual trade work; Artisans operate as independent contractors responsible for their own services.
        </p>
      </section>

      <section id="accounts" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Accounts & Eligibility</span>
        </h2>
        <p className="text-gray-300">
          Users must be at least 18 years of age to register an account. You agree to provide accurate, current, and complete registration details 
          and keep credentials confidential. You are solely responsible for all activities conducted under your user credentials. 
          SkillPay reserves the right to suspend or deactivate accounts found to be fraudulent, abusive, or inactive.
        </p>
      </section>

      <section id="escrow" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Escrow & Payment Terms</span>
        </h2>
        <div className="space-y-3 text-gray-300">
          <p>
            To protect all marketplace participants, customer payments for booked work orders are deposited into a secure escrow hold. 
            Funds remain held in escrow while the Artisan executes the contracted scope of work.
          </p>
          <ul className="list-disc list-inside space-y-2 pl-2 text-gray-300">
            <li>Funds are automatically released upon Customer approval in the app.</li>
            <li>If Customer does not respond within 48 hours of Artisan completion upload and no dispute is filed, funds disburse automatically.</li>
            <li>Platform service fees and payment gateway processing fees are deducted at payout.</li>
          </ul>
        </div>
      </section>

      <section id="cancellations" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Cancellations & Refunds</span>
        </h2>
        <p className="text-gray-300">
          Bookings cancelled before Artisan departure are eligible for a full refund minus nominal processing costs. 
          If work has commenced or customized materials were purchased upon customer authorization, 
          escrow release is adjudicated based on documented milestone delivery or mutual written agreement.
        </p>
      </section>

      <section id="conduct" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">06.</span>
          <span>User Conduct & Prohibited Acts</span>
        </h2>
        <div className="space-y-3 text-gray-300">
          <p>Users agree not to engage in any of the following:</p>
          <ul className="list-disc list-inside space-y-1.5 pl-2 text-gray-400">
            <li>Circumventing platform payments by transacting off-platform to avoid fees.</li>
            <li>Harassing, discriminating against, or threatening any user or artisan.</li>
            <li>Submitting false identity documents or fraudulent payment instruments.</li>
            <li>Reverse engineering or scraping SkillPay software, APIs, or database records.</li>
          </ul>
        </div>
      </section>

      <section id="ip" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">07.</span>
          <span>Intellectual Property</span>
        </h2>
        <p className="text-gray-300">
          All brand assets, software code, graphic designs, algorithms, and trademarks associated with SkillPay 
          are the exclusive property of SkillPay and its licensors. No license is granted without explicit written consent.
        </p>
      </section>

      <section id="liability" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">08.</span>
          <span>Limitation of Liability</span>
        </h2>
        <p className="text-gray-300">
          To the maximum extent permitted by law, SkillPay will not be liable for any indirect, incidental, punitive, 
          or consequential damages, including loss of profits, data loss, property damage, or bodily injury resulting from third-party services.
        </p>
      </section>

      <section id="governing" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">09.</span>
          <span>Governing Law & Dispute Jurisdiction</span>
        </h2>
        <p className="text-gray-300">
          These Terms are governed by and construed in accordance with the laws of the jurisdiction in which SkillPay is incorporated. 
          Parties agree to first attempt good-faith mediation prior to commencing formal arbitration or court litigation.
        </p>
      </section>
    </ComplianceLayout>
  );
}
