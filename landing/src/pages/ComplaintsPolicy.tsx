import ComplianceLayout from "../components/ComplianceLayout";

export default function ComplaintsPolicy() {
  const sections = [
    { id: "philosophy", title: "Our Dispute Philosophy" },
    { id: "procedure", title: "Step-by-Step Complaint Procedure" },
    { id: "timelines", title: "Investigation Timelines" },
    { id: "appeals", title: "Escalation & Appeals" },
    { id: "contact-support", title: "Support Channels" },
  ];

  return (
    <ComplianceLayout
      title="Complaints & Dispute Policy"
      subtitle="Procedures for filing complaints, resolving workmanship disputes, and appealing escrow decisions on SkillPay."
      lastUpdated="September 2026"
      sections={sections}
    >
      <section id="philosophy" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">01.</span>
          <span>Our Dispute Philosophy</span>
        </h2>
        <p className="text-gray-300">
          At SkillPay, our goal is fair, prompt, and transparent resolution for both homeowners and skilled artisans. 
          Our escrow architecture ensures payments remain protected while disputes are investigated objectively using objective evidence.
        </p>
      </section>

      <section id="procedure" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">02.</span>
          <span>Step-by-Step Complaint Procedure</span>
        </h2>
        <div className="space-y-4">
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Step 1: Direct In-App Communication</h3>
            <p className="text-sm text-gray-300">
              Communicate concerns directly with your counterpart through the SkillPay in-app chat. Many discrepancies are resolved quickly via direct clarification.
            </p>
          </div>
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Step 2: Formal Dispute Lodgment</h3>
            <p className="text-sm text-gray-300">
              If unresolved, submit a formal dispute via the booking details screen within 48 hours of work completion. Attach photographs, receipts, and an explanation.
            </p>
          </div>
          <div className="bg-gray-800/60 p-4 rounded-xl border border-gray-700/60">
            <h3 className="font-bold text-white text-base mb-1">Step 3: Escrow Freeze & Evidence Review</h3>
            <p className="text-sm text-gray-300">
              Escrowed funds are automatically frozen. Our dispute mediation team requests rebuttals from the counterparty within 48 hours.
            </p>
          </div>
        </div>
      </section>

      <section id="timelines" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">03.</span>
          <span>Investigation Timelines</span>
        </h2>
        <ul className="list-disc list-inside space-y-2 pl-2 text-gray-300">
          <li><strong>Acknowledgment:</strong> Within 4 hours of dispute submission.</li>
          <li><strong>Evidence Gathering:</strong> Up to 48 hours for both parties.</li>
          <li><strong>Final Determination:</strong> Within 3 to 5 business days, resulting in full customer refund, full artisan payout, or split escrow disbursement.</li>
        </ul>
      </section>

      <section id="appeals" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">04.</span>
          <span>Escalation & Appeals</span>
        </h2>
        <p className="text-gray-300">
          Either party may appeal a dispute verdict within 5 business days by providing previously unavailable documentary evidence to our Senior Mediation Board. 
          Appellate determinations are final for platform escrow administration.
        </p>
      </section>

      <section id="contact-support" className="scroll-mt-28">
        <h2 className="text-xl md:text-2xl font-bold text-white mb-4 flex items-center space-x-2">
          <span className="text-yellow-400 font-mono text-lg">05.</span>
          <span>Support & Dispute Channels</span>
        </h2>
        <p className="text-gray-300">
          To report complaints, reach our compliance team at{" "}
          <a href="mailto:complaints@skillpay.com" className="text-yellow-400 underline">
            complaints@skillpay.com
          </a>{" "}
          or through the in-app Help & Support desk.
        </p>
      </section>
    </ComplianceLayout>
  );
}
