import from "@jac-client/utils" {
    Link,
    useNavigate,
    useLocation,
    jacLogout,
    jacIsLoggedIn
}

def:pub Navbar()  -> any {
    location = useLocation();
    isLoggedIn = jacIsLoggedIn();
    navigate = useNavigate();

    # Hide navbar on landing and onboarding pages
    if location.pathname == "/" or location.pathname == "/onboarding" {
        return None;
    }

    def handleLogout(e: any) -> None {
        e.preventDefault();
        jacLogout();
        localStorage.clear();
        window.location.href = "/";
    }

    def handleBrandClick(e: any) -> None {
        e.preventDefault();
        navigate("/");
    }

    navLinks = None;
    if isLoggedIn {
        navLinks = <div className="nav-items">
            <Link
                to="/dashboard"
                className={"nav-link" + (" active" if location.pathname == "/dashboard" else "")}
            >
                Dashboard
            </Link>
            <Link
                to="/career"
                className={"nav-link" + (" active" if location.pathname == "/career" else "")}
            >
                Career Path
            </Link>
            <Link
                to="/jobs"
                className={"nav-link" + (" active" if location.pathname == "/jobs" else "")}
            >
                Jobs
            </Link>
            <Link
                to="/courses"
                className={"nav-link" + (" active" if location.pathname == "/courses" else "")}
            >
                Courses
            </Link>
            <Link
                to="/profile"
                className={"nav-link" + (" active" if location.pathname == "/profile" else "")}
            >
                Profile
            </Link>
            <button
                onClick={handleLogout}
                className="btn btn-logout"
            >
                Logout
            </button>
        </div>;
    } else {
        navLinks = <div className="nav-items">
            <Link
                to="/login"
                className="nav-link"
            >
                Login
            </Link>
            <Link
                to="/signup"
                className="btn btn-primary btn-sm"
            >
                Sign Up
            </Link>
        </div>;
    }

    return <nav className="navbar">
        <div className="container navbar-container">
            <a href="#" onClick={handleBrandClick} className="navbar-brand-link">
                <h1 className="navbar-brand">
                    🧭 Career Navigator
                </h1>
            </a>
            {navLinks}
        </div>
    </nav>;
}
