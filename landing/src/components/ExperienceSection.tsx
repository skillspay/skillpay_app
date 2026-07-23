import type { ReactNode } from "react"

type ExperienceCard = {
  title: string
  body: string
  icon: ReactNode
}

const cards: ExperienceCard[] = [
  {
    title: 'Hire trusted & vetted workers instantly',
    body: 'Lorem ipsum dolor sit amet consectetur. Scelerisque cursus in nunc in mi eget. Condimentum dui laoreet tincidunt amet.',
    icon: (
      <svg
        width="44"
        height="44"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="text-white/40"
      >
        <path
          d="M8 7.5C8 6.11929 9.11929 5 10.5 5H13.5C14.8807 5 16 6.11929 16 7.5V8.5H8V7.5Z"
          stroke="currentColor"
          strokeWidth="1.6"
        />
        <path
          d="M7 8.5H17C18.1046 8.5 19 9.39543 19 10.5V17C19 18.1046 18.1046 19 17 19H7C5.89543 19 5 18.1046 5 17V10.5C5 9.39543 5.89543 8.5 7 8.5Z"
          stroke="currentColor"
          strokeWidth="1.6"
        />
        <path
          d="M9 12.5H15"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
  {
    title: 'Save time through simplified hiring',
    body: 'Lorem ipsum dolor sit amet consectetur. Scelerisque cursus in nunc in mi eget. Condimentum dui laoreet tincidunt amet.',
    icon: (
      <svg
        width="44"
        height="44"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="text-white/40"
      >
        <path
          d="M12 8V12L14.5 13.5"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d="M12 21C16.4183 21 20 17.4183 20 13C20 8.58172 16.4183 5 12 5C7.58172 5 4 8.58172 4 13C4 17.4183 7.58172 21 12 21Z"
          stroke="currentColor"
          strokeWidth="1.6"
        />
        <path
          d="M7.5 4.5L5.5 6.5"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
        <path
          d="M16.5 4.5L18.5 6.5"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
        />
      </svg>
    ),
  },
  {
    title: 'Manage and reduce risk',
    body: 'Lorem ipsum dolor sit amet consectetur. Scelerisque cursus in nunc in mi eget. Condimentum dui laoreet tincidunt amet.',
    icon: (
      <svg
        width="44"
        height="44"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="text-white/40"
      >
        <path
          d="M12 3L19 6.5V12.2C19 16.6 16.1 20.4 12 21.7C7.9 20.4 5 16.6 5 12.2V6.5L12 3Z"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinejoin="round"
        />
        <path
          d="M9.5 12.2L11.2 14L14.8 10.4"
          stroke="currentColor"
          strokeWidth="1.6"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
    ),
  },
]

export default function ExperienceSection() {
  return (
    <section className="bg-black text-white py-16 md:py-24">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-10 items-start">
          <h2 className="text-4xl md:text-5xl font-semibold leading-tight">
            Enjoy the SkillPay
            <br />
            experience
          </h2>
          <p className="text-white/60 text-base md:text-lg leading-relaxed max-w-xl lg:justify-self-end">
            We simplify the hiring process, offer on-the-job insurance and give
            the SkillPay Guarantee to ensure our clients&apos; peace of mind.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {cards.map((card) => (
            <article
              key={card.title}
              className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-sm p-7 md:p-8 min-h-[320px] flex flex-col"
            >
              <div className="mb-8">{card.icon}</div>
              <h3 className="text-xl font-semibold leading-snug">
                {card.title}
              </h3>
              <p className="mt-4 text-white/60 text-sm leading-relaxed">
                {card.body}
              </p>
              <button className="mt-auto pt-8 text-sm font-semibold inline-flex items-center gap-3 text-white">
                Discover More <span aria-hidden>→</span>
              </button>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}


