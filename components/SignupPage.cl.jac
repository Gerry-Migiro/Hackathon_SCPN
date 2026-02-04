import from "@jac-client/utils" { Link, useNavigate, jacSignup }

def:pub SignupPage()  -> any {
    has username: str = "",
        password: str = "",
        error: str = "";
    navigate = useNavigate();

    async def handleSignup(e: any) -> None {
        e.preventDefault();
        error = "";
        if not username or not password {
            error = "Please fill in all fields";
            return;
        }

        result = await jacSignup(username, password);
        if result["success"] {
            navigate("/onboarding");
        } else {
            # Extract error message - result["error"] may be object {code, message} or string
            errVal = result["error"];
            if errVal {
                # Try to get message from object, otherwise convert to string
                if errVal["message"] {
                    error = "" + errVal["message"];
                } else {
                    error = "" + errVal;
                }
            } else {
                error = "Username already exists";
            }
        }
    }

    def handleUsernameChange(e: any) -> None {
        username = e.target.value;
    }

    def handlePasswordChange(e: any) -> None {
        password = e.target.value;
    }

    errorDisplay = None;
    if error {
        errorDisplay = <div
            style={{"color": "#dc2626", "fontSize": "14px", "marginBottom": "10px"}}
        >
            {error}
        </div>;
    }

    return <div
        className="container"
        style={{
            "display": "flex",
            "justifyContent": "center",
            "alignItems": "center",
            "height": "100vh"
        }}
    >
        <form
            onSubmit={handleSignup}
            className="card"
            style={{"width": "100%", "maxWidth": "400px", "padding": "2.5rem"}}
        >
            <h2
                style={{
                    "textAlign": "center",
                    "marginBottom": "0.5rem",
                    "fontSize": "1.75rem"
                }}
            >
                Create Account
            </h2>
            <p
                style={{
                    "textAlign": "center",
                    "color": "var(--muted-foreground)",
                    "marginBottom": "2rem"
                }}
            >
                Join to accelerate your career
            </p>
            <div className="form-group">
                <label className="form-label">
                    Username
                </label>
                <input
                    type="text"
                    placeholder="Choose a username"
                    value={username}
                    onChange={handleUsernameChange}
                    className="form-input"
                    style={{"marginBottom": "1rem"}}
                />
            </div>
            <div className="form-group">
                <label className="form-label">
                    Password
                </label>
                <input
                    type="password"
                    placeholder="Choose a strong password"
                    value={password}
                    onChange={handlePasswordChange}
                    className="form-input"
                    style={{"marginBottom": "1.5rem"}}
                />
            </div>
            {errorDisplay}
            <button
                type="submit"
                className="btn btn-primary"
                style={{"width": "100%"}}
            >
                Get Started
            </button>
            <div
                style={{
                    "textAlign": "center",
                    "marginTop": "1.5rem",
                    "fontSize": "0.9rem",
                    "color": "var(--muted-foreground)"
                }}
            >
                Already have an account?
                <Link to="/login">
                    Sign In
                </Link>
            </div>
        </form>
    </div>;
}
