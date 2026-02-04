import from react { useEffect }
import from "@jac-client/utils" {
    useLocation,
    jacIsLoggedIn,
    Navigate,
    Link
}

walker generate_roadmap {
    has target_role: str;
}

walker get_profile {}
walker get_all_roles {}

def:pub CareerPath() -> any {
    if not jacIsLoggedIn() { return <Navigate to="/login" />; }
    
    has role: str = "",
        availableRoles: list = [],
        strategy: any = None,
        market: any = None,
        plan: any = None,
        loading: bool = False,
        error: str = "",
        hasData: bool = False;
    location = useLocation();

    # Simple parse function like dashboard uses
    def safeParse(data: any) -> any {
        if not data or data == "[]" { return None; }
        try {
            if data.replace {
                clean = data.replace("```json", "").replace("```", "").trim();
                return JSON.parse(clean);
            }
            return data;
        } except err {
            console.error("Parse error:", err);
            return None;
        }
    }

    async def generate() -> None {
        if not role { return; }
        loading = True;
        error = "";
        strategy = None;
        market = None;
        plan = None;
        hasData = False;
        
        try {
            res = await root spawn generate_roadmap(target_role=role);
            console.log("Generate response:", res);

            if res.reports and res.reports.length > 0 {
                # Parse each section like dashboard does
                parsedStrategy = safeParse(res.reports[0]["strategy"]);
                parsedMarket = safeParse(res.reports[0]["market"]);
                parsedPlan = safeParse(res.reports[0]["plan"]);
                
                console.log("Parsed strategy:", parsedStrategy);
                console.log("Parsed market:", parsedMarket);
                console.log("Parsed plan:", parsedPlan);
                
                # Update state
                strategy = parsedStrategy;
                market = parsedMarket;
                plan = parsedPlan;
                hasData = parsedStrategy or parsedMarket or parsedPlan;
                loading = False;
                
                # Reload from backend to confirm save (optional verification)
                try {
                    profileRes = await root spawn get_profile();
                    if profileRes.reports and profileRes.reports.length > 0 {
                        console.log("Verified save - backend has:", profileRes.reports[0]);
                    }
                } except verifyErr {
                    console.log("Could not verify save:", verifyErr);
                }
            } else {
                error = "No data received from AI. Please try again.";
                loading = False;
            }
        } except genError {
            console.error("Generation error:", genError);
            error = "An error occurred while generating the roadmap.";
            loading = False;
        }
    }

    # Load saved data on mount - same pattern as dashboard
    useEffect(lambda -> None {
        async def init() -> None {
            # Fetch available roles
            try {
                rolesRes = await root spawn get_all_roles();
                if rolesRes.reports and rolesRes.reports.length > 0 {
                    availableRoles = rolesRes.reports[0];
                }
            } except err {
                console.error("Error fetching roles:", err);
            }

            # Check if we should auto-generate
            if location.state and location.state["role"] {
                role = location.state["role"];
                if location.state["run"] {
                    generate();
                    return;
                }
            }

            # Load saved profile data - exactly like dashboard
            try {
                res = await root spawn get_profile();
                if res.reports and res.reports.length > 0 {
                    p = res.reports[0];
                    if p["target_role"] { role = p["target_role"]; }
                    
                    # Parse saved data exactly like dashboard does
                    if p["last_strategy"] and p["last_strategy"] != "[]" {
                        strategy = safeParse(p["last_strategy"]);
                        console.log("Loaded strategy:", strategy);
                    }
                    if p["last_market"] and p["last_market"] != "[]" {
                        market = safeParse(p["last_market"]);
                        console.log("Loaded market:", market);
                    }
                    if p["last_roadmap_plan"] and p["last_roadmap_plan"] != "[]" {
                        plan = safeParse(p["last_roadmap_plan"]);
                        console.log("Loaded plan:", plan);
                    }
                    # Update hasData after loading
                    hasData = strategy or market or plan;
                }
            } except loadError {
                console.error("Error loading profile:", loadError);
            }
        }
        init();
    }, []);

    return <div className="container" style={{"maxWidth": "1200px", "padding": "2rem 1rem"}}>
        <h2 className="mb-8" style={{"color": "var(--foreground)", "marginBottom": "2rem", "fontSize": "2rem", "fontWeight": "700", "textAlign": "center"}}>AI Career Roadmap</h2>
        
        <div className="card" style={{"marginBottom": "2rem", "maxWidth": "800px", "margin": "0 auto 2rem auto"}}>
            <div style={{"display": "flex", "gap": "1rem", "flexWrap": "wrap"}}>
                <div style={{"flex": 1}}>
                    <div style={{"display": "flex", "gap": "0.5rem"}}>
                        <input 
                            type="text" 
                            placeholder="Enter Target Role (e.g. Senior Python Developer)" 
                            value={role} 
                            onChange={lambda e: any -> None { role = e.target.value; }} 
                            className="form-input"
                            style={{"flex": 1}}
                        />
                        <select 
                            value=""
                            onChange={lambda e: any -> None { role = e.target.value; }} 
                            className="form-input"
                            style={{"width": "180px"}}
                        >
                            <option value="" disabled>Select Role...</option>
                            {availableRoles.map(lambda r: any, i: int -> any {
                                return <option key={i} value={r.title}>{r.title}</option>;
                            })}
                        </select>
                    </div>
                </div>
                <button 
                    onClick={generate} 
                    disabled={loading}
                    className="btn btn-primary"
                >
                    {loading and "Generating..."}{not loading and "Generate Roadmap"}
                </button>
            </div>
            {error and <div className="alert-red" style={{"marginTop": "1rem", "textAlign": "center"}}>{error}</div>}
        </div>

        {loading and <div style={{"textAlign": "center", "padding": "4rem", "color": "var(--muted-foreground)"}}>
            <div className="animate-fade-in" style={{"fontSize": "1.5rem", "marginBottom": "1rem", "fontWeight": "500"}}>Analyzing your profile and market data...</div>
            <div style={{"fontSize": "1.1rem"}}>This may take a few seconds.</div>
        </div>}

        {not loading and not hasData and <div className="card" style={{"textAlign": "center", "padding": "3rem"}}>
            <p style={{"color": "var(--muted-foreground)", "fontSize": "1.1rem"}}>
                No career roadmap generated yet. Enter a target role and click "Generate Roadmap" to get started.
            </p>
        </div>}

        {not loading and hasData and <div style={{"display": "grid", "gap": "2rem"}}>
            {strategy and <div className="card" style={{"borderTop": "4px solid var(--brand)"}}>
                <h3 style={{"color": "var(--brand)", "fontSize": "1.25rem", "marginBottom": "1.5rem", "paddingBottom": "0.5rem", "borderBottom": "1px solid var(--border)"}}>
                    Strategic Analysis
                </h3>
                
                {strategy.strengths and Array.isArray(strategy.strengths) and strategy.strengths.length > 0 and <div style={{"marginBottom": "1.5rem"}}>
                    <h4 style={{"fontSize": "1rem", "fontWeight": "600", "marginBottom": "0.75rem", "color": "#10b981"}}>✓ Strengths</h4>
                    <div style={{"display": "flex", "flexDirection": "column", "gap": "0.5rem"}}>
                        {strategy.strengths.map(lambda item: str, i: int -> any {
                            return <div key={i} style={{"display": "flex", "gap": "0.5rem", "alignItems": "flex-start", "color": "var(--card-foreground)"}}>
                                <span style={{"color": "#10b981"}}>•</span>
                                <span>{item}</span>
                            </div>;
                        })}
                    </div>
                </div>}
                
                {strategy.gaps and Array.isArray(strategy.gaps) and strategy.gaps.length > 0 and <div style={{"marginBottom": "1.5rem"}}>
                    <h4 style={{"fontSize": "1rem", "fontWeight": "600", "marginBottom": "0.75rem", "color": "#ef4444"}}>⚠ Skill Gaps</h4>
                    <div style={{"display": "flex", "flexDirection": "column", "gap": "0.5rem"}}>
                        {strategy.gaps.map(lambda item: str, i: int -> any {
                            return <div key={i} className="alert-red" style={{"padding": "0.5rem 0.75rem"}}>
                                • {item}
                            </div>;
                        })}
                    </div>
                </div>}
                
                {strategy.recommendation and <div>
                    <h4 style={{"fontSize": "1rem", "fontWeight": "600", "marginBottom": "0.75rem", "color": "var(--brand)"}}>→ Recommendation</h4>
                    <p style={{"color": "var(--card-foreground)", "lineHeight": "1.6"}}>{strategy.recommendation}</p>
                </div>}
            </div>}

            {market and <div className="card" style={{"borderTop": "4px solid #10b981"}}>
                <h3 style={{"color": "#10b981", "fontSize": "1.25rem", "marginBottom": "1.5rem", "paddingBottom": "0.5rem", "borderBottom": "1px solid var(--border)"}}>
                    Market Insights
                </h3>
                
                <div style={{"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(200px, 1fr))", "gap": "1rem", "marginBottom": "1.5rem"}}>
                    {market.demand and <div className="card" style={{"background": "var(--secondary)", "padding": "1rem"}}>
                        <div className="text-label">Market Demand</div>
                        <div className="text-value" style={{"color": "#10b981" if market.demand == "High" else "#f59e0b"}}>{market.demand}</div>
                    </div>}
                    
                    {market.salary_range and <div className="card" style={{"background": "var(--secondary)", "padding": "1rem"}}>
                        <div className="text-label">Salary Range</div>
                        <div className="text-value" style={{"color": "#10b981", "fontSize": "1rem"}}>{market.salary_range}</div>
                    </div>}
                </div>
                
                {market.top_companies and Array.isArray(market.top_companies) and market.top_companies.length > 0 and <div>
                    <h4 style={{"fontSize": "1rem", "fontWeight": "600", "marginBottom": "0.75rem", "color": "var(--foreground)"}}>Top Hiring Companies</h4>
                    <div style={{"display": "flex", "flexWrap": "wrap", "gap": "0.5rem"}}>
                        {market.top_companies.map(lambda company: str, i: int -> any {
                            return <span key={i} className="badge" style={{"background": "rgba(16, 185, 129, 0.15)", "color": "#10b981", "border": "1px solid rgba(16, 185, 129, 0.3)"}}>{company}</span>;
                        })}
                    </div>
                </div>}
            </div>}

            {plan and plan.weeks and Array.isArray(plan.weeks) and plan.weeks.length > 0 and <div className="card" style={{"borderTop": "4px solid #f59e0b"}}>
                <div className="flex-between" style={{"marginBottom": "1.5rem", "paddingBottom": "0.5rem", "borderBottom": "1px solid var(--border)"}}>
                    <h3 style={{"color": "#f59e0b", "fontSize": "1.25rem", "margin": "0"}}>
                        Learning Plan
                    </h3>
                    <span className="badge" style={{"background": "rgba(245, 158, 11, 0.15)", "color": "#f59e0b", "border": "1px solid rgba(245, 158, 11, 0.3)"}}>
                        {plan.weeks.length} Weeks
                    </span>
                </div>
                
                <div style={{"display": "flex", "flexDirection": "column", "gap": "1rem"}}>
                    {plan.weeks.map(lambda week: any, i: int -> any {
                        weekNum = week.week or (i + 1);
                        return <div key={i} style={{
                            "background": "var(--secondary)",
                            "padding": "1.25rem",
                            "borderRadius": "8px",
                            "borderLeft": "4px solid #f59e0b"
                        }}>
                            <div style={{"display": "flex", "alignItems": "center", "gap": "0.75rem", "marginBottom": "0.5rem"}}>
                                <div style={{
                                    "width": "32px",
                                    "height": "32px",
                                    "borderRadius": "50%",
                                    "background": "#f59e0b",
                                    "color": "white",
                                    "display": "flex",
                                    "alignItems": "center",
                                    "justifyContent": "center",
                                    "fontWeight": "700",
                                    "fontSize": "0.875rem",
                                    "flexShrink": "0"
                                }}>
                                    {weekNum}
                                </div>
                                <div style={{"fontWeight": "600", "color": "var(--foreground)", "fontSize": "1rem"}}>
                                    Week {weekNum}
                                </div>
                            </div>
                            {week.focus and <div style={{"color": "var(--card-foreground)", "marginBottom": "0.75rem", "paddingLeft": "2.75rem"}}>{week.focus}</div>}
                            {week.resources and Array.isArray(week.resources) and week.resources.length > 0 and <div style={{"paddingLeft": "2.75rem"}}>
                                <div style={{"fontSize": "0.875rem", "fontWeight": "600", "color": "var(--muted-foreground)", "marginBottom": "0.5rem"}}>Resources:</div>
                                <div style={{"display": "flex", "flexDirection": "column", "gap": "0.25rem"}}>
                                    {week.resources.map(lambda res: str, j: int -> any {
                                        return <div key={j} style={{"fontSize": "0.875rem", "color": "var(--card-foreground)"}}>• {res}</div>;
                                    })}
                                </div>
                            </div>}
                        </div>;
                    })}
                </div>
            </div>}
        </div>}
    </div>;
}
