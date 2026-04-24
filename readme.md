# Watchman Docker ARM
![Kathy Geiss is watching](mascot.gif)
Builds of Facebook's [Watchman](https://github.com/facebook/watchman) utility for use in Docker workflows. Provides a native ARM build for Apple Silicon and other, lesser non-AMD64 platforms.

## Getting Started
Use this Watchman container as the base for the workload it enables: copy the binaries and the libraries, and you're off.

```Dockerfile
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Binaries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM phyllisstein/watchman:v2026.03.02.00 AS watchman

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ App ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:24.04 AS app

COPY --from=watchman /usr/local/bin/* /usr/local/bin/
COPY --from=watchman /usr/local/lib/* /usr/local/lib/
```

It's also necessary to create the state directory.

```Dockerfile
RUN mkdir -p /usr/local/var/run/watchman && chmod a+w /usr/local/var/run/watchman
```
