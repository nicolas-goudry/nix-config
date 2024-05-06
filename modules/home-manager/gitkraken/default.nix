{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gitkraken;

  # Don't ask
  defaultProfileId = "d6e5a8ca26e14325a4275fc33b17e16f";

  libx = import ./lib.nix { inherit config lib; };
  optionsDefinition = import ./root.nix { inherit lib pkgs; };
  scripts = import ./scripts { inherit pkgs; };

  appConfig =
    let
      eulaVersion = "8.3.1";

      logLevels = {
        standard = 1;
        extended = 2;
        silly = 3;
      };
    in
    {
      activityLogLevel = logLevels.${cfg.logLevel};
      appDateFormat = cfg.datetime.dateFormat;
      appDateTimeFormat = cfg.datetime.format;
      appDateVerboseFormat = cfg.datetime.dateVerboseFormat;
      appDateWordFormat = cfg.datetime.dateWordFormat;
      appLocale = cfg.datetime.locale;
      cloudPatchesEnabled = cfg.enableCloudPatch;
      cloudPatchTermsAccepted = cfg.enableCloudPatch;
      gitBinaryEnabled = !cfg.git.useBundledGit;
      hideCollapsedWorkspaceTab = cfg.ui.hideWorkspaceTab;
      keepGitConfigInSyncWithProfile = cfg.git.syncConfig;
      onboardingGuideDismissed = cfg.skipTour;

      commits = {
        inherit (cfg.commitGraph) showAll;

        enableCommitsLazyLoading = cfg.commitGraph.lazy;
        maxCommitsInGraph = cfg.commitGraph.max;
      };

      notification = {
        settings = {
          cloud =
            if cfg.notifications.enable then {
              inherit (cfg.notifications)
                feature
                help
                marketing
                system
                ;
            } else { };

          local = {
            showDesktopNotifications = cfg.notifications.enable;
          };

          toastPosition = cfg.notifications.position;
        };
      };

      registration =
        if cfg.acceptEULA then {
          EULA = {
            status = "agree_unverified";
            version = eulaVersion;
          };
        } else { };

      ui = {
        showToolbarLabels = cfg.ui.enableToolbarLabels;
        spellcheck = cfg.spellCheck;
      };

      userMilestones =
        {
          firstAppOpen = true;
          firstProfileCreated = true;
          completedNewUserOnboarding = true;
        } // (if cfg.skipTour then {
          firstAppOpen = true;
          firstRepoOpened = true;
          guideOpened = true;
          startATrial = true;
          connectIntegration = true;
          makeABranch = true;
          createACommit = true;
          pushSomeCode = true;
          createAWorkspace = true;
          createASharedDraft = true;
        } else { });
    };

  buildProfile = profile:
    let
      # TODO: how are profiles id generated???
      id = if profile.isDefault then defaultProfileId else "TODO";
      terminal = libx.fromProfileOrDefault profile [ "tools" "terminal" ];
      defaultTerminal = if terminal.default == "gitkraken" then "Gitkraken Terminal" else "none";
      hasCustomTerminal = terminal.default == "custom";
      selectedTabId = libx.generateFakeUuid "selected-tab";
    in
    {
      ${id} = attrsets.mergeAttrsList [
        {
          inherit (cfg) deleteOrigAfterMerge rememberTabs;
          inherit (cfg.ui) showProjectBreadcrumb;
          inherit defaultTerminal;

          autoFetchInterval = libx.fromProfileOrDefault profile [ "git" "autoFetchInterval" ];
          autoPrune = libx.fromProfileOrDefault profile [ "git" "autoPrune" ];
          autoUpdateSubmodules = libx.fromProfileOrDefault profile [ "git" "autoUpdateSubmodules" ];
          diffTool = libx.fromProfileOrDefault profile [ "tools" "diff" ];
          externalEditor = libx.fromProfileOrDefault profile [ "tools" "editor" ];
          git.selectedGitPath = "$packaged";
          init.defaultBranch = libx.fromProfileOrDefault profile [ "git" "defaultBranch" ];
          mergeTool = libx.fromProfileOrDefault profile [ "tools" "merge" ];
          profileIcon = profile.icon;
          useCustomTerminalCmd = hasCustomTerminal;
          userEmail = libx.fromProfileOrDefault profile [ "user" "email" ];
          userName = libx.fromProfileOrDefault profile [ "user" "name" ];

          cli = {
            cursorStyle = libx.fromProfileOrDefault profile [ "ui" "cli" "cursor" ];
            defaultPath = libx.fromProfileOrDefault profile [ "ui" "cli" "defaultPath" ];
            fontFamily = libx.fromProfileOrDefault profile [ "ui" "cli" "fontFamily" ];
            fontSize = libx.fromProfileOrDefault profile [ "ui" "cli" "fontSize" ];
            lineHeight = libx.fromProfileOrDefault profile [ "ui" "cli" "lineHeight" ];
            position = libx.fromProfileOrDefault profile [ "ui" "cli" "graph" "position" ];
            showAutocompleteSuggestions = libx.fromProfileOrDefault profile [ "ui" "cli" "autocomplete" "enable" ];

            graphPanelVisibilityMode = if libx.fromProfileOrDefault profile [ "ui" "cli" "graph" "enable" ] then "AUTO" else null;
            tabBehavior =
              let
                value = libx.fromProfileOrDefault profile [ "ui" "cli" "autocomplete" "tabBehavior" ];
              in
              if value == "ignore" then "DEFAULT" else toUpper value;
          };

          editor = {
            fontFamily = libx.fromProfileOrDefault profile [ "ui" "editor" "fontFamily" ];
            fontSize = libx.fromProfileOrDefault profile [ "ui" "editor" "fontSize" ];
            lineEnding = libx.fromProfileOrDefault profile [ "ui" "editor" "eol" ];
            tabSize = libx.fromProfileOrDefault profile [ "ui" "editor" "tabSize" ];
            showLineNumbers = libx.fromProfileOrDefault profile [ "ui" "editor" "showLineNumbers" ];
            syntaxHighlighting = libx.fromProfileOrDefault profile [ "ui" "editor" "syntaxHighlighting" ];
            wordWrap = libx.fromProfileOrDefault profile [ "ui" "editor" "wrap" ];
          };

          gpg = {
            commitGpgSign = libx.fromProfileOrDefault profile [ "gpg" "signCommits" ];
            gpgFormat = "openpgp";
            gpgProgram = libx.fromProfileOrDefault profile [ "gpg" "package" ];
            tagForceSignAnnotated = libx.fromProfileOrDefault profile [ "gpg" "signTags" ];
            userSigningKey = libx.fromProfileOrDefault profile [ "gpg" "signingKey" ];
            userSigningKeySsh = null;
          };

          ssh = {
            appVersion = "${cfg.package.version}";
            generated = false;
            publicKey = libx.fromProfileOrDefault profile [ "ssh" "publicKey" ];
            privateKey = libx.fromProfileOrDefault profile [ "ssh" "privateKey" ];
            useLocalAgent = libx.fromProfileOrDefault profile [ "ssh" "useLocalAgent" ];
          };

          tabInfo = {
            inherit selectedTabId;

            permanentTabs = {
              FOCUS_VIEW.closed = cfg.collapsePermanentTabs;
              PROJECTS.closed = cfg.collapsePermanentTabs;
            };

            tabs = [{
              id = selectedTabId;
              type = "NEW";
            }];
          };

          ui = {
            highlightRowsOnRefHover = libx.fromProfileOrDefault profile [ "commitGraph" "highlightRowsOnRefHover" ];
            showGhostRefsOnHover = libx.fromProfileOrDefault profile [ "commitGraph" "showGhostRefsOnHover" ];
            useAuthorInitialsForAvatars = libx.fromProfileOrDefault profile [ "commitGraph" "useAuthorInitials" ];
            useGenericRemoteHostingServiceIconsInRefs = libx.fromProfileOrDefault profile [ "commitGraph" "useGenericRemoteIcon" ];

            theme =
              let
                value = libx.fromProfileOrDefault profile [ "ui" "theme" ];
              in
              if value == "system" then "SYNC_WITH_SYSTEM" else value;

            graphOptions.columns = {
              commitAuthorZone.visible = libx.fromProfileOrDefault profile [ "commitGraph" "showAuthor" ];
              commitDateTimeZone.visible = libx.fromProfileOrDefault profile [ "commitGraph" "showDatetime" ];
              commitShaZone.visible = libx.fromProfileOrDefault profile [ "commitGraph" "showSha" ];
              commitZone.visible = libx.fromProfileOrDefault profile [ "commitGraph" "showTree" ];
              refZone.visible = libx.fromProfileOrDefault profile [ "commitGraph" "showRefs" ];

              commitMessageZone = {
                visible = libx.fromProfileOrDefault profile [ "commitGraph" "showMessage" ];

                descDisplayMode =
                  let
                    value = libx.fromProfileOrDefault profile [ "commitGraph" "showDescription" ];
                  in
                  if value == "hover" then "ON_HOVER" else toUpper value;
              };
            };
          };
        }
        (if (profile.name != null) then {
          profileName = profile.name;
        } else { })
        (if hasCustomTerminal then {
          customTerminalCmd = concatStringsSep " " ([
            "${terminal.package}/bin/${if terminal.bin == null then terminal.package.pname else terminal.bin}"
          ] ++ terminal.extraOptions);
        } else { })
      ];
    };
in
{
  meta.maintainers = [ maintainers.nicolas-goudry ];
  options.programs.gitkraken = optionsDefinition;

  config =
    let
      profiles = attrsets.mergeAttrsList (map buildProfile cfg.profiles);
      defaultProfileCount = length (filter (profile: profile.isDefault) cfg.profiles);
      profilesWithoutNameCount = length (filter (profile: !profile.isDefault && profile.name == null) cfg.profiles);
    in
    mkIf cfg.enable {
      warnings = (builtins.foldl'
        (warnings: profile:
          if (profile.gpg.signCommits || profile.gpg.signTags)
            && (profile.gpg.signingKey == null)
            && (cfg.gpg.signingKey == null)
          then warnings ++ [
            "Profile ${profile.id} has GPG commit/tag signature enabled, but no signing key was defined in the profile nor globally."
          ]
          else warnings) [ ]
        cfg.profiles)
      ++ (if ((cfg.gpg.signCommits || cfg.gpg.signTags) && (cfg.gpg.signingKey == null)) then [
        "GPG commit/tag signature is enabled but no signing key was defined."
      ] else [ ]);

      assertions = [
        {
          assertion = cfg.commitGraph.showAuthor
            || cfg.commitGraph.showDatetime
            || cfg.commitGraph.showMessage
            || cfg.commitGraph.showRefs
            || cfg.commitGraph.showSha
            || cfg.commitGraph.showTree;
          message = "Commit graph cannot be empty";
        }
        {
          assertion = defaultProfileCount == 1;
          message =
            if defaultProfileCount > 1
            then "Only one default profile must be defined"
            else "A default profile is required";
        }
        {
          assertion = profilesWithoutNameCount == 0;
          message = "Non-default profiles must have a name";
        }
      ];

      home.packages = [
        cfg.package
        scripts.decrypt
        scripts.encrypt
        scripts.login
      ];

      home.activation.gitkraken = lib.hm.dag.entryAfter [ "writeBoundary" ] (concatStringsSep "\n" ([
        ''
          log() {
            if test -n "''${VERBOSE:-}" || test -n "''${DRY_RUN:-}"; then
              ${pkgs.coreutils}/bin/echo "''${1:-}"
            fi
          }

          gen_appid() {
            ${pkgs.iproute2}/bin/ip -o link show up | \
            ${pkgs.gnugrep}/bin/grep -v "00:00:00:00:00:00" | \
            ${pkgs.gnugrep}/bin/grep "state UP" | \
            ${pkgs.gawk}/bin/awk '{print $17}' | \
            ${pkgs.coreutils}/bin/tr -d '\n' | \
            ${pkgs.openssl}/bin/openssl sha1 | \
            ${pkgs.coreutils}/bin/cut -d' ' -f2
          }

          detect_git() {
            if test -e ${config.home.profileDirectory}/bin/git; then
              echo ${config.home.profileDirectory}/bin/git
            elif test -e /run/current-system/sw/bin/git; then
              echo /run/current-system/sw/bin/git
            elif which git; then
              echo $(which git)
            else
              echo '$packaged'
            fi
          }

          create_or_merge_json() {
            if test -w $1; then
              file_content="$(${pkgs.coreutils}/bin/cat $1)"
              ${pkgs.jq}/bin/jq -s '.[0] * .[1]' <(${pkgs.coreutils}/bin/echo ''${file_content:-{}) <(${pkgs.coreutils}/bin/echo $2) > $1
            elif ! test -f $1; then
              ${pkgs.jq}/bin/jq '.' <(${pkgs.coreutils}/bin/echo $2) > $1
            else
              2&> ${pkgs.coreutils}/bin/echo "File is not writable"
              exit 1
            fi
          }

          config_dir="$HOME/.gitkraken"

          log "Config directory: '$config_dir'"
          log "Write app configuration file"

          if test -n "''${DRY_RUN:-}"; then
            log "dry-run: create configuration directory at $config_dir"
            log "dry-run: patch or create configuration file at $config_dir/config with following data:"
            log "$(${pkgs.jq}/bin/jq '.' <(${pkgs.coreutils}/bin/echo ${strings.escapeNixString (builtins.toJSON appConfig)}))"
          else
            ${pkgs.coreutils}/bin/mkdir -p $config_dir
            create_or_merge_json $config_dir/config ${strings.escapeNixString (builtins.toJSON appConfig)}
          fi

          if test "$(${pkgs.jq}/bin/jq -r '.appId' $config_dir/config)" == "null"; then
            log "Generate new app id"

            appid="$(gen_appid)"

            if test -n "''${DRY_RUN:-}"; then
              log "dry-run: save generated appid ('$appid') to configuration file at $config_dir/config"
            else
              create_or_merge_json $config_dir/config "{\"appId\":\"$appid\"}"
            fi
          else
            log "Keep current app id"
          fi
        ''
      ] ++ mapAttrsToList
        (
          id: profile: ''
            profile_dir="$config_dir/profiles/${id}"

            log "Write profile configuration file for profile ${if profile ? profileName then profile.profileName else "default"} (${id})"

            if test -n "''${DRY_RUN:-}"; then
              log "dry-run: create profile directory at $profile_dir"
              log "dry-run: path or create profile configuration file at $profile_dir/profile with following data:"
              log "$(${pkgs.jq}/bin/jq '.' <(${pkgs.coreutils}/bin/echo ${strings.escapeNixString (builtins.toJSON profile)}))"
            else
              ${pkgs.coreutils}/bin/mkdir -p $profile_dir
              create_or_merge_json $profile_dir/profile ${strings.escapeNixString (builtins.toJSON profile)}
            fi

            if test "${boolToString appConfig.gitBinaryEnabled}" == "true"; then
              log "Git binary is enabled, try to detect git path"

              detected_git="$(detect_git)"

              if test "$detected_git" == '$packaged'; then
                log "Failed to detect git package, falling back to bundled git"
              fi

              log "Update profile configuration with detected git path"

              if test -n "''${DRY_RUN:-}"; then
                log "dry-run: save detected git path ('$detected_git') to profile configuration file at $profile_dir/profile"
              else
                create_or_merge_json $profile_dir/profile "{\"git\":{\"selectedGitPath\":\"$detected_git\"}}"
              fi
            fi
          ''
        )
        profiles
      ++ (if (length cfg.ui.extraThemes > 0) then [
        ''
          themes_dir="$config_dir/themes"

          log "Install extra themes"

          if test -n "''${DRY_RUN:-}"; then
            log "dry-run: create themes directory at $themes_dir"
          else
            mkdir -p $themes_dir
          fi

          for theme in ${concatStringsSep " " cfg.ui.extraThemes}; do
            destination="$themes_dir/$(basename $theme)"

            if test -n "''${DRY_RUN:-}"; then
              log "dry-run: install theme '$theme' at $destination"
            else
              ${pkgs.coreutils}/bin/ln -sf $theme $destination
            fi
          done
        ''
      ] else [ ])
      ++ [
        ''
          ${pkgs.coreutils}/bin/echo "To login to your GitKraken account, run 'gk-login'."
        ''
      ]));
    };
}
