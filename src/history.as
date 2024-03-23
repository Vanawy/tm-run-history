class History 
{
    array<Run> runs;

    History(){}

    void Clear() 
    {
        runs.Resize(0);
    }

    void AddRun(Run @newRun) 
    {
        int count = runs.Length;
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

    void Render(Target @target) 
    {
        UI::BeginGroup();
        uint numCols = 3; 
        if(UI::BeginTable(TEXT_PLUGIN_NAME, numCols, UI::TableFlags::SizingFixedFit)) {
            
            // print(targets.Length);
            UI::TableNextRow();
            
                UI::TableNextColumn();

            if (@target != null && target.time > 0) {
                UI::Text(target.icon);
                UI::TableNextColumn();
                UI::Text("\\$fff" + Time::Format(target.time));
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
    }
}