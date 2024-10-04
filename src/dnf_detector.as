class DnfHandler {
    protected uint last_start_time = 0;
    protected bool is_running = false;
    protected bool last_finish_state = false;

    bool isDNF(const MLFeed::PlayerCpInfo_V4@ cpInfo)
    {
        if (cpInfo is null) {
            return false;
        }
        if (is_running && cpInfo.StartTime > last_start_time) {
            last_start_time = cpInfo.StartTime;
            if (!last_finish_state) {
                return true;
            }
        }
        is_running = true;
        last_start_time = cpInfo.StartTime;
        last_finish_state = cpInfo.IsFinished;
        return false;
    }
}