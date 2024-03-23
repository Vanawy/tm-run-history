class Run 
{
    uint id;
    int time;
    string style;
    bool hidden;
    int delta;

    bool isPB = false;
    int pbDelta = 0;

    string deltaTextOverride;

    Run(){}
    
    Run(uint id, int time = -1, string &in style = "\\$fff") {
        this.id = id;
        this.time = time;
        this.style = style;
        this.hidden = false;
    }

    void Update(Target@ target, Thresholds::Table@ thresholds) 
    {
        if (@currentTarget == null) {
            return;
        }
        delta = target.time - time;
        style = "\\$" + thresholds.GetColorByDelta(delta);
    }
    
    void DrawDelta() 
    {
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

    string ToString()
    {
        return 
            "Run #" + id + " " + Time::Format(time) + " "
            + ICON_PB + "Δ: " + pbDelta + " isPB: " 
            + (isPB ? Icons::Check : Icons::Times);
    }
}

