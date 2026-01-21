# Installation

OpenGamepadUI offers a variety of installation methods. It can be installed locally in your user directory or system-wide. Use one of the following installation guides to install OpenGamepadUI on your system.


=== "ArchLinux"

    If you are using ArchLinux, you can install OpenGamepadUI from the AUR.
    
    You can install it using your favorite AUR helper:
    
    ```bash
    yay -S opengamepadui-bin
    ```
    
    If you wish to install the OpenGamepadUI session, you can also install
    the `opengamepadui-session-git` package:
    
    ```bash
    yay -S opengamepadui-session-git
    ```
    
    **Pre-built binary**
    
    - <https://aur.archlinux.org/packages/opengamepadui-bin>
    
    **Source package**
    
    - <https://aur.archlinux.org/packages/opengamepadui-git>
    - <https://aur.archlinux.org/packages/opengamepadui-session-git>

=== "SteamOS / Steam Deck"

    **Desktop Installer**
    
    The easiest way to install OpenGamepadUI on SteamOS is to use the
    desktop installer. Access this page from your SteamOS device and
    download the installer below. Note that you may have to open the
    installer from your file manager if your browser cannot run files:
    
    [Download](https://github.com/ShadowBlip/OpenGamepadUI/releases/latest/download/opengamepadui_deck_installer.desktop)
    
    **FAQ**
    
    **Can I still use Steam's interface with OpenGamepadUI installed?**
    
    Yes, when running on SteamOS, OpenGamepadUI will give you the option to
    switch back to Steam's gaming interface whenever you\'d like.
    
    **Does OpenGamepadUI require me to unlock the read-only filesystem?**
    
    No, OpenGamepadUI is installed as a
    systemd extension which gets merged over the root filesystem using overlayfs. No system
    files are modified and OpenGamepadUI can be removed any time.
    
    **Does OpenGamepadUI work on Windows, Mac, or other operating systems?**
    
    No, OpenGamepadUI only works on Linux-based operating systems. It relies
    heavily on software that is only available on Linux. There are no plans
    to support any other operating systems.
    
    **Does using OpenGamepadUI void my Steam Deck warranty?**
    
    OpenGamepadUI does not modify the root filesystem, so there shouldn't
    be any reason for your warranty to be denied. However, OpenGamepadUI is
    provided without warranty and you are responsible for the security of
    your device.

=== "NixOS"

    OpenGamepadUI can be installed by modifying your `configuration.nix` and 
    including the opengamepadui program:

    ```nix title="configuration.nix"
    programs.opengamepadui = {
      enable = true;
      inputplumber.enable = true;
      powerstation.enable = true;
    };
    ```

    If you want to also include the enable the dedicated session:

    ```nix title="configuration.nix"
    programs.opengamepadui = {
      enable = true;
      inputplumber.enable = true;
      powerstation.enable = true;
      gamescopeSession.enable = true;
    };

    services.displayManager = {
      defaultSession = "opengamepadui";
    }
    ```

=== "Systemd Extension"

    If you are using an OS that has an immutable filesystem (such as SteamOS
    or ChimeraOS), OpenGamepadUI can be installed as a [systemd
    extension](https://www.freedesktop.org/software/systemd/man/systemd-sysext.html).
    When extensions are enabled (aka "merged") those files will appear on
    the root filesystem using overlayfs.
    
    **Binary Installation**

    Use the following steps to install OpenGamepadUI as a systemd extension:
    
    - Download the latest version of OpenGamepadUI from the
      [releases](https://github.com/ShadowBlip/OpenGamepadUI/releases) page.
      The systemd extension should be called `opengamepadui.raw`.
    - Create a directory to store the extension in your home directory:
    
    ``` bash
    mkdir -p ~/.var/lib/extensions
    ```
    
    - Create a symlink to the extensions directory:
    
    ``` bash
    sudo ln -s $HOME/.var/lib/extensions /var/lib/extensions
    ```
    
    - Move `opengamepadui.raw` to the extensions directory
    
    ``` bash
    mv ~/Downloads/opengamepadui.raw ~/.var/lib/extensions
    ```
    
    - Enable and start systemd-sysext:
    
    ``` bash
    sudo systemctl enable systemd-sysext
    sudo systemctl start systemd-sysext
    ```
    
    - Verify that the extension is loaded:
    
    ``` bash
    systemd-sysext status
    ```
    
    If the extension doesn't load, you may need to force refresh:
    
    ``` bash
    sudo systemd-sysext refresh --force
    ```

    **Source Installation**

    Use the following steps to build and install OpenGamepadUI as a systemd extension
    from source:

    - Ensure that you have the build dependencies from the [developer
      guide](../../contributing/building_from_source/#build-requirements)
      installed.
    - Clone the OpenGamepadUI repository:
    
    ``` bash
    git clone https://github.com/ShadowBlip/OpenGamepadUI.git
    ```
    
    - Build the project with `make`
    
    ``` bash
    cd OpenGamepadUI
    make build
    ```
 
    - Install and enable the systemd extension:

    ``` bash
    make enable-ext
    make install-ext
    ```

=== "Binary"

    OpenGamepadUI offers pre-built binaries that can be installed on any
    modern Linux distribution. There are 2 different ways you can install
    OpenGamepadUI:
    
    1.  System-wide (recommended)
    2.  Locally in your home directory
    
    **System-wide installation**
    
    Installing OpenGamepadUI system-wide provides the most funtionality. Use
    the following steps to install OpenGamepadUI:
    
    - Ensure you have the runtime dependencies installed
    - Download the latest version of OpenGamepadUI from the
      [releases](https://github.com/ShadowBlip/OpenGamepadUI/releases) page.
      The package archive should be called `opengamepadui.tar.gz`.
    - Extract the archive to a folder
    
    ``` bash
    tar xvfz opengamepadui.tar.gz
    ```
    
    - Install OpenGamepadUI
    
    ``` bash
    sudo make install PREFIX=/usr
    ```
    
    **Local user installation**
    
    OpenGamepadUI can be installed completely in your home directory, with
    some limitations. Use the following steps to install OpenGamepadUI in
    your home directory:
    
    - Ensure you have the runtime dependencies installed
    - Download the latest version of OpenGamepadUI from the
      [releases](https://github.com/ShadowBlip/OpenGamepadUI/releases) page.
      The package archive should be called `opengamepadui.tar.gz`.
    - Extract the archive to a folder
    
    ``` bash
    tar xvfz opengamepadui.tar.gz
    ```
    
    - Install OpenGamepadUI (default: `~/.local`)
    
    ``` bash
    cd opengamepadui
    make install
    ```

=== "Source"

    OpenGamepadUI can be built and installed on any modern Linux
    distribution. There are 2 different ways you can install OpenGamepadUI:
    
    1.  System-wide (recommended)
    2.  Locally in your home directory
    
    **Build**
    
    - Ensure that you have the build dependencies from the [developer
      guide](../../contributing/building_from_source/#build-requirements)
      installed.
    - Clone the OpenGamepadUI repository locally
    
    ``` bash
    git clone https://github.com/ShadowBlip/OpenGamepadUI.git
    ```
    
    - Build the project with `make`
    
    ``` bash
    cd OpenGamepadUI
    make build
    ```
    
    **System-wide installation**
    
    If you wish to install OpenGamepadUI system-wide, you can do the
    following:
    
    ``` bash
    sudo make install PREFIX=/usr
    ```
    
    **Local user installation**
    
    Use the following to install OpenGamepadUI to your local user directory
    (default: `~/.local`):
    
    ``` bash
    make install
    ```

## Usage

Once OpenGamepadUI is installed, it should show up as an application you can launch from your desktop environment.

Alternatively you can launch it from the command line with:

```bash
opengamepadui
```

or, if installed in the local user directory:

```bash
~/.local/bin/opengamepadui
```

