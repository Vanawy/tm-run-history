class Run {
    string icon;
    int time;
    string style;
    bool hidden;
    int delta;

    string deltaTextOverride;

    Run(){}
    
    Run(string &in icon, int time = -1, string &in style = "\\$fff") {
        this.icon = icon;
        this.time = time;
        this.style = style;
        this.hidden = false;
    }

    void UpdateDelta(Target@ target) {
        this.delta = target.time - this.time;
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

