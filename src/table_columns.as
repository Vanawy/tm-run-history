namespace TableColumns {
    bool ShowRunId() {
        return settingColumnShowRunId;
    }
    bool ShowMedal() {
        return settingColumnShowMedal;
    }
    bool ShowTime() {
        return settingColumnShowTime;
    }
    bool ShowDelta() {
        return settingColumnShowDelta;
    }
    bool ShowPBImprovment() {
        return settingColumnShowPBImprovment;
    }
    bool ShowNoRespawnTime() {
        return settingColumnShowNoRespawnTime;
    }
    bool ShowRespawns() {
        if (global_active_game_mode == GameMode::Platform) {
            return setting_show_respawns_in_platform;
        }
        return settingColumnShowRespawns;
    }
    bool ShowGrindTime() {
        return settingColumnShowGrindTime;
    }
}
