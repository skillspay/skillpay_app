function SocialIcon({ kind }: { kind: "facebook" | "x" | "instagram" }) {
  const base = "w-5 h-5 text-gray-600";
  if (kind === "facebook") {
    return (
      <svg
        className={base}
        viewBox="0 0 24 24"
        fill="currentColor"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden
      >
        <path d="M22 12a10 10 0 1 0-11.6 9.9v-7H8v-2.9h2.4V9.8c0-2.4 1.4-3.7 3.6-3.7 1 0 2.1.2 2.1.2v2.3h-1.2c-1.2 0-1.6.8-1.6 1.6v1.9H16l-.4 2.9h-2.3v7A10 10 0 0 0 22 12Z" />
      </svg>
    );
  }
  if (kind === "instagram") {
    return (
      <svg
        className={base}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden
      >
        <path
          d="M7 3H17C19.2091 3 21 4.79086 21 7V17C21 19.2091 19.2091 21 17 21H7C4.79086 21 3 19.2091 3 17V7C3 4.79086 4.79086 3 7 3Z"
          stroke="currentColor"
          strokeWidth="2"
        />
        <path
          d="M12 16.2C14.3196 16.2 16.2 14.3196 16.2 12C16.2 9.68041 14.3196 7.8 12 7.8C9.68041 7.8 7.8 9.68041 7.8 12C7.8 14.3196 9.68041 16.2 12 16.2Z"
          stroke="currentColor"
          strokeWidth="2"
        />
        <path
          d="M17.5 6.5H17.51"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </svg>
    );
  }
  return (
    <svg
      className={base}
      viewBox="0 0 24 24"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <path d="M18.9 2H22l-6.8 7.8L23.2 22H16l-5.6-7.1L4.2 22H1l7.4-8.6L.8 2H8l5 6.3L18.9 2Zm-1.1 18h1.7L7.1 3.9H5.3L17.8 20Z" />
    </svg>
  );
}

function FooterColumn({ title, links }: { title: string; links: string[] }) {
  return (
    <div className="space-y-4">
      <p className="font-semibold text-gray-900">{title}</p>
      <ul className="space-y-3 text-sm text-gray-500">
        {links.map((l) => (
          <li key={l}>
            <a className="hover:text-gray-900 transition-colors" href="#">
              {l}
            </a>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function Footer() {
  return (
    <footer className="bg-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-12 pb-10">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-10">
          <FooterColumn
            title="Products"
            links={[
              "SkillPay artisans",
              "SkillPay homeowners",
              "SkillPay business",
              "Invoice",
              "Request",
              "Subscriptions",
            ]}
          />
          <FooterColumn
            title="Company"
            links={[
              "About us",
              "Press",
              "Careers",
              "Blog",
              "FAQs",
              "Affiliates and partnerships",
              "Help centre",
            ]}
          />
          <FooterColumn
            title="Support"
            links={[
              "Terms of sevice",
              "Privacy policy",
              "Artisan terms of service",
              "Cokie policy",
              "Others",
            ]}
          />
          <div className="space-y-4">
            <p className="font-semibold text-gray-900">Follow us</p>
            <div className="flex items-center gap-4">
              <a href="#" className="hover:opacity-80 transition-opacity">
                <SocialIcon kind="facebook" />
              </a>
              <a href="#" className="hover:opacity-80 transition-opacity">
                <SocialIcon kind="x" />
              </a>
              <a href="#" className="hover:opacity-80 transition-opacity">
                <SocialIcon kind="instagram" />
              </a>
            </div>
          </div>
        </div>

        <div className="mt-14 border-t border-gray-200 pt-10">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
            <div className="flex items-center gap-4">
              <img
                src="/logo.png"
                alt="SkillPay"
                className="w-30 rounded-full"
              />
            </div>

            <div className="flex flex-wrap items-center gap-x-10 gap-y-3 text-sm text-gray-500 justify-center md:justify-start">
              <a className="hover:text-gray-900 transition-colors" href="#">
                Legal
              </a>
              <a className="hover:text-gray-900 transition-colors" href="#">
                Complaints
              </a>
            </div>

            <div className="flex flex-wrap items-center gap-x-10 gap-y-3 text-sm text-gray-500 justify-center md:justify-end">
              <a className="hover:text-gray-900 transition-colors" href="#">
                Privacy policy
              </a>
              <a className="hover:text-gray-900 transition-colors" href="#">
                Country site map
              </a>
              <a className="hover:text-gray-900 transition-colors" href="#">
                Cookie Policy
              </a>
            </div>
          </div>

          <p className="mt-10 text-center text-xs text-gray-500">
            Copyright © {new Date().getFullYear()} SkillPay. All Rights Reserved
          </p>
        </div>
      </div>
    </footer>
  );
}
