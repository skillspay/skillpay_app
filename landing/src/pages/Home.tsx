import Header from "../components/Header";
import ServicesSection from "../components/ServicesSection";
import ExperienceSection from "../components/ExperienceSection";
import TrustSection from "../components/TrustSection";
import TestimonialsFaqSection from "../components/TestimonialsFaqSection";
import FinalCtaSection from "../components/FinalCtaSection";
import Footer from "../components/Footer";

export default function Home() {
  return (
    <div>
      <Header />
      <ServicesSection />
      <ExperienceSection />
      <TrustSection />
      <TestimonialsFaqSection />
      <FinalCtaSection />
      <Footer />
    </div>
  );
}
