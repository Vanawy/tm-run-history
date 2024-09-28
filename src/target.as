class Target {
    string color;
    string icon;
    int time;
    
    Target(string &in color, string &in icon, int time = 0) {
        this.color = color;
        this.icon = icon;
        this.time = time;
    }

    string coloredIcon()
    {
        return color + icon;
    }

    bool hasTime()
    {
        return time > 0;
    }
}

