from .AudioCore import AudioCore, InfoContent

from ..globals import Icons


class AudioDisplay(AudioCore):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.icon_keys = [Icons.MUTED, Icons.UNMUTED]

        self.plugin_base.connect_to_event(event_id="com_gapls_AudioControl::PulseEvent",
                                          callback=self.on_pulse_device_change)

        self.create_generative_ui()

    def create_generative_ui(self):
        super().create_generative_ui()

    def on_ready(self):
        self.info_content_combo_row.populate([InfoContent.VOLUME.value])

    def on_update(self):
        super().on_update()
