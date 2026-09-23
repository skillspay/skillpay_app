import { useState, useEffect } from "react";
import Nav from "./components/Nav";
import Home from "./pages/Home";
import TermsOfService from "./pages/TermsOfService";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import ArtisanTerms from "./pages/ArtisanTerms";
import CookiePolicy from "./pages/CookiePolicy";
import DisclaimerPage from "./pages/DisclaimerPage";
import ComplaintsPolicy from "./pages/ComplaintsPolicy";
import "./App.css";

function App() {
  const [currentHash, setCurrentHash] = useState(
    window.location.hash.toLowerCase()
  );

  useEffect(() => {
    const handleHashChange = () => {
      const hash = window.location.hash.toLowerCase();
      setCurrentHash(hash);
      window.scrollTo({ top: 0, behavior: "smooth" });
    };

    window.addEventListener("hashchange", handleHashChange);
    return () => window.removeEventListener("hashchange", handleHashChange);
  }, []);

  // Normalize hash (e.g., "#terms", "#/terms", "#terms/")
  const cleanRoute = currentHash.replace(/^#\/?/, "").split("?")[0].replace(/\/$/, "");

  // Compliance page routing
  switch (cleanRoute) {
    case "terms":
    case "terms-of-service":
      return <TermsOfService />;
    case "privacy":
    case "privacy-policy":
      return <PrivacyPolicy />;
    case "artisan-terms":
    case "artisan-terms-of-service":
      return <ArtisanTerms />;
    case "cookies":
    case "cookie-policy":
      return <CookiePolicy />;
    case "disclaimer":
    case "disclaimers":
    case "legal":
      return <DisclaimerPage />;
    case "complaints":
    case "disputes":
      return <ComplaintsPolicy />;
    default:
      return (
        <div className="min-h-screen bg-gray-900">
          <Nav />
          <Home />
        </div>
      );
  }
}

export default App;
