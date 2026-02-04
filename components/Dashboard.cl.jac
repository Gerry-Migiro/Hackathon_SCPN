import from react { useEffect }
import from "@jac-client/utils" { Link, useNavigate, jacIsLoggedIn, Navigate }

walker get_profile {}

def:pub Dashboard()  -> any {
    if not jacIsLoggedIn() {
        return <Navigate to="/login" />;
    }
    has profile: any = None,
        gaps: list = [],
        roadmap: list = [];
    navigate = useNavigate();

    async def loadData()  -> None {
        try {
            res = await root spawn get_profile();
            if res.reports {
                p = res.reports[0];
                if p and not p["error"] {
                    profile = p;
                    # Redirect to onboarding if name is empty (new user)
                    if not p["name"] or p["name"] == "" {
                        navigate("/onboarding");
                        return;
                    }
                    # Parse strategy to extract gaps
                    if p["last_strategy"] and p["last_strategy"] != "[]" {
                        try {
                            clean_strategy = p["last_strategy"].replace(
                                "```json", ""
                            ).replace(
                                "```", ""
                            ).trim();
                            strategy = JSON.parse(clean_strategy);
                            if strategy.gaps && Array.isArray(strategy.gaps) {
                                gaps = strategy.gaps;
                            }
                        } except ex1 {
                            console.error("Error parsing strategy:", ex1);
                        }
                    }
                    # Parse learning plan
                    if p["last_roadmap_plan"] and p["last_roadmap_plan"] != "[]" {
                        try {
                            clean_plan = p["last_roadmap_plan"].replace(
                                "```json", ""
                            ).replace(
                                "```", ""
                            ).trim();
                            plan = JSON.parse(clean_plan);
                            if plan.weeks {
                                roadmap = plan.weeks;
                            }
                        } except ex2 {
                            console.error("Error parsing plan:", ex2);
                        }
                    }
                } else {
                    console.error("Profile load error:", p);
                    profile = {
                        "name": "",
                        "interests": [],
                        "goals": [],
                        "skills": [],
                        "target_role": ""
                    };
                }
            } else {
                console.error("No reports in response");
                profile = {
                    "name": "",
                    "interests": [],
                    "goals": [],
                    "skills": [],
                    "target_role": ""
                };
            }
        } except ex {
            console.error("Error loading dashboard:", ex);
            profile = {
                "name": "",
                "interests": [],
                "goals": [],
                "skills": [],
                "target_role": ""
            };
        }
    }

    useEffect(lambda   -> None{ loadData();} , []);

    if not profile {
        return <div
            style={{"padding": "4rem", "textAlign": "center", "color": "#64748b"}}
        >
            Loading dashboard...
        </div>;
    }

    return <div
        className="container"
        style={{"maxWidth": "1200px", "padding": "2rem 1rem"}}
    >
        <div
            style={{"marginBottom": "2rem"}}
        >
            <h1
                style={{
                    "margin": 0,
                    "fontSize": "2rem",
                    "color": "var(--foreground)"
                }}
            >
                Welcome, {profile["name"]}
            </h1>
        </div>
        <div className="grid-dashboard">
            <div className="card">
                <div className="text-label">
                    Target Role
                </div>
                <div className="text-value">
                    {profile["target_role"] if profile["target_role"] else "Not Set"}
                </div>
                {not profile["target_role"]
                and <Link
                    to="/profile"
                    style={{
                        "display": "inline-block",
                        "marginTop": "1rem",
                        "fontSize": "0.875rem",
                        "color": "var(--brand)",
                        "textDecoration": "none"
                    }}
                >
                    Set a goal →
                </Link>}
            </div>
            <div className="card">
                <div className="text-label">
                    Skills Acquired
                </div>
                <div className="text-value">
                    {profile["skills"].length}
                </div>
                <div className="text-sub">
                    Verified skills
                </div>
            </div>
            <div className="card">
                <div className="text-label">
                    Skill Gaps
                </div>
                <div
                    className="text-value"
                    style={{"color": "var(--error)"}}
                >
                    {gaps.length}
                </div>
                <div className="text-sub">
                    Areas for improvement
                </div>
            </div>
        </div>
        <div className="grid-cols-2">
            <div className="card">
                <div
                    className="flex-between"
                    style={{
                        "marginBottom": "1.5rem",
                        "borderBottom": "1px solid var(--border)",
                        "paddingBottom": "1rem"
                    }}
                >
                    <h3
                        style={{"fontSize": "1.1rem", "margin": "0"}}
                    >
                        Learning Path
                    </h3>
                    <Link
                        to="/career"
                        style={{
                            "fontSize": "0.875rem",
                            "color": "var(--brand)",
                            "textDecoration": "none",
                            "fontWeight": "500"
                        }}
                    >
                        View Full Plan →
                    </Link>
                </div>
                {roadmap.length > 0
                and <div className="flex-col gap-sm">
                    {roadmap.slice(0, 5).map(
                        lambda  step: any  -> any{ return <div
                            style={{
                                "display": "flex",
                                "alignItems": "center",
                                "gap": "0.75rem",
                                "padding": "0.5rem 0",
                                "borderBottom": "1px solid var(--border)"
                            }}
                        >
                            <div
                                style={{
                                    "width": "28px",
                                    "height": "28px",
                                    "borderRadius": "50%",
                                    "background": "var(--brand)",
                                    "color": "white",
                                    "display": "flex",
                                    "alignItems": "center",
                                    "justifyContent": "center",
                                    "fontSize": "0.75rem",
                                    "fontWeight": "700",
                                    "flexShrink": "0"
                                }}
                            >
                                {step["week"]}
                            </div>
                            <div
                                style={{"fontSize": "0.9rem", "color": "var(--card-foreground)"}}
                            >
                                {step["focus"]}
                            </div>
                        </div>; }
                    )}
                    {roadmap.length > 5 and <div style={{"textAlign": "center", "paddingTop": "0.5rem"}}>
                        <Link to="/career" style={{"fontSize": "0.875rem", "color": "var(--brand)"}}>
                            +{roadmap.length - 5} more weeks →
                        </Link>
                    </div>}
                </div>}
                {roadmap.length == 0
                and <div
                    style={{
                        "textAlign": "center",
                        "padding": "2rem 0",
                        "color": "var(--muted-foreground)"
                    }}
                >
                    <p style={{"marginBottom": "1rem"}}>
                        No learning path generated yet.
                    </p>
                    <Link
                        to="/career"
                        state={{"role": profile["target_role"], "run": True}}
                        className="btn btn-primary"
                    >
                        Generate Roadmap
                    </Link>
                </div>}
            </div>
            <div
                className="flex-col"
                style={{"gap": "1.5rem"}}
            >
                <div className="card">
                    <h3 className="section-title">
                        Skill Gaps
                    </h3>
                    {gaps.length > 0
                    and <div
                        className="flex-col"
                        style={{"gap": "0.5rem"}}
                    >
                        {gaps.slice(0, 4).map(
                            lambda  gap: any  -> any{ return <div className="alert-red" style={{"padding": "0.5rem 0.75rem"}}>
                                <span>
                                    • {gap}
                                </span>
                            </div>; }
                        )}
                        {gaps.length > 4 and <div style={{"fontSize": "0.875rem", "color": "var(--muted-foreground)", "textAlign": "center"}}>
                            +{gaps.length - 4} more gaps
                        </div>}
                    </div>}
                    {gaps.length == 0
                    and <div
                        className="text-sub"
                        style={{"fontStyle": "italic"}}
                    >
                        No gaps identified yet. Generate a roadmap to identify skill gaps.
                    </div>}
                </div>
                <div className="card">
                    <h3 className="section-title">
                        My Skills
                    </h3>
                    <div
                        style={{"display": "flex", "flexWrap": "wrap", "gap": "0.5rem"}}
                    >
                        {profile["skills"].length > 0
                        and profile["skills"].map(
                            lambda  s: any  -> any{ return <span className="badge badge-gray">
                                {s}
                            </span>; }
                        )}{profile["skills"].length == 0
                        and <span className="text-sub">
                            No skills added yet. <Link to="/profile" style={{"color": "var(--brand)"}}>Add skills →</Link>
                        </span>}
                    </div>
                </div>
            </div>
        </div>
    </div>;
}
