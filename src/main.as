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


Target@ currentTarget = null;
Thresholds::Table thresholdsTable = Thresholds::Table();
History runs = History();

Target@ pb          = Target("\\$0ff" + ICON_PB, 0);
Target@ custom      = Target("\\$c11" + ICON_CUSTOM_TARGET, 0);
Target@ bronze      = Target("\\$964" + ICON_MEDAL);
Target@ silver      = Target("\\$899" + ICON_MEDAL);
Target@ gold        = Target("\\$db4" + ICON_MEDAL);
Target@ author      = Target("\\$071" + ICON_MEDAL);
Target@ champion    = Target("\\$f69" + ICON_MEDAL);

array<Target@> targets = {
    pb,
    custom,
    author,
    gold,
    silver,
    bronze
};

float inputNewTime = 0;
bool autoChangeTarget = true;


void Main() 
{
#if DEPENDENCY_CHAMPIONMEDALS
    print("ChampionMedals detected");
#else
    warn("ChampionMedals not installed");
#endif

    string lastMapId = "";
    string lastGhostId = "";

    // init delta thresholds table
    thresholdsTable.FromString(settingDeltasSerialized);

    
#if DEPENDENCY_CHAMPIONMEDALS
    targets.InsertLast(champion);
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

        CTrackMania@ trackmania = cast<CTrackMania>(GetApp());
        if (trackmania !is null) {
            auto map = @trackmania.RootMap;
            if (map !is null && lastMapId != map.MapInfo.MapUid) {
                lastMapId = map.MapInfo.MapUid;
                OnMapChange(map);
            }
        }
    }
}

void Render() 
{
    auto trackmania = cast<CTrackMania@>(GetApp());
    
    auto map = trackmania.RootMap;
    
    if(!UI::IsGameUIVisible()) {
        return;
    }

    if (settingWindowHideWithOverlay && !UI::IsOverlayShown()) {
        return;
    }
    
    if(map !is null && map.MapInfo.MapUid != "" && trackmania.Editor is null) {
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
        
        runs.Render(currentTarget);

        RenderActions();
        
        UI::End();
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
                if (!target.hasTime()) {
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

void RenderAddTargetPopup()
{
    if (!UI::IsOverlayShown()) return;
    if (UI::BeginPopup(POPUP_ADD_TARGET)) {
        if (custom.hasTime()) {
            UI::Text("Custom time - " + Time::Format(custom.time));
        }

        inputNewTime = UI::InputFloat("seconds", inputNewTime, 0.005);
        UI::Text("New time " + Time::Format(int(inputNewTime * 1000)));
        if (UI::Button(TEXT_ADD)) {
            custom.time = int(inputNewTime * 1000);
            inputNewTime = 0;
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


void SetTarget(Target @target) 
{
    if (@currentTarget == @target) {
        return;
    }
    @currentTarget = target;
    print("New target: " + target.icon);
    runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
}


void UpdateCurrentTarget()
{
    if (!autoChangeTarget) {
        runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
        return;
    }

    Target @newTarget = @bronze;
    int smallestDelta = bronze.time;

    for (uint i = 0; i < targets.Length; i++) {
        if (!targets[i].hasTime()) {
            continue;
        }
        auto delta = pb.time - targets[i].time;
        if (delta > 0 && delta < smallestDelta) {
            smallestDelta = delta;
            @newTarget = @targets[i];
        }
    }
    
    if (pb.hasTime() && newTarget.time > pb.time) {
        @newTarget = @pb;
    }
    SetTarget(newTarget);
}


void OnNewGhost(const MLFeed::GhostInfo_V2@ ghost) 
{
    if (!ghost.IsLocalPlayer || ghost.IsPersonalBest) {
        return;
    }
    int lastTime = ghost.Result_Time;

    auto newRun = Run(runs.NextRunID(), lastTime);

    int pbDelta = 0;
    if (pb.hasTime()) {
        pbDelta = lastTime - pb.time;
        newRun.pbDelta = lastTime - pb.time;
    }
    
    if (pbDelta < 0 || !pb.hasTime()) {
        pb.time = lastTime;
        newRun.isPB = true;
    }
    newRun.Update(currentTarget, thresholdsTable);
    runs.AddRun(newRun);
    print("New run: " + newRun.ToString());
    UpdateCurrentTarget();
}

void OnMapChange(CGameCtnChallenge@ map) 
{
    runs.Clear();

    author.time = map.TMObjective_AuthorTime;
    bronze.time = map.TMObjective_BronzeTime;
    silver.time = map.TMObjective_SilverTime;
    gold.time   = map.TMObjective_GoldTime;
    champion.time = 0;
    custom.time = 0;
    pb.time = 0;

    auto trackmania = cast<CTrackMania@>(GetApp());
    auto network = trackmania.Network;
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
            print(pb.icon + Time::Format(pb.time));
        }
    }
#if DEPENDENCY_CHAMPIONMEDALS
    auto newTime = ChampionMedals::GetCMTime();
    if (champion.time != int(newTime)) {
        champion.time = newTime;
        print(champion.icon + Time::Format(champion.time));
    }
#endif
    
    UpdateCurrentTarget();
}

void OnThresholdsTableChange()
{
    runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
}

void OnClearHistory() 
{
    runs.Clear();
}