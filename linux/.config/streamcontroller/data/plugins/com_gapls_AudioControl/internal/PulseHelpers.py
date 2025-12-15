import enum

import pulsectl
from loguru import logger as log

from GtkHelper.ComboRow import SimpleComboRowItem


class DeviceFilter(enum.Enum):
    SINK = SimpleComboRowItem("sink", "Sink")
    SOURCE = SimpleComboRowItem("source", "Source")

    def get_value(self):
        return self.value.get_value()

def filter_proplist(proplist) -> str | None:
    filters: list[str] = [
        "alsa.card_name",
        "alsa.long_card_name",
        "node.name",
        "node.nick",
        "device.name",
        "device.nick",
        "device.description",
        "device.serial"
    ]

    weights: list[(str, int)] = [
        ('.', -50),
        ('_', -10),
        (':', -25),
        (';', -100),
        ('-', -5)
    ]

    length_weight: int = -5

    minimal_weights: list[(int, str)] = []

    for filter in filters:
        out: str = proplist.get(filter)

        if out is None or len(out) < 3:
            continue
        current_weight: int = 0

        current_weight += sum(out.count(weight[0]) * weight[1] for weight in weights)
        current_weight += (len(out) * length_weight)

        minimal_weights.append((current_weight, out))

    minimal_weights.sort(key=lambda x: x[0], reverse=True)

    if len(minimal_weights) > 0:
        return minimal_weights[0][1] or None
    return None


def get_device(filter: DeviceFilter, pulse_device_name):
    with pulsectl.Pulse("device-getter") as pulse:
        try:
            device = None
            if filter == DeviceFilter.SINK.get_value():
                device = pulse.get_sink_by_name(pulse_device_name)
            elif filter == DeviceFilter.SOURCE.get_value():
                device = pulse.get_source_by_name(pulse_device_name)
            return device
        except Exception as e:
            log.error(f"Error while getting device: {pulse_device_name} with filter: {filter}. Error: {e}")
    return None


def get_device_list(filter: DeviceFilter):
    with pulsectl.Pulse("device-list-getter") as pulse:
        switch = {
            DeviceFilter.SINK.get_value(): pulse.sink_list(),
            DeviceFilter.SOURCE.get_value(): pulse.source_list(),
        }
        return switch.get(filter.get_value(), {})

def get_volumes_from_device(device_filter: DeviceFilter, pulse_device_name: str):
    try:
        device = get_device(device_filter, pulse_device_name)
        device_volumes = device.volume.values
        return [round(vol * 100) for vol in device_volumes]
    except Exception as e:
        log.error(f"Error while getting volumes from device: {pulse_device_name} with filter: {device_filter}. Error: {e}")
        return []

def change_volume(device, adjust):
    with pulsectl.Pulse("change-volume") as pulse:
        try:
            pulse.volume_change_all_chans(device, adjust * 0.01)
        except Exception as e:
            log.error(f"Error while changing volume on device: {device.name}, adjustment is {adjust}. Error: {e}")

def set_default_device(device_filter: DeviceFilter, pulse_device_name: str):
    try:
        device = get_device(device_filter, pulse_device_name)

        with pulsectl.Pulse("device-setter") as pulse:
            if device_filter == DeviceFilter.SINK.value:
                pulse.sink_default_set(device)
            elif device_filter == DeviceFilter.SOURCE.value:
                pulse.source_default_set(device)
    except Exception as e:
        log.error(f"Error while settings default device: {e}")

def set_volume(device, volume):
    with pulsectl.Pulse("change-volume") as pulse:
        try:
            pulse.volume_set_all_chans(device, volume * 0.01)
        except Exception as e:
            log.error(f"Error while setting volume on device: {device.name}, volume is {volume}. Error: {e}")

def mute(device, state):
    with pulsectl.Pulse("change-volume") as pulse:
        try:
            pulse.mute(device, state)
        except Exception as e:
            log.error(f"Error while muting device: {device.name}, state is {state}. Error: {e}")

def get_standard_device(device_filter: DeviceFilter):
    with pulsectl.Pulse("change-volume") as pulse:
        try:
            if device_filter == DeviceFilter.SINK.value:
                return get_device(device_filter, pulse.server_info().default_sink_name)
            elif device_filter == DeviceFilter.SOURCE.value:
                return get_device(device_filter, pulse.server_info().default_source_name)
            return None
        except Exception as e:
            log.error(f"Error while getting standard device for filter: {str(device_filter)}. Error: {e}")