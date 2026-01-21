# Deploying

If you would like to build and deploy OpenGamepadUI to a remote system,
the `Makefile` can help make this easier.

First, in the OpenGamepadUI project directory, create a `settings.mk`
file with the SSH user and host you want to deploy to:


```make title="settings.mk"
SSH_USER = gamer
SSH_HOST = 192.168.0.26
SYSEXT_ID = chimeraos
SYSEXT_VERSION_ID = 44
```

Replace the values in this file with the appropriate ones for your
remote device.

You can now build and deploy OpenGamepadUI using one of the following
methods:

```bash
make deploy-update
make deploy-ext
```
