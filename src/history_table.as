class HistoryTable
{
    array<Run> runs;

    int lastRunId = 0;

    HistoryTable(){}

    void Clear() 
    {
        runs.Resize(0);
        lastRunId = 0;
    }

    void AddRun(Run @newRun) 
    {
        int count = runs.Length;
        lastRunId = newRun.id;

        if (settingIsPBOnly && !newRun.isPB) {
            return;
        }
        runs.InsertLast(newRun);

        count = runs.Length;
        for (int i = 0; i < count; i++) {
            runs[i].hidden = false;
            if (i < (count - settingRunsLimit)) {
                runs[i].hidden = true;
            }
        }
    }

    void UpdateDeltaTimes(Target @target, Thresholds::Table @thresholds) 
    {
        if (@target == null) {
            return;
        }

        for (uint i = 0; i < runs.Length; i++) {
            Run@ run = runs[i];
            run.Update(target, thresholds);
        }
    }

    uint NextRunID() {
        return lastRunId + 1;
    }

    bool IsEmpty() {
        return runs.IsEmpty();
    }

    void Render(Target @target) 
    {
        // uint numCols = 6;

        uint numCols = 
            (settingColumnShowRunId ? 1 : 0) +
            (settingColumnShowMedal ? 1 : 0) +
            (settingColumnShowTime ? 1 : 0) +
            (settingColumnShowDelta ? 1 : 0) +
            (settingColumnShowPBImprovment ? 1 : 0) +
            (settingColumnShowNoRespawnTime ? 1 : 0);

        if (numCols < 1) {
            return;
        }


        UI::BeginGroup();

        if(UI::BeginTable(TEXT_PLUGIN_NAME, numCols, UI::TableFlags::SizingFixedFit)) {
            
            // print(targets.Length);
            UI::TableNextRow();
            string formattedTime = "";
            string icon = "";
            if (@target != null && target.time > 0) {
                icon = target.icon;
                formattedTime = "\\$fff" + Time::Format(target.time);
            } else {
                icon = Icons::Spinner;
                formattedTime = "-:--.---";
            }
            if (settingColumnShowRunId) {
                UI::TableNextColumn();
                UI::Text(icon);
            }
            if (settingColumnShowMedal) {
                UI::TableNextColumn();
                if (settingColumnShowRunId) {
                    UI::Text(ICON_MEDAL);
                } else {
                    UI::Text(icon);
                }
            }
            if (settingColumnShowTime) {
                UI::TableNextColumn();
                UI::Text(formattedTime);
            }
            if (settingColumnShowDelta) {
                UI::TableNextColumn();
                UI::Text(Icons::Flag);
            }
            if (settingColumnShowPBImprovment) {
                UI::TableNextColumn();
                UI::Text(COLOR_PB + Icons::ChevronUp);
            }
            if (settingColumnShowNoRespawnTime) {
                UI::TableNextColumn();
                UI::Text(ICON_NORESPAWN);
            }

            UI::TableNextRow();
            for(uint i = 0; i < numCols; i++) {
                UI::TableNextColumn();
                UI::Separator();
            }

            for(uint i = 0; i < runs.Length; i++) {
                Run@ run = runs[i];
                if(run.hidden) {
                    continue;
                }

                UI::TableNextRow();

                if (settingColumnShowRunId) {
                    UI::TableNextColumn();
                    UI::Text("" + (i + 1));
                }
                if (settingColumnShowMedal) {
                    UI::TableNextColumn();
                    UI::Text(run.beaten.icon);
                }
                if (settingColumnShowTime) {
                    UI::TableNextColumn();
                    UI::Text("\\$fff" + Time::Format(run.time));
                }
                if (settingColumnShowDelta) {
                    UI::TableNextColumn();
                    run.DrawDelta();
                }
                if (settingColumnShowPBImprovment) {
                    UI::TableNextColumn();
                    run.DrawPBImprovment();
                }
                if (settingColumnShowNoRespawnTime) {
                    UI::TableNextColumn();
                    if (run.noRespawnTime > 0) {
                        UI::Text(run.noRespawn.color + Time::Format(run.noRespawnTime));
                    }
                }
            }
            UI::EndTable();
        }
        UI::EndGroup();
    }
}