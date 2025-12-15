import enum

from loguru import logger as log

from GtkHelper.ComboRow import SimpleComboRowItem, BaseComboRowItem
from GtkHelper.GenerativeUI.ComboRow import ComboRow
from GtkHelper.GenerativeUI.EntryRow import EntryRow
from GtkHelper.GenerativeUI.ExpanderRow import ExpanderRow
from GtkHelper.GenerativeUI.SwitchRow import SwitchRow
from src.backend.PluginManager.ActionCore import ActionCore
from ..internal.PulseHelpers import DeviceFilter, get_device_list, filter_proplist, get_volumes_from_device, \
    get_standard_device


class InfoContent(enum.Enum):
    VOLUME = SimpleComboRowItem("volume", "Volume")
    ADJUSTMENT = SimpleComboRowItem("adjustment", "Adjustment")


class Device(BaseComboRowItem):
    def __init__(self, pulse_name, pulse_index, device_name):
        super().__init__()
        self.pulse_name: str = pulse_name
        self.pulse_index: int = pulse_index
        self.device_name: str = device_name

    def __str__(self):
        return self.device_name

    def get_value(self):
        return self.pulse_name


class AudioCore(ActionCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.has_configuration = True

        self.plugin_base.asset_manager.icons.add_listener(self.icon_changed)

        self.plugin_base.connect_to_event(event_id="com_gapls_AudioControl::PulseEvent",
                                          callback=self.on_pulse_device_change)

        # Settings

        self.selected_device: Device = None

        self.device_filter: DeviceFilter = None
        self.info_content = InfoContent.VOLUME.value

        self.show_device_name = True
        self.device_nick = ""

        self.show_info_content = True

        self.use_standard_device = False

        self.loaded_devices: list[Device] = []

        # Icon

        self.icon_keys = []

        self._current_icon = None
        self._icon_name = ""

        self.create_event_assigners()

    def create_generative_ui(self):
        self.device_expander = ExpanderRow(
            action_core=self,
            var_name="device-expander",
            default_value=False,
            title="Device Row",
            show_enable_switch=False
        )

        self.standard_device_switch = SwitchRow(
            action_core=self,
            var_name="use-standard",
            default_value=False,
            title="Standard Device",
            complex_var_name=False,
            on_change=self.show_standard_device_changed
        )

        self.device_filter_combo_row = ComboRow(
            action_core=self,
            var_name="device-filter",
            default_value=DeviceFilter.SINK.value,
            items=[device_filter.value for device_filter in DeviceFilter],
            title="base-filter-dropdown",
            complex_var_name=False,
            on_change=self.device_filter_changed
        )

        self.device_combo_row = ComboRow(
            action_core=self,
            var_name="pulse-name",
            default_value="",
            items=[],
            title="base-device-dropdown",
            complex_var_name=False,
            on_change=self.device_changed
        )

        self.device_expander.add_row(self.standard_device_switch.widget)
        self.device_expander.add_row(self.device_filter_combo_row.widget)
        self.device_expander.add_row(self.device_combo_row.widget)

        # Use Standard Device Toggle/Switch

        self.info_expander = ExpanderRow(
            action_core=self,
            var_name="info-expander",
            default_value=False,
            title="Info Row",
            show_enable_switch=False
        )

        self.info_content_switch = SwitchRow(
            action_core=self,
            var_name="show-info",
            default_value=True,
            title="base-info-toggle",
            complex_var_name=False,
            on_change=self.show_info_content_changed
        )

        self.info_content_combo_row = ComboRow(
            action_core=self,
            var_name="info-content",
            default_value=InfoContent.VOLUME.value,
            items=[info_content.value for info_content in InfoContent],
            title="base-info-content",
            complex_var_name=False,
            on_change=self.info_content_changed
        )

        self.info_expander.add_row(self.info_content_switch.widget)
        self.info_expander.add_row(self.info_content_combo_row.widget)

        self.device_name_expander = ExpanderRow(
            action_core=self,
            var_name="device-name-expander",
            default_value=False,
            title="Device Name Row",
            show_enable_switch=False
        )

        self.device_name_switch = SwitchRow(
            action_core=self,
            var_name="show-device-name",
            default_value=True,
            title="base-name-toggle",
            on_change=self.show_device_nick_changed
        )

        self.device_nick_entry = EntryRow(
            action_core=self,
            var_name="nick",
            default_value="",
            title="base-nick",
            complex_var_name=False,
            on_change=self.device_nick_changed
        )

        self.device_name_expander.add_row(self.device_name_switch.widget)
        self.device_name_expander.add_row(self.device_nick_entry.widget)

        self.device_filter = self.device_filter_combo_row.get_selected_item()

    def create_event_assigners(self):
        pass

    def on_update(self):
        self.display_device_name()
        self.display_device_info()
        self.display_icon()
        return

    def on_tick(self):
        self.check_standard_device()

    def load_devices(self):
        try:
            device_list = get_device_list(self.device_filter)

            self.loaded_devices = []

            for device in device_list:
                if device.description.__contains__("Monitor"):
                    continue

                device_name = filter_proplist(device.proplist)

                if device_name is None:
                    continue

                self.loaded_devices.append(Device(
                    pulse_name=device.name,
                    pulse_index=device.index,
                    device_name=device_name
                ))
        except Exception as e:
            log.error(f"Error while populating device list: {e}")
            return

        self.device_combo_row.populate(self.loaded_devices, self.device_combo_row.get_value())
        self.display_device_info()

    # UI Events

    def show_standard_device_changed(self, widget, value, old):
        self.use_standard_device = value
        self.device_combo_row.widget.set_sensitive(not self.use_standard_device)
        self.check_standard_device()

    def device_filter_changed(self, widget, value, old):
        self.device_filter = value
        self.load_devices()

    def device_changed(self, widget, value, old):
        self.selected_device = value

        self.display_device_name()
        self.display_device_info()

    def show_info_content_changed(self, widget, value, old):
        self.show_info_content = value
        self.display_device_info()

    def info_content_changed(self, widget, value, old):
        self.info_content = value
        self.display_device_info()

    def show_device_nick_changed(self, widget, value, old):
        self.show_device_name = value
        self.display_device_name()

    def device_nick_changed(self, widget, value, old):
        self.device_nick = value
        self.display_device_name()

    ############ DISPLAY #############

    def display_device_name(self):
        if not self.show_device_name:
            self.set_top_label("")
            return

        if not self.device_nick and not self.selected_device:
            return

        if self.device_nick and self.device_nick != "":
            self.set_top_label(self.device_nick)
        else:
            self.set_top_label(self.selected_device.device_name)

    def display_device_info(self):
        if not self.show_info_content:
            self.set_bottom_label("")
            return

        if self.info_content == InfoContent.VOLUME.value:
            self.set_bottom_label(self.display_volume())
        elif self.info_content == InfoContent.ADJUSTMENT.value:
            self.set_bottom_label(self.display_adjustment())
        else:
            self.set_bottom_label("")

    def display_volume(self):
        if not self.device_filter or not self.selected_device:
            return

        volumes = get_volumes_from_device(self.device_filter, self.selected_device.pulse_name)

        if len(volumes) > 0:
            return str(int(volumes[0]))
        return "N/A"

    def display_adjustment(self):
        return "B"

    async def icon_changed(self, event: str, key: str, asset):
        if not key in self.icon_keys:
            return

        if key != self._icon_name:
            return

        self._current_icon = asset
        self._icon_name = key

        self.display_icon()

    async def on_pulse_device_change(self, *args, **kwargs):
        if len(args) < 2 or self.selected_device is None:
            return

        event = args[1]
        index = self.selected_device.pulse_index

        if event.index == index:
            self.display_icon()
            self.display_device_info()

    def display_icon(self):
        if not self._current_icon:
            return

        _, rendered = self._current_icon.get_values()

        if rendered or None:
            self.set_media(image=rendered)

    def set_current_icon(self):
        pass

    def check_standard_device(self):
        if self.use_standard_device:
            standard_device = get_standard_device(self.device_filter)

            if self.selected_device is None or self.selected_device.pulse_name == standard_device.name:
                return

            for device in self.loaded_devices:
                if device.pulse_name != standard_device.name:
                    continue

                self.selected_device = device
                self.device_combo_row.set_selected_item(device)
                break
