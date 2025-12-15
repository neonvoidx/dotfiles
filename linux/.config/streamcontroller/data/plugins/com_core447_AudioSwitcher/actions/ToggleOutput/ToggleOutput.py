# Import StreamController modules
from GtkHelper.GtkHelper import ComboRow
from src.backend.PluginManager.ActionBase import ActionBase
from src.backend.DeckManagement.DeckController import DeckController
from src.backend.PageManagement.Page import Page
from src.backend.PluginManager.PluginBase import PluginBase

# Import python modules
import os

# Import gtk modules - used for the config rows
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Pango

import pulsectl

class ToggleOutput(ActionBase):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        self.old_state: int = None

    def on_ready(self):
        self.old_state = None
        self.show_state()

    def show_state(self) -> None:
        new_state = self.get_active_sink()
        if new_state == self.old_state:
            return
        self.old_state = new_state

        if new_state == -1:
            self.set_media(media_path=os.path.join(self.plugin_base.PATH, "assets", "speakers.png"), size=0.75)
        elif new_state == 1:
            self.set_media(media_path=os.path.join(self.plugin_base.PATH, "assets", "headphones.png"), size=0.75)
        else:
            self.set_media(media_path=os.path.join(self.plugin_base.PATH, "assets", "none.png"), size=0.75)

    def on_tick(self):
        self.show_state()

    def get_config_rows(self) -> list:
        self.device_model = Gtk.ListStore.new([str]) # First Column: Name,
        self.device_display_name = Gtk.ListStore.new([str])


        self.device_A_row = ComboRow(title=self.plugin_base.lm.get("actions.toggle-output.device-a.title"), model=self.device_display_name)
        self.device_cell_renderer = Gtk.CellRendererText(ellipsize=Pango.EllipsizeMode.END, max_width_chars=60)
        self.device_A_row.combo_box.pack_start(self.device_cell_renderer, True)
        self.device_A_row.combo_box.add_attribute(self.device_cell_renderer, "text", 0)

        self.device_B_row = ComboRow(title=self.plugin_base.lm.get("actions.toggle-output.device-b.title"), model=self.device_display_name)
        self.device_cell_renderer = Gtk.CellRendererText()

        self.device_B_row.combo_box.pack_start(self.device_cell_renderer, True)
        self.device_B_row.combo_box.add_attribute(self.device_cell_renderer, "text", 0)

        self.load_device_model()

        self.device_A_row.combo_box.connect("changed", self.on_device_change)
        self.device_B_row.combo_box.connect("changed", self.on_device_change)

        self.load_config_settings()

        return [self.device_A_row, self.device_B_row]
    
    def load_device_model(self):
        self.device_model.clear()
        with pulsectl.Pulse('set-output') as pulse:
            for sink in pulse.sink_list():
                name = self.get_sink_identifier(sink)
                display_name = self.get_device_display_name(sink)
                if name is None:
                    continue
                self.device_model.append([name])
                self.device_display_name.append([display_name])

    def load_config_settings(self):
        settings = self.get_settings()
        device_a = settings.get("device_a")
        device_b = settings.get("device_b")

        self.device_A_row.combo_box.set_active(-1)
        self.device_B_row.combo_box.set_active(-1)
        for i, device in enumerate(self.device_model):
            if device[0] == device_a:
                self.device_A_row.combo_box.set_active(i)
            if device[0] == device_b:
                self.device_B_row.combo_box.set_active(i)


    def on_device_change(self, combo_box, *args):
        device_a = self.device_model[self.device_A_row.combo_box.get_active()][0]
        device_b = self.device_model[self.device_B_row.combo_box.get_active()][0]
        settings = self.get_settings()
        settings["device_a"] = device_a
        settings["device_b"] = device_b
        self.set_settings(settings)

    def get_active_sink(self) -> int:
        """
        -1 if a
        1 if b
        0 if other
        """
        settings = self.get_settings()
        device_a  = settings.get("device_a")
        device_b  = settings.get("device_b")


        with pulsectl.Pulse('set-output') as pulse:
            default_sink = pulse.sink_default_get()
            for sink in pulse.sink_list():
                name = self.get_sink_identifier(sink)
                if name == device_a and sink.index == default_sink.index:
                    return -1
                if name == device_b and sink.index == default_sink.index:
                    return 1
                
        return 0

    def on_key_down(self):
        self.old_state = None
        settings = self.get_settings()
        device_a = settings.get("device_a")
        device_b = settings.get("device_b")
        if None in [device_a, device_b]:
            self.show_error(1)
            return
        
        default_sink_result = self.get_active_sink()
        with pulsectl.Pulse('set-output') as pulse:
            for sink in pulse.sink_list():
                name = self.get_sink_identifier(sink)
                
                if default_sink_result == -1:
                    # Device a is selected
                    if name == device_b:
                        pulse.default_set(sink)
                        break
                else:
                    # Either device b or none of them is selected
                    if name == device_a:
                        pulse.default_set(sink)
                        break

        self.show_state()

    def get_device_display_name(self, sink) -> str:
        proplist = sink.proplist
        name = (proplist.get("device.product.name") or proplist.get("device.nick") or
                proplist.get("device.description") or sink.name or None)
        description = proplist.get("device.profile.description")
        if description not in ("", None):
            name = f'{name} ({description})'
        return name
    
    def get_sink_identifier(self, sink) -> str:
        proplist = sink.proplist
        return proplist.get("node.name") or sink.name