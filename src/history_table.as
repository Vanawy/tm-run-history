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

    void Render(Target @target) 
    {
        UI::BeginGroup();
        uint numCols = 6; 
        if(UI::BeginTable(TEXT_PLUGIN_NAME, numCols, UI::TableFlags::SizingFixedFit)) {
            
            // print(targets.Length);
            UI::TableNextRow();
            UI::TableNextColumn();
            
            string text = "";
            if (@target != null && target.time > 0) {
                UI::Text(target.icon);
                text = "\\$fff" + Time::Format(target.time);
            } else {
                UI::Text(Icons::Spinner);
                text = "-:--.---";
            }

            UI::TableNextColumn();
            UI::Text(ICON_MEDAL);
            UI::TableNextColumn();
            UI::Text(text);
            UI::TableNextColumn();
            UI::Text(Icons::Flag);
            UI::TableNextColumn();
            UI::Text(COLOR_PB + Icons::ChevronUp);
            UI::TableNextColumn();
            UI::Text(ICON_NORESPAWN);

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
                
                UI::TableNextColumn();
                UI::Text("" + (i + 1));
                
                UI::TableNextColumn();
                UI::Text(run.beaten.icon);

                UI::TableNextColumn();
                UI::Text("\\$fff" + Time::Format(run.time));

                UI::TableNextColumn();
                run.DrawDelta();
                UI::TableNextColumn();
                run.DrawPBImprovment();
                UI::TableNextColumn();
                if (run.noRespawnTime > 0) {
                    UI::Text(run.noRespawn.color + Time::Format(run.noRespawnTime));
                }
            };
            UI::EndTable();
        }
        UI::EndGroup();
    }
}