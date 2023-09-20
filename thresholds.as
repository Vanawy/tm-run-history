namespace Thresholds {

    const int LIMIT = 8;

    const string STRING_DELIMITER = "|";

    const array<string> COLORS = {
        "F60",
        "F70",
        "F81",
        "F91",
        "F92",
        "FA2",
        "FB3",
        "FC3",
    };

    class Table {

        private array<int> deltas = {};

        private int newTime = 0;

        bool isChanged = false;

        Table() {}

        void FromString(string _settingsString) {
            auto times = _settingsString.Split(STRING_DELIMITER, LIMIT);
            for (int i = 0; i < times.Length; i++) {
                this.Add(Text::ParseInt(times[i]));
            }
        }

        string ToString() {
            array<string> deltasStrings = {};
            for (uint i = 0; i < this.deltas.Length; i++) {
                deltasStrings.InsertLast("" + this.deltas[i]);
            }
            return string::Join(deltasStrings, STRING_DELIMITER);
        }
        
        void Add(int timeMs) {
            if (this.deltas.Find(timeMs) >= 0) {
                return;
            }
            print("added " + timeMs);
            this.deltas.InsertLast(timeMs);
            this.deltas.SortDesc();
        } 

        string GetColor(int timeIndex) {
            int colorIndex = Math::Round(float(timeIndex) / this.deltas.Length * (COLORS.Length - 1));
            return COLORS[colorIndex];
        }

        void Render() {
            UI::Text("Delta time thresholds");

            if(UI::BeginTable("Delta Thresholds", 4, UI::TableFlags::SizingStretchProp)) {

                int count = this.deltas.Length;
                for (int i = 0; i < count; i++) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text("#" + (i + 1));

                    UI::TableNextColumn();
                    UI::Text("\\$" + this.GetColor(i) + "+" + Time::Format(this.deltas[i]));
                    
                    UI::TableNextColumn();
                    UI::Text(this.deltas[i] + " ms");

                    UI::TableNextColumn();
                    UI::Button(Icons::Times);
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

        string GetColorByDelta(int deltaTime, string defaultColor) {
            for (int i = this.deltas.Length - 1; i >= 0; i--) {
                print(i);
                if (deltaTime < this.deltas[i]) {
                    return this.GetColor(i);
                }
            }
            return defaultColor;
        }
    }

}