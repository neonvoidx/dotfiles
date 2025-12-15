from enum import Enum

from GtkHelper.ComboRow import SimpleComboRowItem
from GtkHelper.GenerativeUI.ColorButtonRow import ColorButtonRow
from GtkHelper.GenerativeUI.ComboRow import ComboRow
from GtkHelper.GenerativeUI.ExpanderRow import ExpanderRow
from GtkHelper.GenerativeUI.ScaleRow import ScaleRow
from .AudioCore import AudioCore
from ..globals import Colors
from ..internal.PulseHelpers import get_volumes_from_device


class Comparator(Enum):
    GT = SimpleComboRowItem("gt", "Greater than")
    LT = SimpleComboRowItem("lt", "Less than")
    EQ = SimpleComboRowItem("eq", "Equal to")
    NEQ = SimpleComboRowItem("neq", "Not equal to")
    GOE = SimpleComboRowItem("goe", "Greater or equal to")
    LOE = SimpleComboRowItem("loe", "Less or equal to")


class VolumeWarning(AudioCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.color_keys = [Colors.VOLUME_OK, Colors.VOLUME_WARNING]

        self.plugin_base.connect_to_event(event_id="com_gapls_AudioControl::PulseEvent",
                                          callback=self.on_pulse_device_change)

        self.plugin_base.asset_manager.colors.add_listener(self.color_changed)
        self.plugin_base.asset_manager.icons.remove_listener(self.icon_changed)

        self.comparator: SimpleComboRowItem = Comparator.GT.value
        self.warning_threshold: int = 50
        self.default_color = None
        self.warning_color = None
        self.critical_color = None

        self.create_generative_ui()

    def on_update(self):
        self.check_volume()

    def create_generative_ui(self):
        super().create_generative_ui()

        self.comparison_expander = ExpanderRow(
            action_core=self,
            var_name="comparison_expander",
            default_value=False,
            title="Comparison Row",
        )

        self.comparator_combo_row = ComboRow(
            action_core=self,
            var_name="comparator",
            default_value=Comparator.GT.value,
            items=[comparator.value for comparator in Comparator],
            title="comparator-dropdown",
            on_change=self.on_comparator_change
        )

        self.warning_threshold_scale = ScaleRow(
            action_core=self,
            var_name="warning-threshold",
            default_value=50,
            min=0,
            max=100,
            title="Warning Threshold",
            step=1,
            digits=0,
            draw_value=True,
            on_change=self.on_warning_threshold_change
        )

        self.comparison_expander.add_row(self.comparator_combo_row.widget)
        self.comparison_expander.add_row(self.warning_threshold_scale.widget)

        self.color_expander = ExpanderRow(
            action_core=self,
            var_name="color-expander",
            default_value=False,
            title="Color Row"
        )

        self.default_color_row = ColorButtonRow(
            action_core=self,
            var_name="default-color",
            default_value=self.get_color(Colors.VOLUME_OK).get_values(),
            title="Default Color",
            on_change=self.on_default_color_change
        )

        self.warning_color_row = ColorButtonRow(
            action_core=self,
            var_name="warning-color",
            default_value=self.get_color(Colors.VOLUME_WARNING).get_values(),
            title="Warning Color",
            on_change=self.on_warning_color_change
        )

        self.color_expander.add_row(self.default_color_row.widget)
        self.color_expander.add_row(self.warning_color_row.widget)

    def on_comparator_change(self, widget, value, old):
        self.comparator = value
        self.check_volume()

    def on_warning_threshold_change(self, widget, value, old):
        self.warning_threshold = value
        self.check_volume()

    def on_default_color_change(self, widget, value, old):
        self.default_color = value
        self.check_volume()

    def on_warning_color_change(self, widget, value, old):
        self.warning_color = value
        self.check_volume()

    ########### UI STUFF ###########

    async def on_pulse_device_change(self, *args, **kwargs):
        if len(args) < 2 or self.selected_device is None:
            return

        event = args[1]
        index = self.selected_device.pulse_index

        if event.index == index:
            self.check_volume()

    def check_volume(self):
        if self.warning_color is None or self.default_color is None:
            return

        volumes = get_volumes_from_device(self.device_filter, self.selected_device.pulse_name)
        volume = volumes[0]

        if self.comparator == Comparator.GT.value and volume > self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        elif self.comparator == Comparator.LT.value and volume < self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        elif self.comparator == Comparator.EQ.value and volume == self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        elif self.comparator == Comparator.GOE.value and volume >= self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        elif self.comparator == Comparator.LOE.value and volume <= self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        elif self.comparator == Comparator.NEQ.value and volume != self.warning_threshold:
            self.set_background_color(list(self.warning_color))
        else:
            self.set_background_color(list(self.default_color))

    def display_icon(self):
        return

    async def color_changed(self, event: str, key: str, asset):
        if not key in self.color_keys:
            return

        if key == Colors.VOLUME_OK:
            self.default_color_row._default_value = asset.get_values()
        elif key == Colors.VOLUME_WARNING:
            self.warning_color_row._default_value = asset.get_values()

        self.check_volume()

    def display_adjustment(self):
        return ""
