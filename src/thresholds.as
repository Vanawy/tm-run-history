namespace Thresholds {

    const int LIMIT = 8;

    const string STRING_DELIMITER = "|";

    const string COLOR_NEGATIVE = "f77";

    const string COLOR_POSITIVE = "070";

    const array<string> COLORS = {
        "f10",
        "f30",
        "f61",
        "f82",
        "fa3",
        "fc4",
        "fe5",
        "ff6",
    };

    class Table {

        private array<int> deltas = {};

        private int newTime = 0;

        bool isChanged = false;

        Table() {}

        void FromString(string _settingsString) {
            auto times = _settingsString.Split(STRING_DELIMITER, LIMIT);
            for (int i = 0; i < int(times.Length); i++) {
                this.Add(Text::ParseInt(times[i]));
            }
        }

        string ToString() {
            array<string> settingDeltasSerializeds = {};
            for (uint i = 0; i < this.deltas.Length; i++) {
                settingDeltasSerializeds.InsertLast("" + this.deltas[i]);
            }
            return string::Join(settingDeltasSerializeds, STRING_DELIMITER);
        }
        
        private void Add(int timeMs) {
            if (this.deltas.Find(timeMs) >= 0) {
                return;
            }
            this.deltas.InsertLast(timeMs);
            this.deltas.SortDesc();
        } 
        
        private void RemoveAt(int index) {
            this.deltas.RemoveAt(index);
            this.deltas.SortDesc();
        } 

        private string GetColor(int timeIndex) {
            int colorIndex = 
            int(Math::Round(float(timeIndex) / this.deltas.Length * (COLORS.Length - 1)));
            
            return COLORS[colorIndex];
        }

        void Render() {
            UI::Text("Delta time thresholds (" + this.deltas.Length + "/" + LIMIT + ")");

            if(UI::BeginTable("Delta Thresholds", 4, UI::TableFlags::SizingStretchProp)) {

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("#0");
                UI::TableNextColumn();
                UI::Text("\\$" + COLOR_NEGATIVE + "+" + Time::Format(69420));

                for (uint i = 0; i < this.deltas.Length; i++) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("#" + (i + 1));

                    UI::TableNextColumn();
                    UI::Text("\\$" + this.GetColor(i) + "+" + Time::Format(this.deltas[i]));
                    
                    UI::TableNextColumn();
                    UI::Text(this.deltas[i] + " ms");

                    UI::TableNextColumn();
                    if (UI::Button(Icons::Times + "##" + (i + 1))) {
                        print("remove " + i);
                        this.RemoveAt(i);
                        this.isChanged = true;
                        continue;
                    }
                }

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Separator();
                UI::TableNextColumn();
                UI::Separator();
                UI::TableNextColumn();
                UI::Separator();

                UI::TableNextRow();
                bool disabled = this.deltas.Length >= LIMIT;
                if (disabled) {
                    UI::BeginDisabled();
                }
                
                UI::TableNextColumn();
                UI::TableNextColumn();
                this.newTime = UI::InputInt("ms", this.newTime, 100);

                UI::TableNextColumn();
                UI::TableNextColumn();
                if (UI::Button(Icons::Plus)) {
                    if (this.newTime > 0 && this.deltas.Length < LIMIT) {
                        this.Add(this.newTime);
                        this.newTime = 0;
                        this.isChanged = true;
                    }
                }
                if (disabled) {
                    UI::EndDisabled();
                }

                UI::EndTable();
            }
        }

        string GetColorByDelta(int deltaTime) {
            string color = COLOR_NEGATIVE;
            if (deltaTime < 0) {
                color = COLOR_POSITIVE;
            } else {
                for (int i = this.deltas.Length - 1; i >= 0; i--) {
                    if (deltaTime < this.deltas[i]) {
                        return this.GetColor(i);
                    }
                }
            }
            return color;
        }
    }

}