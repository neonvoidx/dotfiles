import gi

from GtkHelper.GenerativeUI.ComboRow import ComboRow
from GtkHelper.GenerativeUI.ExpanderRow import ExpanderRow
from GtkHelper.GenerativeUI.SwitchRow import SwitchRow
from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.PluginManager.ActionCore import ActionCore
from src.backend.PluginManager.EventAssigner import EventAssigner
from src.backend.PluginManager.PluginSettings.Asset import Color, Icon

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from ..internal.PulseHelpers import DeviceFilter, get_device_list, filter_proplist, get_volumes_from_device, \
    get_standard_device, set_default_device

from .AudioCore import Device, InfoContent

from loguru import logger as log

from ..globals import Icons

from enum import StrEnum


class DeviceSelection(StrEnum):
    NONE = "none"
    SPEAKER = "speaker"
    HEADPHONE = "headphone"


class ToggleDefaultDevice(ActionCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.has_configuration = True

        self.plugin_base.asset_manager.icons.add_listener(self.icon_changed)

        self.plugin_base.connect_to_event(event_id="com_gapls_AudioControl::PulseEvent",
                                          callback=self.on_pulse_device_change)

        # Action Variables
        self.speaker_device: Device = None
        self.headphone_device: Device = None

        self.device_filter: DeviceFilter = None
        self.info_content: InfoContent = None

        self.show_device_name: bool = True
        self.show_info_content: bool = True

        self.loaded_devices: list[Device] = []

        # Setup AssetManager values
        self.icon_keys = []
        self.color_keys = []

        self.current_icon: Icon = None
        self.current_color: Color = None
        self.icon_name = ""
        self.color_name = ""

        self.plugin_base.asset_manager.icons.add_listener(self.icon_changed)
        self.plugin_base.asset_manager.colors.add_listener(self.color_changed)

        # Setup Action Related Stuff
        self.create_generative_ui()
        self.create_event_assigners()

    # ----------# Setup Action Stuff #----------#
    # Only contains the two methods

    def create_generative_ui(self):
        self.device_expander = ExpanderRow(
            action_core=self,
            var_name="device-expander",
            default_value=False,
            title="Device Row",
            show_enable_switch=False
        )

        self.device_filter_combo_row = ComboRow(
            action_core=self,
            var_name="filter",
            default_value=DeviceFilter.SINK.value,
            items=[DeviceFilter.SINK.value, DeviceFilter.SOURCE.value],
            title="base-filter-dropdown",
            complex_var_name=False,
            on_change=self.device_filter_changed
        )

        self.speaker_combo_row = ComboRow(
            action_core=self,
            var_name="speaker-pulse-name",
            default_value="",
            items=[],
            title="Device 1",
            complex_var_name=False,
            on_change=self.speaker_changed
        )

        self.headphone_combo_row = ComboRow(
            action_core=self,
            var_name="headphone-pulse-name",
            default_value="",
            items=[],
            title="Device 2",
            complex_var_name=False,
            on_change=self.headphone_changed
        )

        self.device_expander.add_row(self.device_filter_combo_row.widget)
        self.device_expander.add_row(self.speaker_combo_row.widget)
        self.device_expander.add_row(self.headphone_combo_row.widget)

        self.info_expander = ExpanderRow(
            action_core=self,
            var_name="info-expander",
            default_value=False,
            title="Info Row",
            show_enable_switch=False
        )

        self.info_content_switch = SwitchRow(
            action_core=self,
            var_name="info-content-visible",
            default_value=True,
            title="base-info-toggle",
            complex_var_name=False,
            on_change=self.show_info_content_changed
        )

        self.info_content_combo_row = ComboRow(
            action_core=self,
            var_name="info-content-type",
            default_value=InfoContent.VOLUME.value,
            items=[InfoContent.VOLUME.value, InfoContent.ADJUSTMENT.value],
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

        self.device_name_expander.add_row(self.device_name_switch.widget)

        self.device_filter = self.device_filter_combo_row.get_selected_item()

    def create_event_assigners(self):
        self.add_event_assigner(EventAssigner(
            id="toggle-default-device",
            ui_label="Toggle Default Device",
            default_events=[Input.Key.Events.DOWN, Input.Dial.Events.DOWN],
            tooltip="",
            callback=self.on_toggle_device
        ))

    # ----------# Action Events #----------#
    # Contains all methods that come from the ActionCore itself

    def on_update(self):
        self.change_icon()

        self.display_device_name()
        self.display_device_info()
        self.display_icon()

    def on_tick(self):
        self.change_icon()

        self.display_device_name()
        self.display_device_info()
        self.display_icon()

    # ----------# Event Assigner Events #----------#
    # Contains all methods for the Event Assigner

    def on_toggle_device(self, event):
        selection, _ = self.get_selected_device()

        if selection == DeviceSelection.SPEAKER:
            set_default_device(self.device_filter, self.headphone_device.pulse_name)
        elif selection == DeviceSelection.HEADPHONE:
            set_default_device(self.device_filter, self.speaker_device.pulse_name)

        self.change_icon()

        self.display_device_name()
        self.display_device_info()
        self.display_icon()

    # ----------# Ui Events #----------#
    # Contains all methods for Ui Events

    def device_filter_changed(self, widget, value, old):
        self.device_filter = value
        self.load_devices()

    def speaker_changed(self, widget, value, old):
        self.speaker_device = value

        self.change_icon()
        self.display_device_name()
        self.display_device_info()
        self.display_icon()

    def headphone_changed(self, widget, value, old):
        self.headphone_device = value

        self.change_icon()
        self.display_device_name()
        self.display_device_info()
        self.display_icon()

    def show_info_content_changed(self, widget, value, old):
        self.show_info_content = value
        self.display_device_info()

    def info_content_changed(self, widget, value, old):
        self.info_content = value
        self.display_device_info()

    def show_device_nick_changed(self, widget, value, old):
        self.show_device_name = value
        self.display_device_name()

    # ----------# Display #----------#
    # Contains all methods that display something on the deck

    def change_color(self, *args, **kwargs):
        pass

    def change_icon(self, *args, **kwargs):
        selection, _ = self.get_selected_device()

        if selection == DeviceSelection.HEADPHONE:
            self.icon_name = Icons.HEADPHONE_DEFAULT
        elif selection == DeviceSelection.SPEAKER:
            self.icon_name = Icons.SPEAKER_DEFAULT
        else:
            self.icon_name = Icons.NONE_DEFAULT
        self.current_icon = self.get_icon(self.icon_name)

    def display_icon(self):
        if not self.current_icon:
            return

        _, rendered = self.current_icon.get_values()

        if rendered or None:
            self.set_media(image=rendered)

    def display_color(self):
        if not self.current_color:
            return

        color = self.current_color.get_values()

        self.set_background_color(color)

    def display_device_name(self):
        if not self.show_device_name:
            self.set_top_label("")
            return

        selection, _ = self.get_selected_device()
        selected_device = self.get_device_from_selection(selection)

        if selected_device is None:
            name = ""
        else:
            name = selected_device.device_name

        self.set_top_label(name)

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
        selection, _ = self.get_selected_device()
        selected_device = self.get_device_from_selection(selection)

        if not self.device_filter or not selected_device:
            return

        volumes = get_volumes_from_device(self.device_filter, selected_device.pulse_name)

        if len(volumes) > 0:
            return str(int(volumes[0]))
        return "N/A"

    def display_adjustment(self):
        selection, _ = self.get_selected_device()

        if selection == DeviceSelection.SPEAKER:
            return "Device 1"
        elif selection == DeviceSelection.HEADPHONE:
            return "Device 2"

    # ----------# Asset Management #----------#
    # Contains all methods that handle Asset Management

    async def icon_changed(self, event: str, key: str, asset):
        if not key in self.icon_keys:
            return

        if key != self.icon_name:
            return

        self.current_icon = asset
        self.icon_name = key

        self.display_icon()

    async def color_changed(self, event: str, key: str, asset):
        if not key in self.color_keys:
            return

        if key != self.color_name:
            return

        self.current_color = asset
        self.color_name = key

        self.display_color()

    # ----------# Misc #----------#
    # Contains all other Methods

    async def on_pulse_device_change(self, *args, **kwargs):
        selection, _ = self.get_selected_device()
        selected_device = self.get_device_from_selection(selection)

        if len(args) < 2 or selected_device is None:
            return

        event = args[1]
        index = selected_device.pulse_index

        if event.index == index:
            self.display_icon()
            self.display_device_info()

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

        self.speaker_combo_row.populate(self.loaded_devices, self.speaker_combo_row.get_value())
        self.headphone_combo_row.populate(self.loaded_devices, self.headphone_combo_row.get_value())

        self.display_device_info()

    def get_selected_device(self) -> tuple:
        try:
            device = get_standard_device(self.device_filter)

            if self.headphone_device is None or self.speaker_device is None:
                return DeviceSelection.NONE, device

            if device.name == self.headphone_device.pulse_name:
                return DeviceSelection.HEADPHONE, device
            elif device.name == self.speaker_device.pulse_name:
                return DeviceSelection.SPEAKER, device
            else:
                return DeviceSelection.NONE, device

        except Exception as e:
            log.error(f"Error while getting selected standard device: {e}")

        return DeviceSelection.NONE, None

    def get_device_from_selection(self, device_selection: DeviceSelection):
        if device_selection == DeviceSelection.HEADPHONE:
            return self.headphone_device
        elif device_selection == DeviceSelection.SPEAKER:
            return self.speaker_device
        else:
            return None
