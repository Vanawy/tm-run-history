class Record {
    string icon;
    int time;
    string style;
    bool hidden;
    int delta;

    string deltaTextOverride;

    Record(){}
    
    Record(string &in icon, int time = -1, string &in style = "\\$fff") {
        this.icon = icon;
        this.time = time;
        this.style = style;
        this.hidden = false;
    }

    void DrawIcon() {
        UI::Text(this.style + this.icon);
    }

    void DrawTime() {
        UI::Text(this.FormattedTime());
    }
    
    string FormattedTime() {
        return this.style + (this.time > 0 ? "\\$fff" + Time::Format(this.time) : "-:--.---");
    }

    void UpdateDelta(Record@ other) {
        this.delta = other.time - this.time;
    }
    
    void DrawDelta() {
        if (deltaTextOverride.Length > 0) {
            UI::Text(deltaTextOverride);
            return;
        }
        string sign = "-";
        int delta = this.delta;
        if (delta < 0) {
            sign = "+";
            delta *= -1;
        }
        UI::Text(this.style + sign + Time::Format(delta));
    }
}

