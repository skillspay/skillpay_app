const trustPills = [
  "Licensed technicians",
  "24/7 emergency service",
  "No hidden costs",
]

const stats = [
  { value: "270", suffix: "K", label: "Jobs completed" },
  { value: "52", suffix: "+", label: "Industry awards" },
  { value: "10", suffix: "+", label: "Years experience" },
  { value: "95", suffix: "%", label: "Customer satisfaction" },
]

const featureList = [
  {
    title: "Job Tracking",
    body: "Monitor project milestones, technician arrival times, and task completion status in real time.",
  },
  {
    title: "Repair History",
    body: "Access digital logs, high-resolution before-and-after photos, and itemized receipts for every service.",
  },
  {
    title: "Payments",
    body: "Protected milestone escrow ensures funds are only disbursed once you inspect and approve the completed job.",
  },
  {
    title: "Insurance & Guarantees",
    body: "Rest easy knowing jobs are covered with on-site insurance protection and our 100% SkillPay Guarantee.",
  },
]

function CheckIcon() {
  return (
    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-black text-white">
      <svg
        width="14"
        height="14"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          d="M20 6L9 17L4 12"
          stroke="currentColor"
          strokeWidth="2.2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    </span>
  )
}

export default function TrustSection() {
  return (
    <section className="bg-white text-gray-900 py-20 md:py-28">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-semibold tracking-tight">
            Built on trust and
            <br />
            proven results
          </h2>
          <p className="mt-5 text-gray-500 text-base md:text-lg">
            With 10+ years of experience, we connect home owners to artisans
            solutions backed by honest service and expert care.
          </p>

          <div className="mt-10 flex flex-wrap justify-center gap-3">
            {trustPills.map((pill) => (
              <div
                key={pill}
                className="inline-flex items-center gap-3 rounded-full border border-yellow-300 bg-yellow-50 px-5 py-2 text-sm font-semibold text-gray-900"
              >
                <CheckIcon />
                <span>{pill}</span>
              </div>
            ))}
          </div>

          <div className="mt-14 grid grid-cols-2 md:grid-cols-4 gap-10">
            {stats.map((s) => (
              <div key={s.label} className="text-center">
                <div className="text-4xl md:text-5xl font-semibold tracking-tight">
                  {s.value}
                  <span className="text-yellow-500"> {s.suffix}</span>
                </div>
                <div className="mt-2 text-sm text-gray-500">{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-24 grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div>
            <h3 className="text-4xl md:text-5xl font-semibold leading-tight">
              Find skilled workers
              <br />
              for your home or
              <br />
              business
            </h3>

            <div className="mt-12 grid grid-cols-1 sm:grid-cols-2 gap-10">
              {featureList.map((f) => (
                <div key={f.title} className="space-y-3">
                  <div className="flex items-center gap-3">
                    <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-green-600">
                      <svg
                        width="12"
                        height="12"
                        viewBox="0 0 24 24"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path
                          d="M20 6L9 17L4 12"
                          stroke="white"
                          strokeWidth="2.2"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        />
                      </svg>
                    </span>
                    <p className="font-semibold text-gray-900">{f.title}</p>
                  </div>
                  <p className="text-sm leading-relaxed text-gray-500">
                    {f.body}
                  </p>
                </div>
              ))}
            </div>
          </div>

          <div className="flex justify-center lg:justify-end">
            <div className="rounded-2xl p-8 md:p-10 w-full max-w-xl flex items-center justify-center">
              <div className="w-full max-w-[320px]">
                <div className="rounded-[2.6rem] bg-gray-900 p-2 shadow-2xl">
                  <div className="rounded-[2.2rem] overflow-hidden bg-black aspect-[9/19]">
                    <img
                      src="/hero2.jpg"
                      alt="SkillPay app preview"
                      className="w-full h-full object-cover"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}


