[Setting category="General" name="Records Limit" description="Limit amount of records displayed in history"]
uint recordsLimit = 10;

[Setting category="Display" name="Window position"]
vec2 anchor = vec2(0, 170);

[Setting category="Display" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;


int timeWidth = 53;
int deltaWidth = 60;

array<Record> records;

void AddTime(uint time) {
    uint count = records.Length;
    records.Resize(count + 1);
    records[count].time = time;
    for (int i = 0; i < records.Length; i++) {
        records[i].hidden = false;
        if (i < (records.Length - recordsLimit)) {
            records[i].hidden = true;
        }
    }
}

class Record {
	string title;
    uint time;
	string style;
	bool hidden;

    Record(){}
	
	Record(string &in title, uint time = -1, string &in style = "\\$fff") {
        this.title = title;
		this.time = time;
		this.style = style;
        this.hidden = false;
	}

    void DrawTitle() {
        UI::Text(this.style + this.title);
    }

	void DrawTime() {
		UI::Text(this.style + (this.time > 0 ? Time::Format(this.time) : "-:--.---"));
	}
    
	void DrawDelta(Record@ other) {
		int delta = other.time - this.time;
		if (delta < 0) {
			UI::Text("\\$77f-" + Time::Format(delta * -1));
		} else if (delta >= 0) {
			UI::Text("\\$f77+" + Time::Format(delta));
		}
    }
}


Record@ author = Record("AT", 0);
Record@ pb = Record("PB", 0);

array<Record@> targets = {pb, author};
uint currentTarget = 0;

void Main()
{
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);

    while (app is null || network is null) {
        yield();
    }

    print ("loaded");
	
	string currentMapUid = "";

    uint authorTime = 0;
    uint pbTime = 0;

	while(true) {
		auto map = app.RootMap;
		
		if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {

			if(currentMapUid != map.MapInfo.MapUid) {
                currentMapUid = map.MapInfo.MapUid;

                authorTime = map.TMObjective_AuthorTime;
                author.time = authorTime;
				print("New AT: " + Time::Format(authorTime));
            }
                
            if(network.ClientManiaAppPlayground !is null) {
                auto userMgr = network.ClientManiaAppPlayground.UserMgr;
                MwId userId;
                if (userMgr.Users.Length > 0) {
                    userId = userMgr.Users[0].Id;
                } else {
                    userId.Value = uint(-1);
                }
                
                auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
                uint newPbTime = scoreMgr.Map_GetRecord_v2(userId, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
                
                if (newPbTime != pbTime) {
                    pbTime = newPbTime;
                    pb.time = pbTime;
                    pb.hidden = true;
                    author.hidden = false;
                    print("PB: " + Time::Format(pbTime));
                    if (pb.time - author.time > 0) {
                        pb.hidden = false;
                        author.hidden = true;
                    }
                }
            }
        }

        sleep(500);
    }
}

// void RenderMenu()
// {
//   if (UI::MenuItem("\\$f00" + Icons::Circle + "\\$fff My first menu item!")) {
//     print("You clicked me!!");
//   }
// }

void Render() {
	auto app = cast<CTrackMania>(GetApp());
	
	auto map = app.RootMap;
	
	if(!UI::IsGameUIVisible()) {
		return;
	}
	
	if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
		if(lockPosition) {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
		} else {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
		}
		
		int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
        if (!UI::IsOverlayShown()) {
				windowFlags |= UI::WindowFlags::NoInputs;
		}

		UI::Begin("Run History", windowFlags);
		
		if(!lockPosition) {
			anchor = UI::GetWindowPos();
		}
		
		UI::BeginGroup();

		uint numCols = 3; 
		if(UI::BeginTable("table", numCols, UI::TableFlags::SizingFixedFit)) {
            UI::TableNextRow();
        
            UI::TableNextColumn();
            // setMinWidth(0);
            UI::Text("#" + recordsLimit);
            
            UI::TableNextColumn();
            // setMinWidth(timeWidth);
            UI::Text("Time");
            
            UI::TableNextColumn();
            // setMinWidth(deltaWidth);
            UI::Text("Delta");
			
			for(uint i = 0; i < targets.Length; i++) {
				if(targets[i].hidden) {
					continue;
				}
				UI::TableNextRow();
				
				UI::TableNextColumn();
				targets[i].DrawTitle();
				
				UI::TableNextColumn();
				targets[i].DrawTime();

                UI::TableNextColumn();
                UI::Text(Icons::Flag);
			}

            UI::TableNextRow();
			for(uint i = 0; i < numCols; i++) {
                UI::TableNextColumn();
                UI::Separator();
            }

			for(uint i = 0; i < records.Length; i++) {
				if(records[i].hidden) {
					continue;
				}
				UI::TableNextRow();
				
				UI::TableNextColumn();
				UI::Text("" + (i + 1));
				
				UI::TableNextColumn();
				records[i].DrawTime();

                UI::TableNextColumn();
                targets[currentTarget].DrawDelta(records[i]);
			}
			
			UI::EndTable();
		}
		UI::EndGroup();
		
		UI::End();
	}
}


void setMinWidth(int width) {
	UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
	UI::Dummy(vec2(width, 0));
	UI::PopStyleVar();
}

bool retireHandled = false;
bool finishHandled = false;
int startDrivingTime = 0;
int lastRaceTime = 0;


void Update(float dt) {

    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return;
    auto playground = cast<CSmArenaClient@>(app.CurrentPlayground);
    auto player = GetPlayer();
    if(playground is null 
        || player is null 
        || player.ScriptAPI is null 
        || player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
        return;
    }
    auto currentMap = playground.Map.IdName;
    
    auto scriptPlayer = cast<CSmScriptPlayer@>(player.ScriptAPI);
    auto post = scriptPlayer.Post;
    if(!retireHandled && post == CSmScriptPlayer::EPost::Char) {
        retireHandled = true;
        Retire();
    } else if(retireHandled && post == CSmScriptPlayer::EPost::CarDriver) {
        StartDriving();
        // Driving
        retireHandled = false;
    }

    auto terminal = playground.GameTerminals[0];
    auto uiSequence = terminal.UISequence_Current;
    // Player finishes map
    if(uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish && !finishHandled) {
        finishHandled = true;
        Finish();
    }
    if(uiSequence != CGamePlaygroundUIConfig::EUISequence::Finish && finishHandled) {
        finishHandled = false;
    }
}


CSmPlayer@ GetPlayer() {
    auto app = cast<CTrackMania@>(GetApp());
    if(app is null) return null;
    auto playground = cast<CSmArenaClient@>(app.CurrentPlayground);
    if(playground is null) return null;
    if(playground.GameTerminals.Length < 1) return null;
    auto terminal = playground.GameTerminals[0];
    if(terminal is null) return null;
    return cast<CSmPlayer@>(terminal.ControlledPlayer);
}

void StartDriving() {
    auto app = cast<CTrackMania@>(GetApp());
    if(app.Network is null || app.Network.PlaygroundClientScriptAPI is null) return;
    startDrivingTime = app.Network.PlaygroundClientScriptAPI.GameTime;
}

void Retire() {

}

void Finish() {
    auto app = cast<CTrackMania@>(GetApp());
    if( app.Network is null || app.Network.PlaygroundClientScriptAPI is null) {
        return;
    }
    lastRaceTime = app.Network.PlaygroundClientScriptAPI.GameTime - startDrivingTime;
    AddTime(lastRaceTime);
}
