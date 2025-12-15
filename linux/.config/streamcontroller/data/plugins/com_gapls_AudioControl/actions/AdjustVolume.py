from loguru import logger as log

from GtkHelper.GenerativeUI.ExpanderRow import ExpanderRow
from GtkHelper.GenerativeUI.ScaleRow import ScaleRow
from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.PluginManager.EventAssigner import EventAssigner
from .AudioCore import AudioCore
from ..globals import Icons
from ..internal.PulseHelpers import get_device, change_volume, get_volumes_from_device, set_volume


class AdjustVolume(AudioCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.icon_keys = [Icons.VOLUME_UP, Icons.VOLUME_DOWN]

        self.adjust: int = 1
        self.bounds = 100

        self.create_generative_ui()

    def create_generative_ui(self):
        super().create_generative_ui()

        self.volume_adjust_row = ExpanderRow(
            action_core=self,
            var_name="adjust-expander",
            default_value=False,
            title="Volume Adjust Row",
        )

        self.volume_adjust_scale = ScaleRow(
            action_core=self,
            var_name="volume-adjust",
            default_value=1,
            min=-100,
            max=100,
            step=1,
            digits=0,
            title="Adjustment",
            draw_value=True,
            on_change=self.on_volume_adjust_change
        )

        self.volume_bound_scale = ScaleRow(
            action_core=self,
            var_name="volume-bounds",
            default_value=100,
            min=0,
            max=150,
            step=1,
            digits=0,
            title="Maximum Audio Bounds",
            draw_value=True,
            on_change=self.on_volume_bound_change
        )

        self.volume_adjust_row.add_row(self.volume_adjust_scale.widget)
        self.volume_adjust_row.add_row(self.volume_bound_scale.widget)

    def create_event_assigners(self):
        self.add_event_assigner(EventAssigner(
            id="adjust-volume-positive",
            ui_label="Adjust Volume Positive",
            default_events=[Input.Key.Events.DOWN, Input.Dial.Events.TURN_CW],
            callback=self.event_adjust_volume_positive
        ))

        self.add_event_assigner(EventAssigner(
            id="adjust-volume-negative",
            ui_label="Adjust Volume Negative",
            default_event=Input.Dial.Events.TURN_CCW,
            callback=self.event_adjust_volume_negative
        ))

    def event_adjust_volume_positive(self, event):
        self.adjust_volume()

    def event_adjust_volume_negative(self, event):
        self.adjust_volume(-1)

    def adjust_volume(self, modifier: int = 1):
        adjustment = self.adjust * modifier

        if self.selected_device is None:
            self.show_error(1)
            return

        try:
            device = get_device(self.device_filter, self.selected_device.pulse_name)

            if adjustment < 0:
                change_volume(device, adjustment)
                return

            volumes = get_volumes_from_device(self.device_filter, device.name)

            if len(volumes) > 0 and volumes[0] < self.bounds:
                if volumes[0] + adjustment > self.bounds:
                    set_volume(device, self.bounds)
                else:
                    change_volume(device, adjustment)
        except Exception as e:
            log.error(e)
            self.show_error(1)

    def on_volume_adjust_change(self, widget, value, old):
        self.adjust = value
        self.display_device_info()
        self.set_current_icon()

    def on_volume_bound_change(self, widget, value, old):
        self.bounds = value

    ########### UI STUFF ###########

    def set_current_icon(self):
        if self.adjust >= 0:
            self._current_icon = self.get_icon(Icons.VOLUME_UP)
            self._icon_name = Icons.VOLUME_UP
        else:
            self._current_icon = self.get_icon(Icons.VOLUME_DOWN)
            self._icon_name = Icons.VOLUME_DOWN

        self.display_icon()

    def display_adjustment(self):
        return f"{"+" if self.adjust > 0 else ""}{self.adjust}"
