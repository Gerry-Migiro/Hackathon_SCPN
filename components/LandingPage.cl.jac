import from "@jac-client/utils" { Link, jacIsLoggedIn, Navigate }

def:pub LandingPage() -> any {
    # Redirect logged-in users to dashboard
    if jacIsLoggedIn() {
        return <Navigate to="/dashboard" />;
    }

    features = [
        {
            "icon": "M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M12 16c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4z",
            "title": "AI-Powered Career Analysis",
            "description": "Multi-agent AI analyzes your skills, identifies gaps, and creates personalized strategies."
        },
        {
            "icon": "M18 20V10 M12 20V4 M6 20v-6",
            "title": "Market Intelligence",
            "description": "Real-time job market insights, salary trends, and demand forecasting."
        },
        {
            "icon": "M3 6l6-3 6 3 6-3v15l-6 3-6-3-6 3V6z M9 3v15 M15 6v15",
            "title": "Personalized Roadmaps",
            "description": "Week-by-week learning plans tailored to your goals and learning pace."
        },
        {
            "icon": "M20 7H4a2 2 0 00-2 2v10a2 2 0 002 2h16a2 2 0 002-2V9a2 2 0 00-2-2z M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16",
            "title": "Job Matching",
            "description": "Discover opportunities that match your skills with intelligent recommendations."
        }
    ];

    return <div className="landing-page">
        <header className="landing-header">
            <div className="container">
                <div className="landing-nav">
                    <div className="landing-logo">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M12 2L2 7l10 5 10-5-10-5z"></path>
                            <path d="M2 17l10 5 10-5"></path>
                            <path d="M2 12l10 5 10-5"></path>
                        </svg>
                        <span>Career Navigator</span>
                    </div>
                    <div className="landing-nav-links">
                        <Link to="/login" className="btn btn-outline">Sign In</Link>
                        <Link to="/signup" className="btn btn-primary">Get Started</Link>
                    </div>
                </div>
            </div>
        </header>

        <main className="landing-main">
            <section className="hero-section">
                <div className="container">
                    <div className="hero-content">
                        <h1 className="hero-title">Navigate Your Career with AI</h1>
                        <p className="hero-subtitle">
                            An intelligent career guidance platform powered by multi-agent AI. 
                            Get personalized strategies, learning roadmaps, and job recommendations.
                        </p>
                        <div className="hero-actions">
                            <Link to="/signup" className="btn btn-primary btn-lg">
                                Start Your Journey
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <line x1="5" y1="12" x2="19" y2="12"></line>
                                    <polyline points="12 5 19 12 12 19"></polyline>
                                </svg>
                            </Link>
                            <Link to="/login" className="btn btn-outline btn-lg">
                                I have an account
                            </Link>
                        </div>
                    </div>
                </div>
            </section>

            <section className="features-section">
                <div className="container">
                    <h2 className="section-heading">How It Works</h2>
                    <div className="features-grid">
                        {features.map(lambda f: dict, i: int -> any {
                            return <div key={i} className="feature-card">
                                <div className="feature-icon">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                        <path d={f["icon"]}></path>
                                    </svg>
                                </div>
                                <h3 className="feature-title">{f["title"]}</h3>
                                <p className="feature-description">{f["description"]}</p>
                            </div>;
                        })}
                    </div>
                </div>
            </section>

            <section className="cta-section">
                <div className="container">
                    <div className="cta-content">
                        <h2>Ready to Transform Your Career?</h2>
                        <p>Join thousands of professionals using AI to achieve their career goals.</p>
                        <Link to="/signup" className="btn btn-primary btn-lg">Create Free Account</Link>
                    </div>
                </div>
            </section>
        </main>

        <footer className="landing-footer">
            <div className="container">
                <p>© 2026 Career Navigator. Built with Jaseci.</p>
            </div>
        </footer>
    </div>;
}
