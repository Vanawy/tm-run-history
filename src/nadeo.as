namespace Nadeo {
    int GetMapWorldRecord(const string &in mapUid) {
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        string url = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=1";

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            return -1;
        }

        try {
            return res["tops"][0]["top"][0]["score"];
        } catch {
            return -1;
        }
    }
}