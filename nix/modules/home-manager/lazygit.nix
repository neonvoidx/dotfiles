{ config, pkgs, lib, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      keybinding = {
        files = {
          commitChangesWithEditor = "<disabled>";
        };
      };
      git = {
        skipHookPrefix = "WIP";
      };
      customCommands = [
        {
          key = "C";
          description = "commit with commitizen";
          context = "files";
          command = ''git commit -m "{{ .Form.Type }}{{if .Form.Scopes}}({{ .Form.Scopes }}){{end}}: {{ .Form.Description }}" {{- if .Form.LongDescription }} -m "{{ .Form.LongDescription }}" {{- end }} {{- if .Form.BreakingChange }} -m "BREAKING CHANGE: {{ .Form.BreakingChange }}" {{- end }}'';
          prompts = [
            {
              type = "menu";
              title = "Select the type of change you are committing.";
              key = "Type";
              options = [
                { name = "Feature"; description = "a new feature"; value = "feat"; }
                { name = "Fix"; description = "a bug fix"; value = "fix"; }
                { name = "Documentation"; description = "Documentation only changes"; value = "docs"; }
                { name = "Styles"; description = "Changes that do not affect the meaning of the code"; value = "style"; }
                { name = "Code Refactoring"; description = "A code change that neither fixes a bug nor adds a feature"; value = "refactor"; }
                { name = "Performance Improvements"; description = "A code change that improves performance"; value = "perf"; }
                { name = "Tests"; description = "Adding missing tests or correcting existing tests"; value = "test"; }
                { name = "Builds"; description = "Changes that affect the build system or external dependencies"; value = "build"; }
                { name = "Continuous Integration"; description = "Changes to CI configuration files and scripts"; value = "ci"; }
                { name = "Chores"; description = "Other changes that don't modify src or test files"; value = "chore"; }
                { name = "Reverts"; description = "Reverts a previous commit"; value = "revert"; }
              ];
            }
            { type = "input"; title = "Enter the scope(s) of this change."; key = "Scopes"; }
            { type = "input"; title = "Enter the short description of the change."; key = "Description"; }
            { type = "input"; title = "Enter a more detailed description (optional)."; key = "LongDescription"; }
            { type = "input"; title = "Describe the breaking change, if any (leave empty if none)."; key = "BreakingChange"; }
            { type = "confirm"; title = "Is the commit message correct?"; body = "{{ .Form.Type }}{{if .Form.Scopes}}({{ .Form.Scopes }}){{end}}: {{ .Form.Description }}"; }
          ];
        }
      ];
    };
  };
}
