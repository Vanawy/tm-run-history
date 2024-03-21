

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

Target@ bronze  = Target("\\$964" + MEDAL_ICON);
Target@ silver  = Target("\\$899" + MEDAL_ICON);
Target@ gold    = Target("\\$db4" + MEDAL_ICON);
Target@ author  = Target( "\\$071" + MEDAL_ICON);
#if DEPENDENCY_CHAMPIONMEDALS
Target@ champion  = Target("\\$f69" + MEDAL_ICON);
#endif

Target@ pb = Target(ICON_PB, 0);
Target@ custom = Target(ICON_CUSTOM_TARGET, 0);

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

bool autoChangeTarget = true;

Target@ currentTarget = null;
Thresholds::Table thresholdsTable = Thresholds::Table();
History runs = History();

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
        UI::Text("New time " + Time::Format(int(newTime * 1000)));
        if (UI::Button(TEXT_ADD)) {
            custom.time = int(newTime * 1000);
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
    if (UI::Button(settingUseSmallButtons ? ICON_CLEAR : TEXT_CLEAR)) {
        OnClearHistory();
    }
    if (settingUseSmallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_CLEAR);
        UI::EndTooltip();
    }
    if (settingUseSmallButtons) {
        UI::SameLine();
    }
    if (UI::Button(settingUseSmallButtons ? ICON_CHANGE : TEXT_CHANGE)) {
        UI::OpenPopup(POPUP_CHANGE_TARGET);
    }
    if (settingUseSmallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_CHANGE);
        UI::EndTooltip();
    }
    if (settingUseSmallButtons) {
        UI::SameLine();
    }
    if (UI::Button(settingUseSmallButtons ? ICON_ADD : TEXT_ADD)) {
        UI::OpenPopup(POPUP_ADD_TARGET);
    }
    if (settingUseSmallButtons && UI::IsItemHovered(UI::HoveredFlags::None)) {
        UI::BeginTooltip();
        UI::Text(TEXT_ADD);
        UI::EndTooltip();
    }

    RenderChangeTargetPopup();
    RenderAddTargetPopup();
}

void Render() 
{
    auto app = cast<CTrackMania@>(GetApp());
    
    auto map = app.RootMap;
    
    if(!UI::IsGameUIVisible()) {
        return;
    }

    if (settingWindowHideWithOverlay && !UI::IsOverlayShown()) {
        return;
    }
    
    if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
        if(settingWindowLockPosition) {
            UI::SetNextWindowPos(int(settingWindowAnchor.x), int(settingWindowAnchor.y), UI::Cond::Always);
        } else {
            UI::SetNextWindowPos(int(settingWindowAnchor.x), int(settingWindowAnchor.y), UI::Cond::FirstUseEver);
        }
        
        int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
        if (!UI::IsOverlayShown()) {
            windowFlags |= UI::WindowFlags::NoInputs;
        }

        UI::Begin("Run History", windowFlags);
        
        if(!settingWindowLockPosition) {
            settingWindowAnchor = UI::GetWindowPos();
        }
        
        runs.Render();

        RenderActions();
        
        UI::End();
    }
}

void Main() 
{
    string lastMapId = "";
    string lastGhostId = "";

#if DEPENDENCY_CHAMPIONMEDALS
    print("ChampionMedals detected");
#else
    warn("ChampionMedals not installed");
#endif

    // init delta thresholds table
    thresholdsTable.FromString(settingDeltasSerialized);

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
    if (settingDefaultTarget == DefaultTargetMedalOptions::pb) {
        @currentTarget = @pb;
    } else {
        uint maxTargetId = 1;

        // TODO: Refactor this in next update 
        // HOTFIX
        uint offset = 0;
#if DEPENDENCY_CHAMPIONMEDALS
        offset = 1;
#endif
        switch (settingDefaultTarget) {
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
    runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
}

void SetTarget(Target @target) 
{
    @currentTarget = target;
    print(target.icon);
    UpdateRuns();
}

string BoolToStr(bool value) 
{
    return value ? ("\\$0f0" + Icons::Check) : ("\\$f00" + Icons::Times);
}

void OnNewGhost(const MLFeed::GhostInfo_V2@ ghost) 
{
    if (!ghost.IsLocalPlayer || ghost.IsPersonalBest) {
        return;
    }
    int lastTime = ghost.Result_Time;

    if (settingIsPBOnly && pb.time > 0 && lastTime > pb.time) {
        
    } else {   
        runs.AddRun(Run(lastTime));
    }
    if (pb.time < 1 || lastTime < pb.time) {
        pb.time = lastTime;
    }
    UpdateCurrentTarget();
}

void OnMapChange(CGameCtnChallenge@ map) 
{
    runs.Clear();

    author.time = map.TMObjective_AuthorTime;
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

void OnClearHistory() 
{
    runs.Clear();
}

