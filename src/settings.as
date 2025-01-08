[Setting category="General" name="Limit" description="Limit amount of runs displayed in history"]
uint settingRunsLimit = 10;

[Setting category="General" name="PBs only" description="Save only PB runs"]
bool settingIsPBOnly = false;
[Setting category="General" name="Show DNF" description="Save not finished runs"]
bool setting_show_dnf = true;

[Setting category="General" name="Default target medal" description="Selects the baseline medal for target comparison on map load. If default target is beaten plugin will use next closest target (same as closestNotBeaten option)."]
DefaultTargetMedalOptions settingDefaultTarget = DefaultTargetMedalOptions::closestNotBeaten;

[Setting category="General" name="New Runs first" description="Show new runs at the top"]
bool settingNewRunsFirst = false;


[Setting category="Main window" name="Hide window"]
bool settingWindowHide = false;
[Setting category="Main window" name="Hide with overlay"]
bool settingWindowHideWithOverlay = false;
[Setting category="Main window" name="Window position"]
vec2 settingWindowAnchor = vec2(0, 170);
[Setting category="Main window" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool settingWindowLockPosition = false;
[Setting category="Main window" name="Small action buttons"]
bool settingUseSmallButtons = true;
[Setting category="Main window" name="Hide action buttons" description="Actions will stay accesible in Plugins tab in overlay"]
bool settingUseHideButtons = false;

[Setting category="Main window" name="Show current run info" description="Added for development purposes"]
bool setting_show_current_run = false;


[Setting category="Columns" name="Run number"]
bool settingColumnShowRunId = true;
[Setting category="Columns" name="Medal"  description="Shows current target icon in header if Run number column is disabled"]
bool settingColumnShowMedal = false;
[Setting category="Columns" name="Time"]
bool settingColumnShowTime = true;
[Setting category="Columns" name="Target Delta"]
bool settingColumnShowDelta = true;
[Setting category="Columns" name="PB Improvment"]
bool settingColumnShowPBImprovment = false;
[Setting category="Columns" name="No Respawn Time"]
bool settingColumnShowNoRespawnTime = true;
[Setting category="Columns" name="Number of respawns"]
bool settingColumnShowRespawns = false;
[Setting category="Columns" name="Time since last finish or session start"]
bool settingColumnShowGrindTime = false;

[Setting hidden]
string settingDeltasSerialized = DEFAULT_DELTAS;
[Setting hidden]
bool setting_show_in_stunt = false;
[Setting hidden]
bool setting_show_in_platform = true;
[Setting hidden]
bool setting_show_respawns_in_platform = true;

[SettingsTab name="Game Modes" icon="Gamepad"]
void RenderGameModesTab()
{
    UI::BeginTabBar("GameModesTabBar");
    if (UI::BeginTabItem("Platform")) {
        setting_show_in_platform = UI::Checkbox("Show window", setting_show_in_platform);
        WindowHiddenWarning();
        setting_show_respawns_in_platform = UI::Checkbox("Force show Respawns column", setting_show_respawns_in_platform);
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Stunt")) {
        setting_show_in_stunt = UI::Checkbox("Show window", setting_show_in_stunt);
        WindowHiddenWarning();
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Race / Other")) {
        UI::Text("All other modes uses settings from Main window tab");
        UI::EndTabItem();
    }
    UI::EndTabBar();
}

void WindowHiddenWarning() {
    if (settingWindowHide) {
        UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
        UI::Text("Window is hidden in Main window tab. Setting above won't override it.");
        UI::PopStyleColor();
    }
}


[SettingsTab name="Feedback" icon="Bug"]
void RenderFeedbackTab()
{
    UI::Text("Thank you for using " + TEXT_PLUGIN_NAME + "!");
    UI::Text("To report issues or send feedback use buttons below " + "\\$f69" + Icons::Heart);

    if (UI::Button("GitHub " + Icons::Github)) {
        OpenBrowserURL("https://github.com/Vanawy/tm-run-history/issues");
    }
    if (UI::Button("Bluesky " + Icons::Plane)) {
        OpenBrowserURL("https://bsky.app/profile/vanawy.dev");
    }
}


[SettingsTab name="Thresholds" icon="ClockO"]
void RenderThresholdsTab()
{
    if (UI::Button("Reset to default")) {
        settingDeltasSerialized = DEFAULT_DELTAS;
        thresholdsTable.FromString(settingDeltasSerialized);
    }
    UI::Text("Configure delta time thresholds");
    UI::NewLine();
    thresholdsTable.Render();
    if (thresholdsTable.isChanged) {
        thresholdsTable.isChanged = false;
        settingDeltasSerialized = thresholdsTable.ToString();
        OnThresholdsTableChange();
    }
}