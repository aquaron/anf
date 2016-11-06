# ANF Base Image

Nginx build on Alpine with FastCGI.

# Run

### Test Server

If your host is `example.com` and port is `9090` here's how to run a simple test:

    docker run -p 9090:8080 -h example.com --name anf-server -d aquaron/anf

Point your browser to `example.com:9090` you should see a simple message with a link.
Click on that to see the CGI in action.

### Enter the Container

To run the Nginx server manually:

    docker run -it -p 9090:8080 --name anf-server --entrypoint=/bin/sh aquaron/anf

Once inside the container:

    /usr/bin/nginx-fcgi &


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
        -d aquaron/anf

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
        aquaron/anf

    docker start anf-server


