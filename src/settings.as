[Setting category="General" name="Limit" description="Limit amount of runs displayed in history"]
uint settingRunsLimit = 10;

[Setting category="General" name="PBs only" description="Save only PB runs"]
bool settingIsPBOnly = false;

[Setting category="General" name="Default target medal" description="Target medal chosen on map load"]
DefaultTargetMedalOptions settingDefaultTarget = DefaultTargetMedalOptions::closestNotBeaten;


[Setting category="Display" name="Window position"]
vec2 settingWindowAnchor = vec2(0, 170);
[Setting category="Display" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool settingWindowLockPosition = false;
[Setting category="Display" name="Hide with overlay"]
bool settingWindowHideWithOverlay = false;
[Setting category="Display" name="Small action buttons"]
bool settingUseSmallButtons = true;

[Setting hidden]
string settingDeltasSerialized = DEFAULT_DELTAS;


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