class Run 
{
    uint id;
    int time;
    string style;
    bool hidden;
    int targetDelta;

    bool isPB = false;
    int pbDelta = 0;
    Target@ beaten;
    Target@ noRespawn;
    int noRespawnTime = 0;

    Run(){}
    
    Run(uint id, int time, Target@ beaten, Target@ noRespawn) {
        this.id = id;
        this.time = time;
        if (@beaten != null) {
            @this.beaten = @beaten;
        }
        if (@noRespawn != null) {
            @this.noRespawn = @noRespawn;
        }
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
    
    void DrawPBImprovment() 
    {
        if (!isPB) {
            return;
        }
        string text = COLOR_PB + "PB " + ICON_PB_STAR;
        if (pbDelta < 0) {
            text = COLOR_PB + "-" + Time::Format(-pbDelta, true, false);
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
            "Run #" + id + " " + Time::Format(time) + beaten.icon + " \\$fff "
            + ICON_PB + ICON_DELTA + ": " + pbDelta + " isPB: " 
            + (isPB ? Icons::Check : Icons::Times)
            + " No respawn time: " + Time::Format(noRespawnTime)
        ;
    }
}

