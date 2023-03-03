[Setting category="General" name="Records Limit" description="Limit amount of records displayed in history"]
uint recordsLimit = 10;

[Setting category="Display" name="Window position"]
vec2 anchor = vec2(0, 170);

[Setting category="Display" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;

string pluginName = "RunHistory";

[SettingsTab name="Feedback" icon="Bug"]
void RenderSettings()
{
    UI::Text("Thank you for using " + pluginName + "!");
    UI::Text("To report issues or send feedback use buttons below " + "\\$f69" + Icons::Heart);

    if (UI::Button("GitHub " + Icons::Github)) {
        OpenBrowserURL("https://github.com/Vanawy/tm-run-history/issues");
    }
    if (UI::Button("Twitter " + Icons::Twitter)) {
        OpenBrowserURL("https://twitter.com/vanawy");
    }
}

array<Record> records;


array<string> colors = {
    "\\$964", // bronze medal
    "\\$899", // silver medal
    "\\$db4", // gold medal
    "\\$071", // author medal
#if DEPENDENCY_CHAMPIONMEDALS
    "\\$f69", // champion medal
#endif
};

const string MEDAL_ICON = Icons::Circle;

const string PB_TEXT = "\\$0ff" + Icons::User;

void AddTime(int time, string &in title = "") {
    int count = records.Length;
    records.Resize(count + 1);
    records[count].time = time;
    if (time < pb.time) {
        title = "PB";
    }
    records[count].title = title;
    count = records.Length;
    for (int i = 0; i < count; i++) {
        records[i].hidden = false;
        if (i < (count - recordsLimit)) {
            records[i].hidden = true;
        }
    }
}

void ClearRecords()
{
    records.Resize(0);
}

class Record {
    string title;
    int time;
    string style;
    bool hidden;

    Record(){}
    
    Record(string &in title, int time = -1, string &in style = "\\$fff") {
        this.title = title;
        this.time = time;
        this.style = style;
        this.hidden = false;
    }

    void DrawTitle() {
        UI::Text(this.style + this.title);
    }

    void DrawTime() {
        UI::Text(this.style + (this.time > 0 ? Time::Format(this.time) : "-:--.---"));
    }
    
    void DrawDelta(Record@ other) {
        int delta = other.time - this.time;
        if (delta < 0) {
            UI::Text("\\$7f7" + "New PB");
        } else if (delta >= 0) {
            string color = "f77";
            if (delta < 100) {
                color = "fc0";
            } else if (delta < 500) {
                color = "fa3";
            }
            UI::Text("\\$" + color + "+" + Time::Format(delta));
        }
    }
}


Record@ bronze  = Record(colors[0] + MEDAL_ICON);
Record@ silver  = Record(colors[1] + MEDAL_ICON);
Record@ gold    = Record(colors[2] + MEDAL_ICON);
Record@ author  = Record(colors[3] + MEDAL_ICON);
#if DEPENDENCY_CHAMPIONMEDALS
Record@ champion  = Record(colors[4] + MEDAL_ICON);
#endif

Record@ pb = Record(PB_TEXT, 0);

array<Record@> targets = {
    pb,
#if DEPENDENCY_CHAMPIONMEDALS
    champion,
#endif
    author,
    gold,
    silver,
    bronze
};

Record@ currentTarget = null;

void Render() {
    auto app = cast<CTrackMania@>(GetApp());
    
    auto map = app.RootMap;
    
    if(!UI::IsGameUIVisible()) {
        return;
    }
    
    if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
        if(lockPosition) {
            UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
        } else {
            UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
        }
        
        int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
        if (!UI::IsOverlayShown()) {
            windowFlags |= UI::WindowFlags::NoInputs;
        }

        UI::Begin("Run History", windowFlags);
        
        if(!lockPosition) {
            anchor = UI::GetWindowPos();
        }
        
        UI::BeginGroup();

        uint numCols = 3; 
        if(UI::BeginTable(pluginName, numCols, UI::TableFlags::SizingFixedFit)) {
            
            for(uint i = 0; i < targets.Length; i++) {
                if(targets[i].hidden) {
                    continue;
                }
                UI::TableNextRow();
                
                UI::TableNextColumn();
                targets[i].DrawTitle();
                
                UI::TableNextColumn();
                targets[i].DrawTime();

                UI::TableNextColumn();
                if (@targets[i] == @currentTarget) {
                UI::Text(Icons::Flag);
                }
            }

            UI::TableNextRow();
            for(uint i = 0; i < numCols; i++) {
                UI::TableNextColumn();
                UI::Separator();
            }

            for(uint i = 0; i < records.Length; i++) {
                if(records[i].hidden) {
                    continue;
                }
                UI::TableNextRow();
                
                UI::TableNextColumn();
                if (records[i].title.Length > 0) {
                    records[i].DrawTitle();
                } else {
                    UI::Text("" + (i + 1));
                }
                
                UI::TableNextColumn();
                records[i].DrawTime();

                UI::TableNextColumn();
                currentTarget.DrawDelta(records[i]);
            }
            
            UI::EndTable();
        }
        UI::EndGroup();
        
        UI::End();
    }
}

void Main() {
    string lastMapId = "";
    string lastGhostId = "";

#if DEPENDENCY_CHAMPIONMEDALS
    print("ChampionMedals detected");
#else
    warn("ChampionMedals not installed");
#endif

    while(true) {
        sleep(1000);

        auto gd = MLFeed::GetGhostData();
        if (gd !is null && gd.Ghosts_V2 !is null && gd.NbGhosts != 0) {
            auto lastGhost = @gd.Ghosts_V2[gd.NbGhosts - 1];
            if (lastGhostId != lastGhost.IdName) {
                lastGhostId = lastGhost.IdName;
                OnNewGhost(lastGhost);
            }
        }

        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app !is null) {
            auto map = @app.RootMap;
            if (map !is null && lastMapId != map.MapInfo.MapUid) {
                lastMapId = map.MapInfo.MapUid;
                OnMapChange(map);
            }
        }

#if DEPENDENCY_CHAMPIONMEDALS
        UpdateChampionTime();
#endif
    }
}

#if DEPENDENCY_CHAMPIONMEDALS
void UpdateChampionTime() {
    auto newTime = ChampionMedals::GetCMTime();
    if (champion.time != newTime) {
        champion.time = newTime;
        print("Champion Medal detected: " + Time::Format(champion.time));
        UpdateTargets();
    }
}
#endif

void UpdateTargets()
{
    @currentTarget = targets[1];
    for(uint i = 2; i < targets.Length; i++) {
        if (currentTarget.time < 1 || (targets[i].time > 0 && (targets[i].time < pb.time || pb.time < 1) && targets[i].time > currentTarget.time)) {
            @currentTarget = @targets[i];
        }
    }
    if (pb.time > 0 && currentTarget.time > pb.time) {
        @currentTarget = @pb;
    }
    for (uint i = 0; i < targets.Length; i++) {
        targets[i].hidden = true;
    }
    currentTarget.hidden = false;
}

string BoolToStr(bool value) {
    return value ? ("\\$0f0" + Icons::Check) : ("\\$f00" + Icons::Times);
}

void OnNewGhost(const MLFeed::GhostInfo_V2@ ghost) {
    int lastTime = ghost.Result_Time;
    AddTime(lastTime);
    if (pb.time < 1 || lastTime < pb.time) {
        pb.time = lastTime;
    }
    UpdateTargets();
}

void OnMapChange(CGameCtnChallenge@ map) {
    ClearRecords();

    author.time = map.TMObjective_AuthorTime;
    print("AT detected: " + Time::Format(author.time));

    bronze.time = map.TMObjective_BronzeTime;
    silver.time = map.TMObjective_SilverTime;
    gold.time   = map.TMObjective_GoldTime;
#if DEPENDENCY_CHAMPIONMEDALS
    champion.time = 0;
#endif

    auto app = cast<CTrackMania@>(GetApp());
    auto network = app.Network;
    if(network.ClientManiaAppPlayground !is null) {
        auto userMgr = network.ClientManiaAppPlayground.UserMgr;
        MwId userId;
        if (userMgr.Users.Length > 0) {
            userId = userMgr.Users[0].Id;
        } else {
            userId.Value = uint(-1);
        }
        
        auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
        uint newPbTime = scoreMgr.Map_GetRecord_v2(userId, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
        if (newPbTime != 0) {
            pb.time = newPbTime;
            print("PB detected: " + Time::Format(pb.time));
        }
    }

    UpdateTargets();
}

