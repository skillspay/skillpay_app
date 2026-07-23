import { useMemo, useState } from "react"

type Testimonial = {
  quote: string
  name: string
  title: string
}

type FaqItem = {
  question: string
  answer: string
}

function PlusIcon({ open }: { open: boolean }) {
  return (
    <span className="inline-flex items-center justify-center w-10 h-10 rounded-lg border border-gray-200 bg-white text-gray-900">
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className={`transition-transform duration-200 ${open ? "rotate-45" : ""}`}
      >
        <path
          d="M12 5V19"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
        <path
          d="M5 12H19"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </svg>
    </span>
  )
}

export default function TestimonialsFaqSection() {
  const testimonials: Testimonial[] = useMemo(
    () => [
      {
        quote:
          "A wonderful experience! They knew what they were doing and were incredibly knowledgeable throughout the process.",
        name: "John McConnor",
        title: "Senior Marketing Manager",
      },
      {
        quote:
          "A wonderful experience! They knew what they were doing and were incredibly knowledgeable throughout the process.",
        name: "John McConnor",
        title: "Senior Marketing Manager",
      },
      {
        quote:
          "A wonderful experience! They knew what they were doing and were incredibly knowledgeable throughout the process.",
        name: "John McConnor",
        title: "Senior Marketing Manager",
      },
    ],
    []
  )

  const faqs: FaqItem[] = useMemo(
    () => [
      {
        question: "What services SkillPay provide?",
        answer:
          "SkillPay connects you with verified skilled workers for home and business projects, including repairs, maintenance, and on‑demand services.",
      },
      {
        question: "How do I request a service?",
        answer:
          "Choose a category, describe what you need, share your location and preferred time, then confirm your request. We’ll match you with available pros.",
      },
      {
        question: "Are your artisans trained and certified?",
        answer:
          "Yes—workers are vetted, and we verify relevant experience and documentation where applicable before onboarding.",
      },
      {
        question: "Do you offer emergency repair services?",
        answer:
          "We support urgent requests depending on your location and pro availability. Select an emergency option when submitting your request.",
      },
      {
        question: "Can businesses and commercial properties use SkillPay?",
        answer:
          "Absolutely. SkillPay supports one‑off jobs and ongoing maintenance for businesses, facilities, and commercial properties.",
      },
      {
        question: "How do you ensure quality control?",
        answer:
          "We combine vetting, customer ratings, job tracking, and support oversight to maintain consistent service quality.",
      },
      {
        question: "Do you provide warranties on services rendered?",
        answer:
          "We provide service guarantees for eligible jobs. Coverage depends on the service type and is communicated during booking.",
      },
    ],
    []
  )

  const [openIndex, setOpenIndex] = useState<number | null>(null)

  return (
    <section className="bg-white text-gray-900 py-20 md:py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-20">
        {/* Testimonials */}
        <div className="space-y-10">
          <div className="flex items-start justify-between gap-6">
            <h2 className="text-4xl md:text-5xl font-semibold leading-tight">
              See what our users
              <br />
              say about us
            </h2>
            <button className="bg-yellow-400 hover:bg-yellow-300 transition-colors text-gray-900 font-semibold px-8 py-3 rounded-xl">
              Hire a pro
            </button>
          </div>

          <div className="relative">
            <div className="flex gap-6 overflow-x-auto pb-2 snap-x snap-mandatory">
              {testimonials.map((t, idx) => (
                <article
                  key={`${t.name}-${idx}`}
                  className="min-w-[320px] md:min-w-[520px] snap-start bg-gray-100 rounded-2xl p-8 md:p-10"
                >
                  <p className="text-lg md:text-xl font-semibold leading-snug">
                    “{t.quote}”
                  </p>

                  <div className="mt-8 flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-gray-300 overflow-hidden">
                      {/* placeholder avatar */}
                      <svg
                        viewBox="0 0 24 24"
                        width="48"
                        height="48"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                        className="w-full h-full"
                      >
                        <path
                          d="M12 12C14.2091 12 16 10.2091 16 8C16 5.79086 14.2091 4 12 4C9.79086 4 8 5.79086 8 8C8 10.2091 9.79086 12 12 12Z"
                          fill="white"
                          opacity="0.8"
                        />
                        <path
                          d="M4 20C4 16.6863 7.58172 14 12 14C16.4183 14 20 16.6863 20 20"
                          stroke="white"
                          strokeWidth="2"
                          opacity="0.8"
                        />
                      </svg>
                    </div>
                    <div>
                      <p className="font-semibold">{t.name}</p>
                      <p className="text-sm text-gray-500">{t.title}</p>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          </div>
        </div>

        {/* FAQ */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">
          <div className="space-y-6">
            <h3 className="text-4xl md:text-5xl font-semibold leading-tight">
              Frequently Asked
              <br />
              Questions
            </h3>
            <p className="text-gray-500">Do you still have any questions?</p>
            <button className="bg-yellow-400 hover:bg-yellow-300 transition-colors text-gray-900 font-semibold px-8 py-4 rounded-xl inline-flex items-center gap-2">
              Contact us <span aria-hidden>↗</span>
            </button>
          </div>

          <div className="space-y-4">
            {faqs.map((f, idx) => {
              const open = openIndex === idx
              return (
                <div
                  key={f.question}
                  className="rounded-2xl border border-gray-200 bg-white"
                >
                  <button
                    type="button"
                    className="w-full flex items-center justify-between gap-4 px-6 py-5 text-left"
                    onClick={() => setOpenIndex(open ? null : idx)}
                    aria-expanded={open}
                  >
                    <span className="font-semibold">{f.question}</span>
                    <PlusIcon open={open} />
                  </button>
                  {open && (
                    <div className="px-6 pb-6 text-sm text-gray-500 leading-relaxed">
                      {f.answer}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        </div>
      </div>
    </section>
  )
}


