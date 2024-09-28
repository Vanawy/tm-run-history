enum DefaultTargetMedalOptions {
    closestNotBeaten,
    pb,
#if DEPENDENCY_CHAMPIONMEDALS
    champion,
#endif
#if DEPENDENCY_WARRIORMEDALS
    warrior,
#endif
    author,
    gold,
    silver,
    bronze,
}


Target@ currentTarget = null;
Thresholds::Table thresholdsTable = Thresholds::Table();
HistoryTable runs = HistoryTable();

Target@ pb          = Target(COLOR_PB, ICON_PB, 0);
Target@ custom      = Target("\\$c11", ICON_CUSTOM_TARGET, 0);
Target@ bronze      = Target(COLOR_BRONZE, ICON_MEDAL);
Target@ silver      = Target(COLOR_SILVER, ICON_MEDAL);
Target@ gold        = Target(COLOR_GOLD, ICON_MEDAL);
Target@ author      = Target(COLOR_AUTHOR, ICON_MEDAL);
Target@ champion    = Target(COLOR_CHAMPION, ICON_MEDAL);
Target@ warrior     = Target(COLOR_WARRIOR, ICON_MEDAL);
Target@ no_medal    = Target(COLOR_NO_MEDAL, ICON_NO_MEDAL);

array<Target@> targets = {
    pb,
    custom,
    author,
    gold,
    silver,
    bronze
};

float inputNewTime = 0;
bool inputTriggerPopup = false;

bool autoChangeTarget = true;

uint championMedalUpdateAttempts = 0;


void Main() 
{

    string lastMapId = "";
    string lastGhostId = "";

    // init delta thresholds table
    thresholdsTable.FromString(settingDeltasSerialized);

    
#if DEPENDENCY_WARRIORMEDALS
    print("WarriorMedals detected");
    targets.InsertAt(1, warrior);
    warrior.color = WarriorMedals::GetColorStr();
#else
    warn("WarriorMedals not installed");
#endif
    
#if DEPENDENCY_CHAMPIONMEDALS
    print("ChampionMedals detected");
    targets.InsertAt(1, champion);
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

    if (settingWindowHide) {
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
            text = currentTarget.coloredIcon() + "\\$fff" + Time::Format(currentTarget.time);
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
                    target.coloredIcon() + "\\$fff" + Time::Format(target.time), 
                    @target == @currentTarget && !autoChangeTarget
                )) {
                    print("Target change " + target.coloredIcon());
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


void RenderMenu() {
    if (UI::BeginMenu(ICON_MENU + " " + TEXT_PLUGIN_NAME)) {

        string toggleVisibilityText = settingWindowHide 
            ? Icons::Eye + " Show window"
            : Icons::EyeSlash + " Hide window";
        if (UI::MenuItem(toggleVisibilityText)) {
            settingWindowHide = !settingWindowHide;
        }

        if (UI::BeginMenu(ICON_CLEAR + " " + TEXT_CLEAR)) {
            if (UI::MenuItem("Clear.")) {
                OnClearHistory();
            }
            UI::EndMenu();
        }

        if (UI::MenuItem(ICON_ADD + " " + TEXT_ADD)) {
            inputTriggerPopup = true;
        }

        if (UI::BeginMenu(ICON_CHANGE + " " + TEXT_CHANGE)) {
            if (UI::MenuItem(TEXT_DEFAULT_TARGET, "", autoChangeTarget)) {
                autoChangeTarget = true;
                UpdateCurrentTarget();
            }
            for(uint i = 0; i < targets.Length; i++) {
                Target @target = @targets[i];
                if (!target.hasTime()) {
                    continue;
                }            
                if (UI::MenuItem(
                    target.coloredIcon() + " \\$fff" + Time::Format(target.time), 
                    "",
                    @target == @currentTarget && !autoChangeTarget
                )) {
                    print("Target change " + target.coloredIcon());
                    autoChangeTarget = false;
                    SetTarget(target);
                }
            }
            UI::EndMenu();
        }

        UI::EndMenu();
    }
}


void RenderActions()
{
    if (inputTriggerPopup) {
        UI::OpenPopup(POPUP_ADD_TARGET);
        inputTriggerPopup = false;
    }
    RenderAddTargetPopup();

    if (!UI::IsOverlayShown() || settingUseHideButtons) return;

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
}


void SetTarget(Target @target) 
{
    if (@currentTarget == @target) {
        return;
    }
    @currentTarget = target;
    print("New target: " + target.coloredIcon());
    runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
}


void UpdateCurrentTarget()
{
    if (!autoChangeTarget) {
        runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
        return;
    }

    if (settingDefaultTarget == DefaultTargetMedalOptions::pb) {
        SetTarget(pb);
        return;
    }

    Target @newTarget = @bronze;
    int smallestDelta = bronze.time;
    Target @defaultTarget = @bronze;
    
    if (settingDefaultTarget != DefaultTargetMedalOptions::closestNotBeaten) {
        defaultTarget = GetDefaultTarget();
    }

    for (uint i = 0; i < targets.Length; i++) {
        if (!targets[i].hasTime()) {
            continue;
        }
        auto delta = pb.time - targets[i].time;
        if (delta > 0 
            && targets[i].time <= defaultTarget.time
            && delta < smallestDelta
        ) {
            smallestDelta = delta;
            @newTarget = @targets[i];
        }
    }
    
    if (pb.hasTime() && newTarget.time > pb.time) {
        @newTarget = @pb;
    }
    SetTarget(newTarget);
} 

Target@ GetDefaultTarget()
{
    switch (settingDefaultTarget) {
#if DEPENDENCY_CHAMPIONMEDALS
        case DefaultTargetMedalOptions::champion:
            if (champion.hasTime()) {
                return @champion;
            }
#endif
#if DEPENDENCY_WARRIORMEDALS
        case DefaultTargetMedalOptions::warrior:
            if (warrior.hasTime()) {
                return @warrior;
            }
#endif
        case DefaultTargetMedalOptions::pb:
            return @pb;
        case DefaultTargetMedalOptions::author:
            return @author;
        case DefaultTargetMedalOptions::gold:
            return @gold;
        case DefaultTargetMedalOptions::silver:
            return @silver;
        default:
            return @bronze;
    }
}

Target@ GetHardestMedalBeaten(int time) 
{
    array<Target@> medals = {
        bronze,
        silver,
        gold,
        author,
        warrior,
        champion,
    };

    Target @newTarget = @no_medal;

    for (uint i = 0; i < medals.Length; i++) {
        if (@medals[i] == null || !medals[i].hasTime()) {
            continue;
        }
        auto delta = time - medals[i].time;
        if (delta < 0) {
            @newTarget = @medals[i];
        }
    }

    return newTarget;
}

int GetNoRespawnTime() {
    auto raceData = MLFeed::GetRaceData_V4();
    auto playerData = raceData.GetPlayer_V4(MLFeed::LocalPlayersName);
    if (playerData is null) {
        return 0;
    }
    return playerData.LastTheoreticalCpTime;
}

void OnNewGhost(const MLFeed::GhostInfo_V2@ ghost) 
{
    if (!ghost.IsLocalPlayer || ghost.IsPersonalBest) {
        return;
    }
    int lastTime = ghost.Result_Time;
    auto beaten = GetHardestMedalBeaten(lastTime);

    auto noRespawnTime = GetNoRespawnTime();
    auto norespawnTarget = GetHardestMedalBeaten(noRespawnTime);


    auto newRun = Run(runs.NextRunID(), lastTime, beaten, norespawnTarget);

    if (noRespawnTime > 0 && noRespawnTime != lastTime) {
        newRun.noRespawnTime = noRespawnTime;
    }

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
    warrior.time = 0;
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
            print(pb.coloredIcon() + Time::Format(pb.time));
        }
    }
    UpdateCurrentTarget();
    
#if DEPENDENCY_CHAMPIONMEDALS
    UpdateCustomMedalTime(champion, function() { return ChampionMedals::GetCMTime(); });
#endif
#if DEPENDENCY_WARRIORMEDALS
    UpdateCustomMedalTime(warrior, function() { return WarriorMedals::GetWMTimeAsync(); });
#endif
}

funcdef int MedalTimeCB();

void UpdateCustomMedalTime(Target @medal, MedalTimeCB @GetTime) {
    int attempts = 0;
    while (!medal.hasTime()
        && attempts < MAX_CUSTOM_MEDAL_UPDATE_ATTEMPTS_PER_MAP
    ) {
        attempts += 1;

        int newTime = GetTime();
        if (medal.time != int(newTime)) {
            medal.time = newTime;
            print(medal.coloredIcon() + Time::Format(medal.time) + " attempt#" + attempts);
            UpdateCurrentTarget();
        }
        sleep(1000 * attempts);
    }
}


void OnThresholdsTableChange()
{
    runs.UpdateDeltaTimes(currentTarget, thresholdsTable);
}

void OnClearHistory() 
{
    runs.Clear();
}