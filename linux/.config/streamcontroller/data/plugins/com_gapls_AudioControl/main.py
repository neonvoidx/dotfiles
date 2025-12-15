# Import StreamController modules
import os.path

import pulsectl
from gi.repository import Gtk

from src.backend.PluginManager.ActionHolder import ActionHolder
from src.backend.PluginManager.ActionInputSupport import ActionInputSupport
from src.backend.PluginManager.EventHolder import EventHolder
from src.backend.PluginManager.PluginBase import PluginBase
from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.DeckManagement.ImageHelpers import image2pixbuf

from .internal.PulseEventListener import PulseEvent

from .actions.Mute import Mute
from .actions.SetVolume import SetVolume
from .actions.AdjustVolume import AdjustVolume
from .actions.ToggleDefaultDevice import ToggleDefaultDevice
from .actions.VolumeWarning import VolumeWarning
from .actions.AudioDisplay import AudioDisplay
from .actions.SetDefaultDevice import SetDefaultDevice

from .globals import Icons, Colors

class AudioControl(PluginBase):
    def __init__(self):
        super().__init__(use_legacy_locale=False)
        self.init_vars()

        self.has_plugin_settings = True

        self.audio_display = ActionHolder(
            plugin_base=self,
            action_core=AudioDisplay,
            action_id_suffix="AudioDisplay",
            action_name="Audio Display",
            action_support= {
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.audio_display)

        self.mute = ActionHolder(
            plugin_base=self,
            action_core=Mute,
            action_id_suffix="Mute",
            action_name="Mute",
            action_support= {
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.mute)

        self.set_volume = ActionHolder(
            plugin_base=self,
            action_core=SetVolume,
            action_id_suffix="SetVolume",
            action_name="Set Volume",
            action_support= {
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.set_volume)

        self.volume_adjust = ActionHolder(
            plugin_base=self,
            action_core=AdjustVolume,
            action_id_suffix="AdjustVolume",
            action_name="Adjust Volume",
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.volume_adjust)

        self.toggle_default_device = ActionHolder(
            plugin_base=self,
            action_core=ToggleDefaultDevice,
            action_id_suffix="ToggleDefaultDevice",
            action_name="Toggle Default Device",
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.toggle_default_device)

        self.set_default_device = ActionHolder(
            plugin_base=self,
            action_core=SetDefaultDevice,
            action_id_suffix="SetDefaultDevice",
            action_name="Set Default Device",
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.set_default_device)

        self.volume_warning = ActionHolder(
            plugin_base=self,
            action_core=VolumeWarning,
            action_id_suffix="VolumeWarning",
            action_name="Volume Warning",
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.volume_warning)

        # Events

        self.pulse_sink_event_holder = PulseEvent(
            self,
            "com_gapls_AudioControl::PulseEvent",
            pulsectl.PulseEventMaskEnum.sink,
            pulsectl.PulseEventMaskEnum.source
        )
        self.add_event_holder(self.pulse_sink_event_holder)

        self.register()

    def get_selector_icon(self) -> Gtk.Widget:
        _, rendered = self.asset_manager.icons.get_asset_values(Icons.MAIN)
        return Gtk.Image.new_from_pixbuf(image2pixbuf(rendered))

    def init_vars(self):
        self.pulse = pulsectl.Pulse("audio-control-main")

        self.add_color(Colors.VOLUME_OK, (0,0,0,0))
        self.add_color(Colors.VOLUME_WARNING, (111,29,29,255))

        size = 0.7

        self.add_icon(Icons.MAIN, self.get_asset_path("main_icon.png"))

        self.add_icon(Icons.MUTED, self.get_asset_path("audio_muted.png"), size)
        self.add_icon(Icons.UNMUTED, self.get_asset_path("audio.png"), size)
        self.add_icon(Icons.VOLUME_DOWN, self.get_asset_path("volume_down.png"), size)
        self.add_icon(Icons.VOLUME_UP, self.get_asset_path("volume_up.png"), size)

        self.add_icon(Icons.SPEAKER_DEFAULT, self.get_asset_path("speaker_default.png"))
        self.add_icon(Icons.HEADPHONE_DEFAULT, self.get_asset_path("headphone_default.png"))
        self.add_icon(Icons.NONE_DEFAULT, self.get_asset_path("none_default.png"))