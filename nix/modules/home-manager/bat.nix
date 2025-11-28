{ config, pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;
    
    config = {
      theme = "Eldritch";
      # pager = "less --RAW-CONTROL-CHARS --quit-if-one-screen --mouse";
    };
  };

  # Create Eldritch theme for bat
  xdg.configFile."bat/themes/Eldritch.tmTheme".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Eldritch</string>
      <key>settings</key>
      <array>
        <dict>
          <key>settings</key>
          <dict>
            <key>background</key>
            <string>#212337</string>
            <key>foreground</key>
            <string>#ebfafa</string>
            <key>caret</key>
            <string>#37f499</string>
            <key>lineHighlight</key>
            <string>#323449</string>
            <key>selection</key>
            <string>#bf4f8e</string>
            <key>findHighlight</key>
            <string>#f1fc79</string>
            <key>findHighlightForeground</key>
            <string>#212337</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Comment</string>
          <key>scope</key>
          <string>comment</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#7081d0</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>String</string>
          <key>scope</key>
          <string>string</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#f1fc79</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Number</string>
          <key>scope</key>
          <string>constant.numeric</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#a48cf2</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Keyword</string>
          <key>scope</key>
          <string>keyword</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#f265b5</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Function</string>
          <key>scope</key>
          <string>entity.name.function</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#37f499</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Type</string>
          <key>scope</key>
          <string>entity.name.type, support.type</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#04d1f9</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Variable</string>
          <key>scope</key>
          <string>variable</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#ebfafa</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Constant</string>
          <key>scope</key>
          <string>constant</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#a48cf2</string>
          </dict>
        </dict>
        <dict>
          <key>name</key>
          <string>Error</string>
          <key>scope</key>
          <string>invalid</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>#f16c75</string>
          </dict>
        </dict>
      </array>
    </dict>
    </plist>
  '';
}
