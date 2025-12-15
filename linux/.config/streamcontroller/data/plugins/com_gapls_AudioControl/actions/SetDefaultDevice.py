import pulsectl
from loguru import logger as log

from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.PluginManager.EventAssigner import EventAssigner
from .AudioCore import AudioCore
from ..globals import Icons
from ..internal.PulseHelpers import get_device, mute, set_default_device, get_standard_device


class SetDefaultDevice(AudioCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.icon_keys = [Icons.HEADPHONE_DEFAULT, Icons.NONE_DEFAULT]

        self.plugin_base.connect_to_event(event_id="com_gapls_AudioControl::PulseEvent",
                                          callback=self.on_pulse_device_change)

        self.create_generative_ui()

    def create_generative_ui(self):
        super().create_generative_ui()

        self.standard_device_switch.widget.hide()
        self.standard_device_switch = None

    def create_event_assigners(self):
        self.add_event_assigner(EventAssigner(
            id="set-default-device",
            ui_label="Set Default Device",
            default_events=[Input.Key.Events.DOWN, Input.Dial.Events.DOWN],
            callback=self.on_set_default_device
        ))

    def on_update(self):
        super().on_update()

    def on_tick(self):
        self.set_current_icon()
        self.display_device_info()

    def on_set_default_device(self, event):
        if self.selected_device is None:
            self.show_error(1)
            return

        try:
            set_default_device(self.device_filter, self.selected_device.pulse_name)
            self.display_device_info()
            self.set_current_icon()
        except Exception as e:
            log.error(f"Error while setting default device: {e}")
            self.show_error(1)

    ########### UI STUFF ###########

    def set_current_icon(self):
        standard_device = get_standard_device(self.device_filter)

        if standard_device.name == self.selected_device.pulse_name:
            self._current_icon = self.get_icon(Icons.HEADPHONE_DEFAULT)
            self._icon_name = Icons.HEADPHONE_DEFAULT
        else:
            self._current_icon = self.get_icon(Icons.NONE_DEFAULT)
            self._icon_name = Icons.NONE_DEFAULT

        self.display_icon()

    def display_adjustment(self):
        standard_device = get_standard_device(self.device_filter)

        if standard_device.name == self.selected_device.pulse_name:
            return "SELECTED"
        return ""