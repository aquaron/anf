# ANF Base Image

Nginx build on Alpine with FastCGI.

## `runme.sh`

Runs `init` if no configurations found.
This script accepts these commands:

| Command   | Description                                      |
| --------- | ------------------------------------------------ |
| init      | initialize directories if they're empty          |
| daemon    | run in non-detached mode                         |
| start     | start `nginx` server                             |
| stop      | stop `nginx` server                              |
| quit      | gracefully stop `nginx` server                   |
| reload    | reloads `nginx` configurations                   |
| reopen    | reopens `nginx` log files                        |
| kill      | `killall nginx`                                  |
| test      | check `nginx`'s configuration                    |

### `init`

Initializes the server with all the necessary configurations and certificate.
Example:

    runme.sh init 

### `daemon`

Put `nginx` in the foreground so that it wouldn't stop when the container detatches.

### `start`, `stop`, `quit`, `kill`

These are convenience commands when you're inside the running container use for
starting and stopping.

### `reload`, `reopen`, `test`

When you change configurations, reload and test it.

## Execute `runme.sh` using `docker`

You can execute the script from `docker` commandline by using this format:

    docker run -it --rm -p <port>:80 \
        -v <datadir>:/usr/share/nginx \
        -v <logdir>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf aquaron/anf \
            <command> <args>

For example, if you'd want to initialize the server:

    docker run -it --rm -p <port>:80 \
        -v <datadir>:/usr/share/nginx \
        -v <logdir>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf aquaron/anf \
            init

To reload the configuration after you've made some changes:

    docker exec -it anf runme.sh reload


-------------------------------------------------------------------------------

# Usage

## Test Server

Just run the container without mapping to any local directories will start you off with
a clean test configuration pointing to a test page with a link showing that FastCGI is working.

If your host is `example.com` and port is `9090` here's how to run a simple test:

    docker run -p 9090:80 -h example.com --name anf -d aquaron/anf

Point your browser to `example.com:9090` you should see a simple message with a link.
Click on that to see the FastCGI in action.

## Debugging

You can enter the container and use `runme.sh` to control `nginx`.
To run the `nginx` server manually:

    docker run -it -p 9090:80 --name anf --entrypoint=/bin/sh aquaron/anf

Once inside the container:

    runme.sh test


## Start Server

    docker run -p <port>:80 \
        -h <hostname> \
        -v <datadir>:/usr/share/nginx \
        -v <logdir>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf-server \
        -d aquaron/anf

### `<port>`

Maps the internal port `80` to localhost's port. 
If you're using `anf` with [`anle`](https://github.com/aquaron/anle) 
use port `999x` (starting with `x` is `1`) to make setup easier.

### `<datadir>`, `<logdir>`, `<etcdir>`

You need to map the local directories to container's to get access
to the files inside the containers:

| Directory | Description
| --------- | -----------
| <datadir> | Maps to `/usr/share/nginx` where the HTML (data) files are
| <logdir>  | Maps to `/var/log/nginx` stores log files
| <etcdir>  | Maps to `/etc/nginx` configurations

### `--name`

Gives this container a name for ease of access.
If you want to attach to the running container:

    docker exec -it anf sh -l

### `-d`

Detatch the container and run in the background.

## Control Container

### Using `systemd`

Use the provided `install-systemd.sh` to install the autostart script.
Start and stop container by issuing:

    systemctl start docker-anf.service
    systemctl stop docker-anf.service

### Manual Controls

    docker create -p <port>:80 \
        -h <hostname> \
        -v <datadir>:/usr/share/nginx \
        -v <logdir>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf-server \
            aquaron/anf

    docker start anf-server

