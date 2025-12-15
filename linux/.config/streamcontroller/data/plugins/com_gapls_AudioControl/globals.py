from enum import StrEnum

class Icons(StrEnum):
    MAIN = "main-icon"
    MUTED = "mute"
    UNMUTED = "audio"
    VOLUME_UP = "vol-up"
    VOLUME_DOWN = "vol-down"
    SPEAKER_DEFAULT = "speaker-default"
    HEADPHONE_DEFAULT = "headphone-default"
    NONE_DEFAULT = "none-default"

class Colors(StrEnum):
    VOLUME_OK = "volume-ok"
    VOLUME_WARNING = "volume-warning"