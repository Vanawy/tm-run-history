class Run 
{
    uint id;
    int time;
    string style;
    bool hidden;
    int targetDelta;

    bool isPB = false;
    int pbDelta = 0;

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
        targetDelta = time - target.time;
        style = "\\$" + thresholds.GetColorByDelta(targetDelta);
    }
    
    void DrawDelta() 
    {
        UI::Text(style + FormatDelta(targetDelta));
    }
    
    void DrawPBDelta() 
    {
        string sign = "+";
        int delta = pbDelta;
        if (delta < 0) {
            sign = "-";
            delta *= -1;
        }
        string text = sign + Time::Format(delta);
        if (isPB) {
            string color = "\\$0ff";
            text = color + "PB " + ICON_PB_STAR;
            if (settingIsPBOnly && delta > 0) {
                text = color + "-" + Time::Format(delta, true, false);
            }
        }
        UI::Text(text);
    }
    
    string FormatDelta(int delta) 
    {
        string sign = "+";
        if (delta < 0) {
            sign = "-";
            delta *= -1;
        }
        return sign + Time::Format(delta);
    }

    string ToString()
    {
        return 
            "Run #" + id + " " + Time::Format(time) + " "
            + ICON_PB + "Δ: " + pbDelta + " isPB: " 
            + (isPB ? Icons::Check : Icons::Times);
    }
}

