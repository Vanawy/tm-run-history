class Target {
    string icon;
    int time;
    
    Target(string &in icon, int time = 0) {
        this.icon = icon;
        this.time = time;
    }

    void DrawIcon() {
        UI::Text(this.icon);
    }

    void DrawTime() {
        UI::Text(this.FormattedTime());
    }
    
    string FormattedTime() {
        return (this.time > 0 ? "\\$fff" + Time::Format(this.time) : "-:--.---");
    }


}

