class HistoryTable
{
    array<Run> runs;

    Run current = Run();

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
    
        print("New run: " + newRun.ToString());
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
            (TableColumns::ShowRunId() ? 1 : 0)
            + (TableColumns::ShowMedal() ? 1 : 0)
            + (TableColumns::ShowTime() ? 1 : 0)
            + (TableColumns::ShowDelta() ? 1 : 0)
            + (TableColumns::ShowPBImprovment() ? 1 : 0)
            + (TableColumns::ShowNoRespawnTime() ? 1 : 0)
            + (TableColumns::ShowRespawns() ? 1 : 0)
            + (TableColumns::ShowGrindTime() ? 1 : 0)
        ;

        if (numCols < 1) {
            return;
        }


        if(UI::BeginTable(TEXT_PLUGIN_NAME, numCols, UI::TableFlags::SizingFixedFit)) {
            
            // print(targets.Length);
            UI::TableNextRow();

            RenderHeader(target);

            UI::TableNextRow();
            RenderSeparator();

            for(uint i = 0; i < runs.Length; i++) {
                Run@ run = @runs[i];
                if (settingNewRunsFirst) {
                    @run = @runs[runs.Length - 1 - i];
                }
                if (run.hidden) {
                    continue;
                }

                UI::TableNextRow();
                RenderRun(run);
            }

            if (!current.hidden) {
                UI::TableNextRow();
                RenderSeparator();
                UI::TableNextRow();
                RenderRun(current);
            }
            UI::EndTable();
        }
    }

    void RenderHeader(Target@ target)
    {
        string formattedTime = "";
        string icon = "";
        if (@target != null && target.time > 0) {
            icon = target.coloredIcon();
            formattedTime = "\\$fff" + Time::Format(target.time);
        } else {
            icon = Icons::Spinner;
            formattedTime = "-:--.---";
        }
        if (TableColumns::ShowRunId()) {
            UI::TableNextColumn();
            UI::Text(icon);
        }
        if (TableColumns::ShowMedal()) {
            UI::TableNextColumn();
            if (TableColumns::ShowRunId()) {
                UI::Text(ICON_MEDAL);
            } else {
                UI::Text(icon);
            }
        }
        if (TableColumns::ShowTime()) {
            UI::TableNextColumn();
            UI::Text(formattedTime);
        }
        if (TableColumns::ShowDelta()) {
            UI::TableNextColumn();
            UI::Text(Icons::Flag);
        }
        if (TableColumns::ShowPBImprovment()) {
            UI::TableNextColumn();
            UI::Text(COLOR_PB + Icons::ChevronUp);
        }
        if (TableColumns::ShowNoRespawnTime()) {
            UI::TableNextColumn();
            UI::Text(ICON_NORESPAWN);
        }
        if (TableColumns::ShowRespawns()) {
            UI::TableNextColumn();
            UI::Text(ICON_RESPAWN);
        }
        if (TableColumns::ShowGrindTime()) {
            UI::TableNextColumn();
            UI::Text(ICON_GRIND_TIME);
        }
    }

    void RenderRun(Run@ run)
    {
        if (TableColumns::ShowRunId()) {
            UI::TableNextColumn();
            if (run.id > 0) {
                UI::Text("" + run.id);
            }
        }
        if (TableColumns::ShowMedal()) {
            UI::TableNextColumn();
            if (run.beaten !is null) {
                UI::Text(run.beaten.coloredIcon());
            } else {
                UI::Text(COLOR_NO_MEDAL + ICON_NO_MEDAL);
            }
        }
        if (TableColumns::ShowTime()) {
            UI::TableNextColumn();
            if (run.isDNF) {
                UI::Text("DNF");
            } else {
                UI::Text("\\$fff" + Time::Format(run.time));
            }
        }
        if (TableColumns::ShowDelta()) {
            UI::TableNextColumn();
            run.DrawDelta();
        }
        if (TableColumns::ShowPBImprovment()) {
            UI::TableNextColumn();
            run.DrawPBImprovment();
        }
        if (TableColumns::ShowNoRespawnTime()) {
            UI::TableNextColumn();
            if (run.noRespawnTime > 0) {
                UI::Text(run.noRespawn.color + Time::Format(run.noRespawnTime));
            }
        }
        if (TableColumns::ShowRespawns()) {
            UI::TableNextColumn();
            if (run.respawns > 0) {
                UI::Text("" + run.respawns);
            }
        }
        if (TableColumns::ShowGrindTime()) {
            UI::TableNextColumn();
            if (!run.isDNF) {
                auto formatted = Time::Format(run.grindTime);
                UI::Text(formatted.SubStr(0, formatted.Length - 1));
            }
        }
    }

    void RenderSeparator()
    {
        for(int i = 0; i < UI::TableGetColumnCount(); i++) {
            UI::TableNextColumn();
            UI::Separator();
        }
    }
}