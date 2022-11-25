# Plugins

OpenGamepad UI uses a plugin system to extend functionality.

## Writing Plugins

First, clone the OpenGamepad UI project to its own folder:

```bash
git clone https://github.com/ShadowBlip/opengamepad-ui.git
```

Next, create a separate folder that will contain your plugin project:

```bash
mkdir my-plugin
```

Change directory to the project folder and create the plugin folder structure:

```bash
cd my-plugin
git init
```

Now create a JSON file with the same name as your plugin that will contain the
metadata that describes your plugin:

```bash
$EDITOR plugin.json
```

```json
{
  "plugin.name": "My Plugin",
  "plugin.version": "1.0.0",
  "plugin.min-api-version": "1.0.0",
  "plugin.link": "https://github.com/ShadowBlip/opengamepad-ui",
  "plugin.source": "https://github.com/ShadowBlip/opengamepad-ui",
  "plugin.description": "An example plugin",
  "store.tags": [],
  "store.images": [],
  "author.name": "William Edwards",
  "author.email": "shadowapex@gmail.com",
  "entrypoint": "plugin.gd"
}
```

Next, create a symlink to your plugin inside the OpenGamepad UI directory:

```bash
cd ../opengamepad-ui/plugins
ln -s ../../my-plugin ./
```

You can now run `make plugins` inside the OpenGamepad UI project directory to
build your plugin.
