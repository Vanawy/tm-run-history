[Setting category="General" name="Limit" description="Limit amount of runs displayed in history"]
uint runsLimit = 10;

[Setting category="General" name="PBs only" description="Save only PB runs"]
bool isPBOnly = false;

[Setting category="General" name="Default target medal" description="Target medal chosen on map load"]
DefaultTargetMedalOptions defaultTarget = DefaultTargetMedalOptions::closestNotBeaten;


[Setting category="Display" name="Window position"]
vec2 anchor = vec2(0, 170);
[Setting category="Display" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;
[Setting category="Display" name="Small action buttons"]
bool smallButtons = true;
[Setting category="Display" name="Hide with overlay"]
bool hideWithOverlay = false;

[Setting hidden]
string deltasString = DEFAULT_DELTAS;

bool autoChangeTarget = true;

array<Run> runs;

enum DefaultTargetMedalOptions {
    closestNotBeaten,
    pb,
#if DEPENDENCY_CHAMPIONMEDALS
    champion,
#endif
    author,
    gold,
    silver,
    bronze,
}

const string MEDAL_ICON = Icons::Circle;

array<string> colors = {
    "\\$964", // bronze medal
    "\\$899", // silver medal
    "\\$db4", // gold medal
    "\\$071", // author medal
#if DEPENDENCY_CHAMPIONMEDALS
    "\\$f69", // champion medal
#endif
};


const string PB_TEXT = "\\$0ff" + Icons::User;
const string CUSTOM_TEXT = "\\$c11" + Icons::Crosshairs;

Target@ bronze  = Target(colors[0] + MEDAL_ICON);
Target@ silver  = Target(colors[1] + MEDAL_ICON);
Target@ gold    = Target(colors[2] + MEDAL_ICON);
Target@ author  = Target(colors[3] + MEDAL_ICON);
#if DEPENDENCY_CHAMPIONMEDALS
Target@ champion  = Target(colors[4] + MEDAL_ICON);
#endif

Target@ pb = Target(PB_TEXT, 0);
Target@ custom = Target(CUSTOM_TEXT, 0);

array<Target@> targets = {
    pb, // Should be first for correct target autoselection
    custom,
#if DEPENDENCY_CHAMPIONMEDALS
    champion,
#endif
    author,
    gold,
    silver,
    bronze
};

Target@ currentTarget = null;



[SettingsTab name="Feedback" icon="Bug"]
void RenderFeedbackTab()
{
    UI::Text("Thank you for using " + TEXT_PLUGIN_NAME + "!");
    UI::Text("To report issues or send feedback use buttons below " + "\\$f69" + Icons::Heart);

    if (UI::Button("GitHub " + Icons::Github)) {
        OpenBrowserURL("https://github.com/Vanawy/tm-run-history/issues");
    }
    if (UI::Button("Twitter " + Icons::Twitter)) {
        OpenBrowserURL("https://twitter.com/vanawy");
    }
}

Thresholds::Table thresholdsTable = Thresholds::Table();

[SettingsTab name="Thresholds" icon="ClockO"]
void RenderThresholdsTab()
{
    if (UI::Button("Reset to default")) {
        deltasString = DEFAULT_DELTAS;
        thresholdsTable.FromString(deltasString);
    }
    UI::Text("Configure delta time thresholds");
    UI::NewLine();
    thresholdsTable.Render();
    if (thresholdsTable.isChanged) {
        deltasString = thresholdsTable.ToString();
        thresholdsTable.isChanged = false;
        UpdateRuns();
    }
}


void RenderChangeTargetPopup()
{
    if (!UI::IsOverlayShown()) return;
    if (UI::BeginPopup(POPUP_CHANGE_TARGET)) {
        string text = TEXT_DEFAULT_TARGET;
        if (!autoChangeTarget && @currentTarget != null) {
            text = currentTarget.icon + "\\$fff" + Time::Format(currentTarget.time);
        }
        if (UI::BeginCombo(Icons::ClockO, text)) {
            if (UI::Selectable(TEXT_DEFAULT_TARGET, autoChangeTarget)) {
                autoChangeTarget = true;
                UpdateCurrentTarget();
                UI::CloseCurrentPopup();
            }
            for(uint i = 0; i < targets.Length; i++) {
                Target @target = @targets[i];
                if (target.time == 0) {
                    continue;
                }            
                if (UI::Selectable(
                    target.icon + "\\$fff" + Time::Format(target.time), 
                    @target == @currentTarget
                )) {
                    print("Target change " + target.icon);
                    autoChangeTarget = false;
                    SetTarget(target);
                    UI::CloseCurrentPopup();
                }
            }
            
            UI::EndCombo();
        }
        // autoChangeTarget = UI::Checkbox("Auto change target", autoChangeTarget);
        UI::EndPopup();
    }
}

float newTime = 0;
void RenderAddTargetPopup()
{
    if (!UI::IsOverlayShown()) return;
    if (UI::BeginPopup(POPUP_ADD_TARGET)) {
        if (custom.time > 0) {
            UI::Text("Custom time - " + Time::Format(custom.time));
            UI::Text("Change custom time");
        } else {
            UI::Text("Add custom time");
        }
        newTime = UI::InputFloat("seconds", newTime, 0.005);
        UI::Text("New time " + Time::Format(int(newTime) * 1000));
        if (UI::Button(TEXT_ADD)) {
            custom.time = int(newTime) * 1000;
            newTime = 0;
            custom.time = custom.time;
            SetTarget(custom); 
        }
        UI::EndPopup();
    }
}


void RenderActions()
{
    if (!UI::IsOverlayShown()) return;

    // UI::Columns(1);
    if (UI::Button(smallButtons ? ICON_CLEAR : TEXT_CLEAR)) {
        OnClearHistory();
    }
    if (smallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_CLEAR);
        UI::EndTooltip();
    }
    if (smallButtons) {
        UI::SameLine();
    }
    if (UI::Button(smallButtons ? ICON_CHANGE : TEXT_CHANGE)) {
        UI::OpenPopup(POPUP_CHANGE_TARGET);
    }
    if (smallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_CHANGE);
        UI::EndTooltip();
    }
    if (smallButtons) {
        UI::SameLine();
    }
    if (UI::Button(smallButtons ? ICON_ADD : TEXT_ADD)) {
        UI::OpenPopup(POPUP_ADD_TARGET);
    }
    if (smallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_ADD);
        UI::EndTooltip();
    }

    RenderChangeTargetPopup();
    RenderAddTargetPopup();
}

void AddTime(int time) 
{
    if (isPBOnly && pb.time > 0 && time > pb.time) {
        // Ignore non PB time if setting enabled
        return;
    }
    int count = runs.Length;
    runs.Resize(count + 1);
    runs[count].time = time;

    if (isPBOnly && (pb.time < 1 || time < pb.time)) {
        int delta = pb.time - time;
        string color = "\\$0ff";
        runs[count].deltaTextOverride = color + "PB";
        if (pb.time > 0 && delta > 0) {
            runs[count].deltaTextOverride = color + "-" + Time::Format(delta, true, false);
        }
    }
    UpdateRunDelta(runs[count]);
    count = runs.Length;
    for (int i = 0; i < count; i++) {
        runs[i].hidden = false;
        if (i < (count - runsLimit)) {
            runs[i].hidden = true;
        }
    }
}

void UpdateRunDelta(Run@ record) 
{
    if (@currentTarget == null) {
        return;
    }
    record.UpdateDelta(currentTarget);
    record.style = "\\$" + thresholdsTable.GetColorByDelta(record.delta);
}

void ClearRuns() 
{
    runs.Resize(0);
}

void Render() {
    auto app = cast<CTrackMania@>(GetApp());
    
    auto map = app.RootMap;
    
    if(!UI::IsGameUIVisible()) {
        return;
    }

    if (hideWithOverlay && !UI::IsOverlayShown()) {
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
        if(UI::BeginTable(TEXT_PLUGIN_NAME, numCols, UI::TableFlags::SizingFixedFit)) {
            
            // print(targets.Length);
            UI::TableNextRow();
            
                UI::TableNextColumn();

            if (@currentTarget != null && currentTarget.time > 0) {
                UI::Text(currentTarget.icon);
                UI::TableNextColumn();
                UI::Text("\\$fff" + Time::Format(currentTarget.time));
            } else {
                UI::Text(Icons::Spinner);
                UI::TableNextColumn();
                UI::Text("-:--.---");
            }
            UI::TableNextColumn();
            UI::Text(Icons::Flag);

            UI::TableNextRow();
            for(uint i = 0; i < numCols; i++) {
                UI::TableNextColumn();
                UI::Separator();
            }

            for(uint i = 0; i < runs.Length; i++) {
                if(runs[i].hidden) {
                    continue;
                }
                UI::TableNextRow();
                
                UI::TableNextColumn();
                UI::Text("" + (i + 1));
                
                UI::TableNextColumn();
                UI::Text("\\$fff" + Time::Format(runs[i].time));

                UI::TableNextColumn();
                runs[i].DrawDelta();
            };
            UI::EndTable();
        }
        UI::EndGroup();

        RenderActions();
        
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

    // init delta thresholds table
    thresholdsTable.FromString(deltasString);

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
    if (champion.time != int(newTime)) {
        champion.time = newTime;
        print("Champion Medal detected: " + Time::Format(champion.time));
        UpdateCurrentTarget();
    }
}
#endif

void UpdateCurrentTarget()
{
    if (!autoChangeTarget) {
        UpdateRuns();
        return;
    } 
    if (defaultTarget == DefaultTargetMedalOptions::pb) {
        @currentTarget = @pb;
    } else {
        uint maxTargetId = 1;

        // TODO: Refactor this in next update 
        // HOTFIX
        uint offset = 0;
#if DEPENDENCY_CHAMPIONMEDALS
        offset = 1;
#endif
        switch (defaultTarget) {
#if DEPENDENCY_CHAMPIONMEDALS
            case DefaultTargetMedalOptions::champion:
                maxTargetId = 2;
                break;
#endif
            case DefaultTargetMedalOptions::author:
                maxTargetId = 2 + offset;
                break;
            case DefaultTargetMedalOptions::gold:
                maxTargetId = 3 + offset;
                break;
            case DefaultTargetMedalOptions::silver:
                maxTargetId = 4 + offset;
                break;
            default:
                maxTargetId = 5 + offset;
                break;
        }

        @currentTarget = targets[1];
        for(uint i = 2; i <= maxTargetId; i++) {
            if (
                currentTarget.time < 1 
                || (targets[i].time > 0 
                && (targets[i].time < pb.time || pb.time < 1) 
                && targets[i].time > currentTarget.time)
            ) {
                @currentTarget = @targets[i];
            }
        }
    }
    if (pb.time > 0 && currentTarget.time > pb.time) {
        @currentTarget = @pb;
    }
    SetTarget(currentTarget);
}

void UpdateRuns()
{
    for (int i = 0; i < int(runs.Length); i++) {
        UpdateRunDelta(runs[i]);
    }
}

void SetTarget(Target @target) {
    @currentTarget = target;
    print(target.icon);
    UpdateRuns();
}

string BoolToStr(bool value) {
    return value ? ("\\$0f0" + Icons::Check) : ("\\$f00" + Icons::Times);
}

void OnNewGhost(const MLFeed::GhostInfo_V2@ ghost) {
    if (!ghost.IsLocalPlayer || ghost.IsPersonalBest) {
        return;
    }
    int lastTime = ghost.Result_Time;
    AddTime(lastTime);
    if (pb.time < 1 || lastTime < pb.time) {
        pb.time = lastTime;
    }
    UpdateCurrentTarget();
}

void OnMapChange(CGameCtnChallenge@ map) {
    ClearRuns();

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
    custom.time = 0;
    
    UpdateCurrentTarget();
}

void OnClearHistory() {
    runs.Resize(0);
}

