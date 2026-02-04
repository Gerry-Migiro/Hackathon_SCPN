# Backend Code
import from byllm.lib { Model }
import from json { loads, dumps }
import from urllib.request { urlopen, Request }
import from jaclang.pycore.runtime { JacBasics }

glob llm = Model(model_name="gemini/gemini-2.5-flash");

# --- Nodes ---
node User {
    has owner_id: str = "";  # Store the root ID to ensure user isolation
    has name: str = "";
    has interests: list = [];
    has goals: list = [];
    has target_role: str = "";
    has last_roadmap_plan: str = "[]";
    has last_strategy: str = "[]";
    has last_market: str = "[]";
}

node Role {
    has title: str = "";
    has salary_range: str = "N/A";
    has description: str = "";
}

node Skill {
    has name: str = "";
}

node Course {
    has title: str = "";
    has url: str = "";
    has duration: str = "";
}

node JobPosting {
    has title: str = "";
    has company: str = "";
    has posted_date: str = "";
}

# --- Edges ---
edge UserSkill {
    has level: int = 0;
}

edge RequiresSkill {
    has importance: int = 5;  # 1-10 scale: how critical this skill is for the role
}

edge PrerequisiteOf {
    has difficulty_gap: int = 1;  # How many levels harder (1=easy step, 5=major leap)
}

# Agent 1: Career Strategy Analyzer - Identifies strengths and skill gaps
def analyze_career_strategy(
    user_skills: list, target_role: str, user_interests: list, context: str
) -> str by llm(method="Reason");

# Agent 2: Market Research Analyzer - Researches job market trends
def analyze_market(
    role_title: str, context: str
) -> str by llm(method="Reason");

# Agent 3: Learning Path Designer - Creates personalized learning roadmap
def create_learning_plan(
    missing_skills: list, timeline: str, context: str
) -> str by llm(method="Reason");

"""Extract technical skills from resume text. Return only concrete tools, languages, frameworks, and technologies as nouns. Skip job titles, company names, soft skills, general and unecessary descriptions."""
def resume_parser(resume_text: str) -> list[str] by llm(method="Reason");

# --- OSP Graph Traversal Walker ---
walker calculate_role_match {
    has target_role: str;
    has match_score: float = 0.0;
    has required_skills: list = [];
    has missing_skills: list = [];
    has matched_skills: list = [];

    can find_role with `root entry {
        # Find target role node using graph traversal
        role_node = None;
        for r in [here-->](`?Role) {
            if r.title == self.target_role {
                role_node = r;
                visit role_node;
            }
        }
        if not role_node {
            report {"error": "Role not found", "score": 0.0} ;
        }
    }

    can score_match with Role entry {
        # OSP Graph Reasoning: Traverse Role->RequiresSkill->Skill edges
        total_importance = 0;
        matched_importance = 0;

        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else "";
        
        # Find User node by owner_id
        user_node = None;
        for u in [root-->](`?User) {
            if u.owner_id == my_root_id {
                user_node = u;
                break;
            }
        }

        if not user_node {
            report {"error": "User not found", "score": 0.0} ;
            return;
        }

        # Collect user's skills
        user_skills = [];
        for s in [user_node->:UserSkill:->] {
            user_skills.append(s.name);
        }

        # Traverse role requirements using OSP edge filtering
        for skill_edge in [here->:RequiresSkill:->] {
            skill_node = [here->:RequiresSkill:->(`?Skill)][-1];
            if skill_node {
                importance = 5;  # default
                # Get actual importance from edge
                for e in [here->:RequiresSkill:target==skill_node:->] {
                    importance = e.importance if hasattr(e, 'importance') else 5;
                    break;
                }
                total_importance += importance;
                self.required_skills.append(skill_node.name);
                # Check if user has this skill
                if skill_node.name in user_skills {
                    matched_importance += importance;
                    self.matched_skills.append(skill_node.name);
                } else {
                    self.missing_skills.append(skill_node.name);
                }
            }
        }

        # Calculate match score (0-100)
        if total_importance > 0 {
            self.match_score = (matched_importance / total_importance) * 100;
        } else {
            self.match_score = 0.0;
        }

        report {
            "role": self.target_role,
            "match_score": round(self.match_score, 2),
            "required_skills": self.required_skills,
            "matched_skills": self.matched_skills,
            "missing_skills": self.missing_skills,
            "total_importance": total_importance,
            "matched_importance": matched_importance
        } ;
    }
}

# --- Walkers ---
walker seed_database {
    can seed with `root entry {
        # Check if already seeded by looking for jobs
        existing_jobs = [here-->](`?JobPosting);
        if len(existing_jobs) > 0 {
            print("Database already seeded");
            return;
        }

        print("Seeding database...");

        # Create Roles
        here ++> Role(
            title="Software Developer",
            salary_range="$80k - $150k",
            description="Builds software applications"
        );
        here ++> Role(
            title="Data Scientist",
            salary_range="$100k - $180k",
            description="Analyzes complex data"
        );
        here ++> Role(
            title="Product Manager",
            salary_range="$90k - $160k",
            description="Oversees product development"
        );
        here ++> Role(
            title="DevOps Engineer",
            salary_range="$90k - $160k",
            description="Manages infrastructure and deployments"
        );
        here ++> Role(
            title="UX Designer",
            salary_range="$70k - $130k",
            description="Designs user experiences"
        );

        # Create Courses
        here ++> Course(
            title="Python Programming Masterclass",
            url="https://udemy.com/python",
            duration="40 hours"
        );
        here ++> Course(
            title="Data Science Bootcamp",
            url="https://coursera.org/data-science",
            duration="3 months"
        );
        here ++> Course(
            title="Web Development Complete",
            url="https://udemy.com/web-dev",
            duration="60 hours"
        );
        here ++> Course(
            title="Machine Learning Specialization",
            url="https://coursera.org/ml",
            duration="4 months"
        );
        here ++> Course(
            title="AWS Cloud Practitioner",
            url="https://aws.amazon.com/training",
            duration="20 hours"
        );
        here ++> Course(
            title="React Advanced Patterns",
            url="https://frontendmasters.com/react",
            duration="25 hours"
        );
        here ++> Course(
            title="SQL for Data Analysis",
            url="https://udacity.com/sql",
            duration="30 hours"
        );
        here ++> Course(
            title="Product Management Fundamentals",
            url="https://coursera.org/product-management",
            duration="6 weeks"
        );
        here ++> Course(
            title="DevOps Engineering Bootcamp",
            url="https://udemy.com/devops",
            duration="50 hours"
        );
        here ++> Course(
            title="UX Design Principles",
            url="https://interaction-design.org/ux",
            duration="8 weeks"
        );

        # Create Skills
        skill_python = here ++> Skill(name="Python");
        skill_js = here ++> Skill(name="JavaScript");
        skill_react = here ++> Skill(name="React");
        skill_ml = here ++> Skill(name="Machine Learning");
        skill_aws = here ++> Skill(name="AWS");
        skill_pandas = here ++> Skill(name="Pandas");
        skill_sql = here ++> Skill(name="SQL");
        skill_docker = here ++> Skill(name="Docker");
        skill_figma = here ++> Skill(name="Figma");
        skill_agile = here ++> Skill(name="Agile");

        # OSP Graph: Create Role->Skill relationships with RequiresSkill edges
        # Get role references
        roles = [here-->](`?Role);
        role_softdev = None;
        role_datascience = None;
        role_productmgr = None;
        role_devops = None;
        role_ux = None;

        for r in roles {
            if r.title == "Software Developer" {
                role_softdev = r;
            } elif r.title == "Data Scientist" {
                role_datascience = r;
            } elif r.title == "Product Manager" {
                role_productmgr = r;
            } elif r.title == "DevOps Engineer" {
                role_devops = r;
            } elif r.title == "UX Designer" {
                role_ux = r;
            }
        }

        # Software Developer requires these skills (importance 1-10)
        if role_softdev {
            role_softdev +>: RequiresSkill(importance=9) :+> skill_python;
            role_softdev +>: RequiresSkill(importance=8) :+> skill_js;
            role_softdev +>: RequiresSkill(importance=7) :+> skill_react;
            role_softdev +>: RequiresSkill(importance=6) :+> skill_sql;
            role_softdev +>: RequiresSkill(importance=5) :+> skill_docker;
        }

        # Data Scientist requires these skills
        if role_datascience {
            role_datascience +>: RequiresSkill(importance=10) :+> skill_python;
            role_datascience +>: RequiresSkill(importance=9) :+> skill_ml;
            role_datascience +>: RequiresSkill(importance=8) :+> skill_pandas;
            role_datascience +>: RequiresSkill(importance=7) :+> skill_sql;
        }

        # DevOps Engineer requires these skills
        if role_devops {
            role_devops +>: RequiresSkill(importance=9) :+> skill_docker;
            role_devops +>: RequiresSkill(importance=8) :+> skill_aws;
            role_devops +>: RequiresSkill(importance=7) :+> skill_python;
            role_devops +>: RequiresSkill(importance=6) :+> skill_sql;
        }

        # Product Manager requires these skills
        if role_productmgr {
            role_productmgr +>: RequiresSkill(importance=8) :+> skill_agile;
            role_productmgr +>: RequiresSkill(importance=5) :+> skill_sql;
        }
        # UX Designer requires these skills
        if role_ux {
            role_ux +>: RequiresSkill(importance=10) :+> skill_figma;
            role_ux +>: RequiresSkill(importance=4) :+> skill_js;
        }
        # OSP Graph: Create Skill->Skill prerequisites with PrerequisiteOf edges
        # Python is prerequisite for more advanced skills
        skill_python +>: PrerequisiteOf(difficulty_gap=2) :+> skill_pandas;
        skill_python +>: PrerequisiteOf(difficulty_gap=3) :+> skill_ml;
        skill_js +>: PrerequisiteOf(difficulty_gap=2) :+> skill_react;
        skill_sql +>: PrerequisiteOf(difficulty_gap=3) :+> skill_ml;

        # Create Job Postings
        here ++> JobPosting(
            title="Software Developer",
            company="TechCorp Inc.",
            posted_date="2024-12-01"
        );
        here ++> JobPosting(
            title="Senior Software Engineer",
            company="Google",
            posted_date="2024-12-05"
        );
        here ++> JobPosting(
            title="Full Stack Developer", company="Microsoft", posted_date="2024-12-03"
        );
        here ++> JobPosting(
            title="Data Scientist", company="Amazon", posted_date="2024-12-02"
        );
        here ++> JobPosting(
            title="ML Engineer", company="Meta", posted_date="2024-12-06"
        );
        here ++> JobPosting(
            title="Product Manager", company="Apple", posted_date="2024-12-04"
        );
        here ++> JobPosting(
            title="Senior Product Manager", company="Netflix", posted_date="2024-12-07"
        );
        here ++> JobPosting(
            title="DevOps Engineer", company="Spotify", posted_date="2024-12-01"
        );
        here ++> JobPosting(
            title="Cloud Engineer", company="IBM", posted_date="2024-12-05"
        );
        here ++> JobPosting(
            title="UX Designer", company="Adobe", posted_date="2024-12-03"
        );
        here ++> JobPosting(
            title="Senior UX/UI Designer", company="Figma", posted_date="2024-12-06"
        );
        here ++> JobPosting(
            title="Backend Developer", company="Stripe", posted_date="2024-12-02"
        );
        here ++> JobPosting(
            title="Frontend Developer", company="Airbnb", posted_date="2024-12-04"
        );
        here ++> JobPosting(
            title="Data Analyst", company="Salesforce", posted_date="2024-12-07"
        );
        here ++> JobPosting(
            title="Python Developer", company="Dropbox", posted_date="2024-12-01"
        );

        print("Database seeded successfully");
    }
}
walker get_all_roles {
    can return_roles with `root entry {
        roles = [here-->](`?Role);
        if len(roles) == 0 {
            # Auto-seed if no roles exist
            here spawn seed_database();
            roles = [here-->](`?Role);
        }

        role_list = [];
        for r in roles {
            role_list.append(
                {
                    "title": r.title,
                    "description": r.description,
                    "salary": r.salary_range
                }
            );
        }
        report role_list ;
    }
}
walker get_recommended_courses {
    can recommend with `root entry {
        missing_skills = [];
        
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }

        # Try to find user and their missing skills for target role
        if my_user {
            if my_user.target_role {
                try {
                    # Reuse existing walker logic to find gaps
                    matcher = calculate_role_match(target_role=my_user.target_role) spawn root;
                    if matcher and len(matcher.reports) > 0 {
                        report_data = matcher.reports[0];
                        if "missing_skills" in report_data {
                            missing_skills = report_data["missing_skills"];
                        }
                    }
                } except Exception as e {
                    print("Error calculating skills for courses: " + str(e));
                }
            }
        }

        # Get all courses
        all_courses = [-->](`?Course);
        course_list = [];
        
        for course in all_courses {
            is_relevant = False;
            
            # If we have missing skills, filter for them
            if len(missing_skills) > 0 {
                for skill in missing_skills {
                    # Simple keyword match: if skill name is in course title
                    if skill.lower() in course.title.lower() {
                        is_relevant = True;
                        break;
                    }
                }
            } else {
                # If no specific gaps identified, show everything (or fallback logic)
                is_relevant = True;
            }

            if is_relevant {
                course_list.append(
                    {"title": course.title, "url": course.url, "duration": course.duration}
                );
            }
        }
        
        # Fallback: if filtering resulted in 0 courses, return all
        if len(course_list) == 0 {
             for course in all_courses {
                course_list.append(
                    {"title": course.title, "url": course.url, "duration": course.duration}
                );
            }
        }

        report course_list ;
    }
}

# Resume Parsing Walker: Extracts skills, experience, education from resume text
walker parse_resume {
    has resume_text: str;

    can extract_info with `root entry {
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        
        if my_user {
            visit my_user;
        } else {
            # Create new User for this user's root
            new_user = here ++> User(owner_id=my_root_id, name="", interests=[], goals=[], target_role="");
            visit new_user;
        }
    }

    can parse_and_update with User entry {
        # Use AI agent to extract skills from resume text
        skill_list = resume_parser(resume_text=self.resume_text);

        # Get current skills to avoid duplicates
        current_skills = [];
        for s in [here->:UserSkill:->] {
            current_skills.append(s.name);
        }

        # Add new skills from resume
        added_skills = [];
        skipped_skills = [];

        for skill_name in skill_list {
            if skill_name not in current_skills {
                # Create new skill and connect (simple approach)
                here +>: UserSkill(level=50) :+> Skill(name=skill_name);
                added_skills.append(skill_name);
            } else {
                skipped_skills.append(skill_name);
            }
        }

        # Return structured resume data with update info
        report {
            "skills": skill_list,
            "added_skills": added_skills,
            "skipped_skills": skipped_skills,
            "total_skills": len(current_skills) + len(added_skills)
        } ;
    }
}
walker get_profile {
    can get_profile with `root entry {
        # Workaround for jaclang bug: get the actual user's root from context
        ctx = JacBasics.get_context();
        
        # Get the actual entry node (user's root)
        if ctx.entry_node {
            my_root_id = str(ctx.entry_node.id);
            actual_root = ctx.entry_node.archetype;
        } else {
            my_root_id = str(here.__jac__.id);
            actual_root = here;
        }
        
        print(f"DEBUG get_profile: my_root_id = {my_root_id}");
        print(f"DEBUG get_profile: here.__jac__.id = {here.__jac__.id}");
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        
        if my_user {
            visit my_user;
        } else {
            # Create new User with owner_id set to this user's root
            new_user = here ++> User(owner_id=my_root_id, name="", interests=[], goals=[], target_role="");
            visit new_user;
        }
    }

    can return_profile with User entry {
        skills = [];
        for s in [here->:UserSkill:->] {
            skills.append(s.name);
        }
        report {
            "name": here.name,
            "interests": here.interests,
            "goals": here.goals,
            "skills": skills,
            "target_role": here.target_role,
            "last_roadmap_plan": here.last_roadmap_plan,
            "last_strategy": here.last_strategy,
            "last_market": here.last_market
        } ;
    }
}
walker update_profile {
    has name: any = None;
    has interests: any = None;
    has goals: any = None;
    has target_role: any = None;

    can start with `root entry {
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        
        if my_user {
            visit my_user;
        } else {
            # Create new User for this user's root
            new_user = here ++> User(
                owner_id=my_root_id,
                name=self.name if self.name != None else "",
                interests=self.interests if self.interests != None else [],
                goals=self.goals if self.goals != None else [],
                target_role=self.target_role if self.target_role != None else ""
            );
            visit new_user;
        }
    }

    can update with User entry {
        if self.name != None {
            here.name = self.name;
        }
        if self.interests != None {
            here.interests = self.interests;
        }
        if self.goals != None {
            here.goals = self.goals;
        }
        if self.target_role != None {
            here.target_role = self.target_role;
        }
        report {"status": "success", "message": "Profile updated"} ;
    }
}

walker add_skill {
    has skill_name: str;

    can start with `root entry {
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        
        if my_user {
            visit my_user;
        } else {
            report {"error": "User not found"} ;
        }
    }

    can add with User entry {
        # Check if skill already exists
        exists: bool = False;
        for s in [here->:UserSkill:->] {
            if s.name == self.skill_name {
                exists = True;
                break;
            }
        }
        if not exists {
            here +>: UserSkill(level=50) :+> Skill(name=self.skill_name);
        }
        report {"status": "success", "message": "Added skill " + str(self.skill_name)} ;
    }
}
walker delete_skill {
    has skill_name: str;

    can start with `root entry {
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        
        if my_user {
            visit my_user;
        } else {
            report {"error": "User not found"} ;
        }
    }

    can delete with User entry {
        deleted: bool = False;
        # Delete all matching skill nodes connected to the user
        for skill_node in [here->:UserSkill:->] {
            if skill_node.name == self.skill_name {
                del skill_node ;
                deleted = True;
            }
        }
        status: str = "not-found";
        message: str = "Skill " + str(self.skill_name) + " not found";
        if deleted {
            status = "success";
            message = "Deleted skill " + str(self.skill_name);
        }
        report {"status": status, "message": message} ;
    }
}
walker generate_roadmap {
    has target_role: str;

    can start with `root entry {
        role_node = None;
        for r in [here-->](`?Role) {
            if r.title == self.target_role {
                role_node = r;
                break;
            }
        }
        if not role_node {
            role_node = here ++> Role(title=self.target_role, salary_range="Unknown");
        }
        
        # Workaround: Get actual user's root from context
        ctx = JacBasics.get_context();
        my_root_id = str(ctx.entry_node.id) if ctx.entry_node else str(here.__jac__.id);
        
        # Find User node by owner_id
        my_user = None;
        for u in [here-->](`?User) {
            if u.owner_id == my_root_id {
                my_user = u;
                break;
            }
        }
        if my_user {
            visit my_user;
        }
    }

    can analyze with User entry {
        user_skills = [];
        for s in [here->:UserSkill:->] {
            user_skills.append(s.name);
        }

        print("Generating roadmap for role: " + self.target_role);
        print("User skills: " + str(user_skills));

        
        # OSP Graph Analysis: Calculate role match using graph traversal
        graph_match = None;
        try {
            matcher = calculate_role_match(target_role=self.target_role) spawn root;
            if matcher and len(matcher.reports) > 0 {
                graph_match = matcher.reports[0];
                print(
                    "OSP Graph Match Score: " + str(graph_match.get("match_score", 0)) + "%"
                );
            }
        } except Exception as e {
            print("Graph match calculation skipped: " + str(e));
        }

        # Call AI Agents
        strategy = analyze_career_strategy(
            user_skills,
            self.target_role,
            here.interests,
            context="Return ONLY a valid JSON object. No Markdown. No code blocks. Structure: { 'strengths': [], 'gaps': [], 'recommendation': '' }"
        );
        print("Strategy generated: " + str(bool(strategy)));

        market = analyze_market(
            self.target_role,
            context="Return ONLY a valid JSON object. No Markdown. No code blocks. Structure: { 'demand': 'High/Medium/Low', 'salary_range': '', 'top_companies': [] }"
        );
        print("Market analysis generated: " + str(bool(market)));

       
        # Extract gaps from strategy to create targeted learning plan
        gaps_list = [];
        try {
            # Clean up potential markdown code blocks from strategy response
            clean_strategy = strategy.replace("```json", "").replace("```", "").strip();
            strategy_obj = loads(clean_strategy);
            if "gaps" in strategy_obj {
                gaps_list = strategy_obj["gaps"];
            }
        } except Exception {
            print("Could not extract gaps from strategy");
            print("Strategy content: " + strategy);
        }

        # If no gaps found or extraction failed, use user skills as fallback
        if not gaps_list or len(gaps_list) == 0 {
            print("No gaps found, using skills for learning plan");
            gaps_list = user_skills;
        }

        print("Gaps/skills for learning plan: " + str(gaps_list));

        plan = create_learning_plan(
            gaps_list,
            "3 months",
            context="Return ONLY a valid JSON object. No Markdown. No code blocks. Structure: { 'weeks': [ { 'week': 1, 'focus': '', 'resources': [] } ] }. Create a learning plan to acquire these missing skills/gaps."
        );
        print("Learning plan generated: " + str(bool(plan)));

        # Save to user node for persistence
        here.last_strategy = strategy;
        here.last_market = market;
        here.last_roadmap_plan = plan;
        here.target_role = self.target_role;

        print("Reporting results...");

        # Include OSP graph match data in response
        response = {
            "target_role": self.target_role,
            "strategy": strategy,
            "market": market,
            "plan": plan
        };

        if graph_match {
            response["graph_match"] = graph_match;
        }

        report response ;
    }
}
walker fetch_jobs {
    has role_filter: str = "";

    can fetch with `root entry {
        jobs_list = [];

        try {
            url = "https://jobicy.com/api/v2/remote-jobs";

            request = Request(url);
            request.add_header("User-Agent", "Mozilla/5.0 (Career-Advisory-App)");
            response = urlopen(request);
            data = response.read().decode("utf-8");
            json_data = loads(data);  # parse JSON

            # Check that "jobs" key exists and is a list
            if "jobs" in json_data and type(json_data["jobs"]) == list and len(json_data["jobs"]) > 0 {
                for job in json_data["jobs"] {
                    if len(jobs_list) >= 50 { break; }

                    # Safe access to fields
                    job_title = job["jobTitle"] if "jobTitle" in job else "No Title";
                    company = job["companyName"] if "companyName" in job else "Unknown";
                    location = job["jobGeo"] if "jobGeo" in job else "Remote";
                    posted_date = job["pubDate"][:10] if "pubDate" in job else "N/A";

                    # Role filter
                    if self.role_filter != "" {
                        filter_lower = self.role_filter.lower();
                        title_lower = job_title.lower();
                        if filter_lower not in title_lower { continue; }
                    }

                    jobs_list.append(
                        {
                            "title": job_title,
                            "company": company,
                            "location": location,
                            "posted_date": posted_date,
                            "match_score": 85
                        }
                    );
                }
            }
        } except Exception as e {
            print(f"Error fetching jobs: {e}");
        }

        # Fallback to seeded jobs
        if len(jobs_list) == 0 {
            print("No jobs from API, using seeded data");
            all_jobs = [root-->](`?JobPosting);
            for job in all_jobs {
                if self.role_filter == "" or self.role_filter.lower() in job.title.lower() {
                    jobs_list.append(
                        {
                            "title": job.title,
                            "company": job.company,
                            "location": "Remote",
                            "posted_date": job.posted_date,
                            "match_score": 75
                        }
                    );
                }
            }
        }

        # Return jobs
        if len(jobs_list) > 0 {
            report jobs_list;
        } else {
            report [
                {
                    "title": "No jobs found",
                    "company": "Try a different search",
                    "posted_date": "N/A",
                    "match_score": 0
                }
            ];
        }
    }
}

# --- Frontend ---
cl import from "@jac-client/utils" { Router, Routes, Route }

cl import from .components.Navbar { Navbar }
cl import from .components.LoginPage { LoginPage }
cl import from .components.SignupPage { SignupPage }
cl import from .components.Dashboard { Dashboard }
cl import from .components.CareerPath { CareerPath }
cl import from .components.Jobs { Jobs }
cl import from .components.Profile { Profile }
cl import from .components.Courses { Courses }
cl import from .components.LandingPage { LandingPage }
cl import from .components.Onboarding { Onboarding }
# Import Global Styles
cl import ".globals.css";

cl def:pub app()  -> any {
    return <Router>
        <div className="app-container">
            <Navbar />
            <Routes>
                <Route
                    path="/"
                    element={<LandingPage />}
                />
                <Route
                    path="/dashboard"
                    element={<Dashboard />}
                />
                <Route
                    path="/onboarding"
                    element={<Onboarding />}
                />
                <Route
                    path="/login"
                    element={<LoginPage />}
                />
                <Route
                    path="/signup"
                    element={<SignupPage />}
                />
                <Route
                    path="/career"
                    element={<CareerPath />}
                />
                <Route
                    path="/jobs"
                    element={<Jobs />}
                />
                <Route
                    path="/profile"
                    element={<Profile />}
                />
                <Route
                    path="/courses"
                    element={<Courses />}
                />
            </Routes>
        </div>
    </Router>;
}
