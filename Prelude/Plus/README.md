Prelude Plus
============
> These are files that contain functions that are not part of the core Prelude module, for one reason or another. Use `help <name> -Examples` to see examples for any of these module names.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [`Enable-Remoting`](#enable-remoting)
- [`Get-DefaultBrowser`](#get-defaultbrowser)
- [`Get-GithubOAuthToken`](#get-githuboauthtoken)
- [`Get-Screenshot`](#get-screenshot)
- [`Invoke-ListenForWord`](#invoke-listenforword)
- [`Invoke-ListenTo`](#invoke-listento)
- [`Invoke-NewDirectoryAndEnter`](#invoke-newdirectoryandenter)
- [`Invoke-Normalize`](#invoke-normalize)
- [`Invoke-RemoteCommand`](#invoke-remotecommand)
- [`Measure-Readability`](#measure-readability)
- [`Open-Session`](#open-session)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

`Enable-Remoting`
-----------------
- **Description**: This function enables...remoting.  Specifically, it makes a network private, enables remoting via `Enable-PSRemoting`, and updates trusted hosts.
- **Note**: Requires **Administrator** privileges.

`Get-DefaultBrowser`
--------------------
- **Description**: Returns string name of default browser - Firefox, IE, Chrome, Opera, or Unknown.

`Get-GithubOAuthToken`
----------------------
- **Description**: Enables one to easily obtain an OAuth token for connecting to the GitHub.com API.
- **Note**: Requires [GitHub OAuth application](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app) Client ID.

`Get-Screenshot`
----------------
> This function triggers Windows security since it is similar to [PowerShell Empire code](https://github.com/EmpireProject/Empire/blob/08cbd274bef78243d7a8ed6443b8364acd1fc48b/data/module_source/collection/Get-Screenshot.ps1). As a standalone cmdlet, if `Get-Screenshot` is blocked by Windows security, the impace will be isolated from the rest of the Prelude module.

`Invoke-ListenForWord`
----------------------
- **Description**: Uses Windows speech recognition and listens for a certain word.  Can be used to trigger subsequent scripts.
- **Aliases**: `listenFor`

`Invoke-ListenTo`
-----------------
- **Description**: Basically a wrapper for Register-EngineEvent.
- **Aliases**: `on`, `listenTo`


`Invoke-NewDirectoryAndEnter`
-----------------------------
- **Description**: PowerShell version of [Oh-My-Zsh's `take` command](https://github.com/ohmyzsh/ohmyzsh/wiki/Cheatsheet#commands).
- **Aliases**: `take`

`Invoke-Normalize`
------------------
- **Description**: Helper to make string values more normal.

`Invoke-RemoteCommand`
----------------------
- **Description**: Wrapper for invoking commands on remote machines.
- **Aliases**: `irc`


`Measure-Readability`
---------------------
- **Description**: Measure readability of input text.  See `help Measure-Readability` for details.

`Open-Session`
--------------
- **Description**: Create interactive session with remote machine.

