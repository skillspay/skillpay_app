import type { ReactNode } from "react";

function StoreButton({
  variant,
  children,
}: {
  variant: "google" | "apple";
  children: ReactNode;
}) {
  const base =
    "inline-flex items-center gap-3 rounded-xl bg-black text-white px-5 py-3 shadow-sm hover:bg-gray-900 transition-colors";

  return (
    <button className={base} type="button">
      {variant === "google" ? (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M3.5 3.4V20.6C3.5 21 3.72 21.37 4.08 21.56L13.25 12L4.08 2.44C3.72 2.63 3.5 3 3.5 3.4Z"
            fill="#34A853"
          />
          <path
            d="M13.25 12L16.46 15.34L6.11 21.2C5.66 21.45 5.11 21.44 4.68 21.17L13.25 12Z"
            fill="#FBBC04"
          />
          <path
            d="M20.05 10.96C20.53 11.23 20.83 11.6 20.83 12C20.83 12.4 20.53 12.77 20.05 13.04L16.46 15.34L13.25 12L16.46 8.66L20.05 10.96Z"
            fill="#EA4335"
          />
          <path
            d="M6.11 2.8L16.46 8.66L13.25 12L4.68 2.83C5.11 2.56 5.66 2.55 6.11 2.8Z"
            fill="#4285F4"
          />
        </svg>
      ) : (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="currentColor"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M18.71,19.5C17.88,20.74 17,21.95 15.66,21.97C14.32,22 13.89,21.18 12.37,21.18C10.84,21.18 10.37,21.95 9.1,22C7.79,22.05 6.8,20.68 5.96,19.47C4.25,17 2.94,12.45 4.7,9.39C5.57,7.87 7.13,6.91 8.82,6.88C10.1,6.86 11.32,7.75 12.11,7.75C12.89,7.75 14.37,6.68 15.92,6.84C16.57,6.87 18.39,7.1 19.56,8.82C19.47,8.88 17.39,10.1 17.41,12.63C17.44,15.65 20.06,16.66 20.09,16.67C20.06,16.74 19.67,18.11 18.71,19.5M13,3.5C13.73,2.67 14.94,2.04 15.94,2C16.07,3.17 15.6,4.35 14.9,5.19C14.21,6.04 13.07,6.7 11.95,6.61C11.8,5.46 12.36,4.26 13,3.5Z" />
        </svg>
      )}

      <div className="leading-tight text-left">
        <div className="text-[10px] uppercase tracking-wide opacity-80">
          {variant === "google" ? "Get it on" : "Download on the"}
        </div>
        <div className="text-base font-semibold">{children}</div>
      </div>
    </button>
  );
}

export default function FinalCtaSection() {
  return (
    <section className="bg-gray-100 py-16 md:py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-yellow-400 rounded-2xl overflow-hidden">
          <div className="grid grid-cols-1 lg:grid-cols-2 items-center">
            <div className="p-10 md:p-14 lg:p-16 flex flex-col justify-center">
              <h2 className="text-5xl md:text-6xl font-semibold leading-[1.02] text-gray-900">
                Hire for your
                <br />
                next project.
              </h2>
              <p className="mt-6 text-gray-900/80 max-w-md leading-relaxed">
                Lorem ipsum dolor sit amet consectetur. Curabitur ac tortor in
                mattis. Convallis imperdiet magna tincidunt in eleifend. Cras.
              </p>

              <div className="mt-8 flex flex-wrap gap-4">
                <StoreButton variant="google">Google Play</StoreButton>
                <StoreButton variant="apple">App Store</StoreButton>
              </div>
            </div>

            <div className="relative flex justify-center lg:justify-end">
              <div className="lg:pr-10 xl:pr-16 py-8 lg:py-12">
                <div className="w-[280px] md:w-[300px] lg:w-[320px]">
                  <div className="rounded-[2.8rem] bg-gray-900 p-2 shadow-2xl">
                    <div className="rounded-[2.4rem] overflow-hidden bg-black aspect-[9/19]">
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
      </div>
    </section>
  );
}
