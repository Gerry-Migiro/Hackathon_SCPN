import from "@jac-client/utils" { Link, useNavigate, jacIsLoggedIn, Navigate }
import from "react" { useEffect }

# Walker stubs for client-side spawning (actual implementation in app.jac)
walker update_profile {
    has name: str = "";
    has interests: list = [];
    has goals: list = [];
    has target_role: str = "";
}

walker add_skill {
    has skill_name: str = "";
}

walker get_profile {}

def:pub Onboarding() -> any {
    # Auth check first
    if not jacIsLoggedIn() {
        return <Navigate to="/login" />;
    }

    navigate = useNavigate();

    has currentStep: int = 0,
        name: str = "",
        currentRole: str = "",
        targetRole: str = "",
        interests: list = [],
        goals: list = [],
        skills: list = [],
        newSkill: str = "",
        timeline: str = "3months",
        saving: bool = False;

    # Step definitions
    steps = [
        {"name": "Personal Info", "icon": "user"},
        {"name": "Skills", "icon": "skills"},
        {"name": "Goals", "icon": "target"},
        {"name": "Summary", "icon": "check"}
    ];

    # Available options
    availableRoles = [
        {"title": "Software Engineer"},
        {"title": "Data Scientist"},
        {"title": "Product Manager"},
        {"title": "UX Designer"},
        {"title": "DevOps Engineer"},
        {"title": "Full Stack Developer"},
        {"title": "Machine Learning Engineer"},
        {"title": "Cloud Architect"}
    ];

    interestOptions = [
        "Artificial Intelligence",
        "Web Development",
        "Mobile Apps",
        "Cloud Computing",
        "Data Analytics",
        "Cybersecurity",
        "Blockchain",
        "Game Development"
    ];

    goalOptions = [
        "Get a new job",
        "Career transition",
        "Skill upgrade",
        "Start freelancing",
        "Build a startup",
        "Get promoted"
    ];

    skillSuggestions = [
        "Python", "JavaScript", "React", "Node.js", "SQL", 
        "Machine Learning", "AWS", "Docker", "Git", "TypeScript"
    ];

    def nextStep() -> None {
        if currentStep < 3 {
            currentStep = currentStep + 1;
        }
    }

    def prevStep() -> None {
        if currentStep > 0 {
            currentStep = currentStep - 1;
        }
    }

    def addSkill() -> None {
        if newSkill and not skills.includes(newSkill.trim()) {
            newList = skills.slice();
            newList.push(newSkill.trim());
            skills = newList;
            newSkill = "";
        }
    }

    def removeSkill(skill: str) -> None {
        skills = skills.filter(lambda s: str -> bool { return s != skill; });
    }

    def toggleItem(listName: str, item: str) -> None {
        if listName == "interests" {
            if interests.includes(item) {
                interests = interests.filter(lambda i: str -> bool { return i != item; });
            } else {
                newList = interests.slice();
                newList.push(item);
                interests = newList;
            }
        } elif listName == "goals" {
            if goals.includes(item) {
                goals = goals.filter(lambda g: str -> bool { return g != item; });
            } else {
                newList = goals.slice();
                newList.push(item);
                goals = newList;
            }
        } elif listName == "skills" {
            if skills.includes(item) {
                skills = skills.filter(lambda s: str -> bool { return s != item; });
            } else {
                newList = skills.slice();
                newList.push(item);
                skills = newList;
            }
        }
    }

    async def handleSubmit() -> None {
        saving = True;
        
        console.log("=== ONBOARDING SUBMIT ===");
        console.log("Name:", name);
        console.log("Target Role:", targetRole);
        console.log("Interests:", interests);
        console.log("Goals:", goals);
        console.log("Skills:", skills);
        
        try {
            # Update profile with all basic information
            console.log("Updating profile...");
            updateResult = await root spawn update_profile(
                name=name,
                interests=interests,
                goals=goals,
                target_role=targetRole
            );
            console.log("Profile update result:", updateResult);
            
            # Add all selected skills
            console.log("Adding skills...");
            for skill_name in skills {
                skillResult = await root spawn add_skill(skill_name=skill_name);
                console.log("Skill added:", skill_name, skillResult);
            }
            
            # Verify profile was saved
            console.log("Verifying profile...");
            finalProfile = await root spawn get_profile();
            console.log("Final profile:", finalProfile.reports[0] if finalProfile.reports else None);
            
            navigate("/dashboard");
        } except err {
            console.error("Error saving profile:", err);
        }
        saving = False;
    }

    progress = ((currentStep + 1) / 4) * 100;

    return <div className="onboarding-container">
        <div className="onboarding-card">
            <div className="onboarding-header">
                <h1>Welcome to Career Navigator</h1>
                <p>Let's personalize your experience</p>
            </div>

            <div className="progress-indicator">
                <div className="progress-bar-track">
                    <div className="progress-bar-fill" style={{"width": String(progress) + "%"}}></div>
                </div>
                <span className="progress-text">Step {currentStep + 1} of 4</span>
            </div>

            <div className="step-indicators">
                {steps.map(lambda s: dict, i: int -> any {
                    stepClass = "step-dot";
                    if i < currentStep {
                        stepClass = stepClass + " completed";
                    } elif i == currentStep {
                        stepClass = stepClass + " active";
                    }
                    return <div key={i} className={stepClass}>
                        <span className="step-number">{i + 1}</span>
                        <span className="step-name">{s["name"]}</span>
                    </div>;
                })}
            </div>

            <div className="step-content">
                {(currentStep == 0) and <div className="form-step">
                    <h2 className="step-heading">Personal Information</h2>
                    
                    <div className="form-group">
                        <label className="form-label">Full Name</label>
                        <input 
                            type="text"
                            className="form-input"
                            placeholder="Enter your full name"
                            value={name}
                            onChange={lambda e: any -> None { name = e.target.value; }}
                        />
                    </div>

                    <div className="form-group">
                        <label className="form-label">Current Role (Optional)</label>
                        <input 
                            type="text"
                            className="form-input"
                            placeholder="e.g. Junior Developer, Student"
                            value={currentRole}
                            onChange={lambda e: any -> None { currentRole = e.target.value; }}
                        />
                    </div>
                </div>}

                {(currentStep == 1) and <div className="form-step">
                    <h2 className="step-heading">Your Skills</h2>
                    
                    <div className="form-group">
                        <label className="form-label">Add Your Skills</label>
                        <div className="skill-input-row">
                            <input 
                                type="text"
                                className="form-input"
                                placeholder="Type a skill and click Add"
                                value={newSkill}
                                onChange={lambda e: any -> None { newSkill = e.target.value; }}
                                onKeyPress={lambda e: any -> None {
                                    if e.key == "Enter" {
                                        addSkill();
                                    }
                                }}
                            />
                            <button className="btn btn-secondary" onClick={lambda e: any -> None { addSkill(); }}>Add</button>
                        </div>
                    </div>

                    {(skills.length > 0) and <div className="skills-display">
                        {skills.map(lambda skill: str, i: int -> any {
                            return <span key={i} className="skill-chip">
                                {skill}
                                <button 
                                    className="chip-remove"
                                    onClick={lambda e: any -> None { removeSkill(skill); }}
                                >×</button>
                            </span>;
                        })}
                    </div>}

                    <div className="form-group">
                        <label className="form-label">Quick Add Popular Skills</label>
                        <div className="suggestion-chips">
                            {skillSuggestions.map(lambda skill: str, i: int -> any {
                                isSelected = skills.includes(skill);
                                chipClass = "chip" + (" chip-selected" if isSelected else "");
                                return <button 
                                    key={i}
                                    className={chipClass}
                                    onClick={lambda e: any -> None { toggleItem("skills", skill); }}
                                >
                                    {("✓ " + skill) if isSelected else skill}
                                </button>;
                            })}
                        </div>
                    </div>
                </div>}

                {(currentStep == 2) and <div className="form-step">
                    <h2 className="step-heading">Career Goals</h2>
                    
                    <div className="form-group">
                        <label className="form-label">Target Role</label>
                        <select 
                            className="form-select"
                            value={targetRole}
                            onChange={lambda e: any -> None { targetRole = e.target.value; }}
                        >
                            <option value="">Select your target role</option>
                            {availableRoles.map(lambda role: dict, i: int -> any {
                                return <option key={i} value={role["title"]}>{role["title"]}</option>;
                            })}
                        </select>
                    </div>

                    <div className="form-group">
                        <label className="form-label">Areas of Interest</label>
                        <div className="checkbox-grid">
                            {interestOptions.map(lambda interest: str, i: int -> any {
                                isSelected = interests.includes(interest);
                                itemClass = "checkbox-item" + (" checkbox-selected" if isSelected else "");
                                return <label key={i} className={itemClass}>
                                    <input 
                                        type="checkbox"
                                        checked={isSelected}
                                        onChange={lambda e: any -> None { toggleItem("interests", interest); }}
                                    />
                                    <span>{interest}</span>
                                </label>;
                            })}
                        </div>
                    </div>

                    <div className="form-group">
                        <label className="form-label">What are your goals?</label>
                        <div className="checkbox-grid">
                            {goalOptions.map(lambda goal: str, i: int -> any {
                                isSelected = goals.includes(goal);
                                itemClass = "checkbox-item" + (" checkbox-selected" if isSelected else "");
                                return <label key={i} className={itemClass}>
                                    <input 
                                        type="checkbox"
                                        checked={isSelected}
                                        onChange={lambda e: any -> None { toggleItem("goals", goal); }}
                                    />
                                    <span>{goal}</span>
                                </label>;
                            })}
                        </div>
                    </div>
                </div>}

                {(currentStep == 3) and <div className="form-step">
                    <h2 className="step-heading">Review Your Profile</h2>
                    
                    <div className="summary-card">
                        <div className="summary-section">
                            <h3>Personal Info</h3>
                            <div className="summary-item">
                                <span className="summary-label">Name:</span>
                                <span className="summary-value">{name or "Not set"}</span>
                            </div>
                            <div className="summary-item">
                                <span className="summary-label">Target Role:</span>
                                <span className="summary-value">{targetRole or "Not set"}</span>
                            </div>
                        </div>

                        <div className="summary-section">
                            <h3>Skills ({skills.length})</h3>
                            <div className="summary-chips">
                                {(skills.length > 0) and skills.map(lambda s: str, i: int -> any {
                                    return <span key={i} className="chip chip-small">{s}</span>;
                                })}
                                {(skills.length == 0) and <span className="text-muted">No skills added</span>}
                            </div>
                        </div>

                        <div className="summary-section">
                            <h3>Interests ({interests.length})</h3>
                            <div className="summary-chips">
                                {(interests.length > 0) and interests.map(lambda interest: str, i: int -> any {
                                    return <span key={i} className="chip chip-small">{interest}</span>;
                                })}
                                {(interests.length == 0) and <span className="text-muted">No interests selected</span>}
                            </div>
                        </div>

                        <div className="summary-section">
                            <h3>Goals ({goals.length})</h3>
                            <div className="summary-chips">
                                {(goals.length > 0) and goals.map(lambda goal: str, i: int -> any {
                                    return <span key={i} className="chip chip-small">{goal}</span>;
                                })}
                                {(goals.length == 0) and <span className="text-muted">No goals selected</span>}
                            </div>
                        </div>
                    </div>
                </div>}
            </div>

            <div className="onboarding-nav">
                {(currentStep > 0) and <button 
                    className="btn btn-outline"
                    onClick={lambda e: any -> None { prevStep(); }}
                >
                    ← Previous
                </button>}
                
                <div className="nav-spacer"></div>
                
                {(currentStep < 3) and <button 
                    className="btn btn-primary"
                    onClick={lambda e: any -> None { nextStep(); }}
                >
                    Next →
                </button>}
                
                {(currentStep == 3) and <button 
                    className="btn btn-primary btn-lg"
                    onClick={lambda e: any -> None { handleSubmit(); }}
                    disabled={saving}
                >
                    {("Saving...") if saving else ("Complete Setup →")}
                </button>}
            </div>
        </div>
    </div>;
}
