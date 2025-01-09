namespace Windows {

    const string MAIN = "Main";
    const string MEDALS = "Medals";

    enum ShowIf {
        Always,
        InterfaceShown,
        InterfaceHidden,
        OverlayShown,
        Never,
    }

    bool ShowMainWindow() {
        return _CheckOption(setting_main_show_window);
    }

    bool ShowMedalsWindow() {
        return _CheckOption(setting_medals_show_window);
    }

    int Flags(bool with_inputs = false) {
        int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
        if (!with_inputs || !UI::IsOverlayShown()) {
            windowFlags |= UI::WindowFlags::NoInputs;
        }
        return windowFlags;
    }

    bool _CheckOption(ShowIf option) {
        switch (option) {
            case ShowIf::Always:
                return true;
            case ShowIf::InterfaceShown:
                return UI::IsGameUIVisible();
            case ShowIf::InterfaceHidden:
                return !UI::IsGameUIVisible();
            case ShowIf::OverlayShown:
                return UI::IsOverlayShown();
            case ShowIf::Never:
                return false;
        }
        return false;
    }
}