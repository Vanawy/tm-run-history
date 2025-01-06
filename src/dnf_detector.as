class DnfHandler {
    protected MLFeed::SpawnStatus last_spawn_status = MLFeed::SpawnStatus::Spawning;
    protected bool is_running = false;
    protected bool last_finish_state = false;

    bool isDNF(const MLFeed::PlayerCpInfo_V4@ cpInfo)
    {
        if (cpInfo is null) {
            return false;
        }

        if (!is_running && UI::CurrentActionMap() != "SpectatorMap" && cpInfo.CurrentRaceTime < 0 && cpInfo.SpawnStatus == MLFeed::SpawnStatus::Spawning) {
            is_running = true;
            return false;
        }

        if (is_running && cpInfo.SpawnStatus != last_spawn_status) {
            last_spawn_status = cpInfo.SpawnStatus;

            if (!last_finish_state && cpInfo.SpawnStatus == MLFeed::SpawnStatus::Spawning) {
                return true;
            }
        }

        if (cpInfo.IsFinished) {
            last_finish_state = true;
        } else if (cpInfo.SpawnStatus == MLFeed::SpawnStatus::Spawned) {
            last_finish_state = false;
        }

        return false;
    }

    void Reset() {
        last_spawn_status = MLFeed::SpawnStatus::Spawning;
        is_running = false;
        last_finish_state = false;
    }

    bool IsRunning() {
        return is_running;
    }
}