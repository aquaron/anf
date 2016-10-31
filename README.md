# ANF Base Image

Nginx build on Alpine with FastCGI.

# Run

### Start Server

You need to map 3 local paths to the container's. 
`<datadir>` is the `rootdir` of the server.
`<logdir>` is where the server log will be written and `<etcdir>` stores the conf.
`<port>` is local port to foward to the server's `8080` port.
`--name` directive gives the container the name for ease of access, in this example,
we give it `anf-server` as the name of the container.
`-d` tells `docker` to detatch the container.

    docker run -p <port>:8080 \
        -h <hostname> \
        -v <datadir>:/usr/share/nginx \
        -v <logidr>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf-server \
        -d anf

### Stop Server

    docker stop anf-server

### Remove the Container

    docker rm anf-server

### Remove Image

    docker rmi anf
    

### Create Container & Run

    docker create -p <port>:8080 \
        -h <hostname> \
        -v <datadir>:/usr/share/nginx \
        -v <logidr>:/var/log/nginx \
        -v <etcdir>:/etc/nginx \
        --name anf-server \
        anf

    docker start anf-server
