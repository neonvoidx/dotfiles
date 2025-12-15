# Import StreamController modules
from src.backend.PluginManager.PluginBase import PluginBase
from src.backend.PluginManager.ActionHolder import ActionHolder
from src.backend.DeckManagement.InputIdentifier import Input
from src.backend.PluginManager.ActionInputSupport import ActionInputSupport

# Import actions
from .actions.SetOutput.SetOutput import SetOutput
from .actions.ToggleOutput.ToggleOutput import ToggleOutput

class AudioSwitcher(PluginBase):
    def __init__(self):
        super().__init__()

        self.lm = self.locale_manager

        ## Register actions
        self.set_output_holder = ActionHolder(
            plugin_base = self,
            action_base = SetOutput,
            action_id_suffix = "SetOutput", # Change this to your own plugin id
            action_name = self.lm.get("actions.set-output.name"),
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.set_output_holder)

        self.toggle_output_holder = ActionHolder(
            plugin_base = self,
            action_base = ToggleOutput,
            action_id_suffix = "ToggleOutput", # Change this to your own plugin id
            action_name = self.lm.get("actions.toggle-output.name"),
            action_support={
                Input.Key: ActionInputSupport.SUPPORTED,
                Input.Dial: ActionInputSupport.SUPPORTED,
                Input.Touchscreen: ActionInputSupport.UNTESTED
            }
        )
        self.add_action_holder(self.toggle_output_holder)

        # Register plugin
        self.register(
            plugin_name = self.lm.get("plugin.name"),
            github_repo = "https://github.com/StreamController/AudioSwitcher",
            plugin_version = "1.0.0",
            app_version = "1.4.5-beta"
        )