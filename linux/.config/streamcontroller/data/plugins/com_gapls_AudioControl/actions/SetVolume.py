from loguru import logger as log

from GtkHelper.GenerativeUI.ExpanderRow import ExpanderRow
from GtkHelper.GenerativeUI.ScaleRow import ScaleRow
from GtkHelper.GenerativeUI.SwitchRow import SwitchRow
from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.PluginManager.EventAssigner import EventAssigner
from .AudioCore import AudioCore
from ..globals import Icons
from ..internal.PulseHelpers import get_device, set_volume


class SetVolume(AudioCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.icon_keys = [Icons.UNMUTED]
        self._icon_name = Icons.UNMUTED
        self._current_icon = self.get_icon(Icons.UNMUTED)

        self.volume: int = 50
        self.extend_volume: bool = False

        self.create_generative_ui()

    def create_generative_ui(self):
        super().create_generative_ui()

        self.volume_expander = ExpanderRow(
            action_core=self,
            var_name="volume-expander",
            default_value=False,
            title="Volume Row",
        )

        self.extend_volume_switch = SwitchRow(
            action_core=self,
            var_name="volume-extend",
            default_value=False,
            title="Extend Volume Slider",
            on_change=self.extend_volume_changed
        )

        self.volume_slider = ScaleRow(
            action_core=self,
            var_name="volume",
            default_value=50,
            min=0,
            max=100,
            title="Volume",
            step=1,
            digits=0,
            on_change=self.volume_changed
        )

        self.volume_expander.add_row(self.extend_volume_switch.widget)
        self.volume_expander.add_row(self.volume_slider.widget)

    def create_event_assigners(self):
        self.add_event_assigner(EventAssigner(
            id="set-volume",
            ui_label="Set Volume",
            default_events=[Input.Key.Events.DOWN, Input.Dial.Events.DOWN],
            callback=self.on_set_volume
        ))

    def on_ready(self):
        super().on_ready()

    def on_set_volume(self, event):
        if self.selected_device is None:
            self.show_error(1)
            return

        try:
            device = get_device(self.device_filter, self.selected_device.pulse_name)
            set_volume(device, self.volume)
        except Exception as e:
            log.error(e)
            self.show_error(1)

    def volume_changed(self, widget, value, old):
        self.volume = value
        self.display_device_info()

    def extend_volume_changed(self, widget, value, old):
        self.extend_volume = value

        if self.extend_volume:
            self.volume_slider.max = 150
        else:
            self.volume_slider.max = 100

        self.volume_slider.widget.scale.set_value(self.volume_slider.widget.scale.get_value())

    ########### UI STUFF ###########

    def display_adjustment(self):
        return str(self.volume)
