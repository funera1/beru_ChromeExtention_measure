ARG        PYTHON_TAG=3
FROM       python:${PYTHON_TAG} AS base

# Add some metadata
LABEL      app.name="InterPlanetary Wayback (IPWB)" \
           app.description="A distributed and persistent archive replay system using IPFS" \
           app.license="MIT License" \
           app.license.url="https://github.com/oduwsdl/ipwb/blob/master/LICENSE" \
           app.repo.url="https://github.com/oduwsdl/ipwb" \
           app.authors="Mat Kelly <@machawk1> and Sawood Alam <@ibnesayeed>"

# Add a custom entrypoint script
COPY       entrypoint.sh /usr/local/bin/
RUN        chmod a+x /usr/local/bin/entrypoint.sh

# Enable unbuffered STDOUT logging
ENV        PYTHONUNBUFFERED=1

# Create folders for WARC, CDXJ and IPFS stores
RUN        mkdir -p /data/ipfs \
        && mkdir -p /data/warc \
        && mkdir -p /data/cdxj \

# Download and install IPFS
ENV        IPFS_PATH=/data/ipfs
ARG        IPFS_VERSION=v0.18.0
RUN        cd /tmp \
            && wget -q https://dist.ipfs.io/kubo/${IPFS_VERSION}/kubo_${IPFS_VERSION}_linux-amd64.tar.gz \
            && tar xvfz kubo*.tar.gz \
            && mv kubo/ipfs /usr/local/bin/ipfs \
            && rm -rf kubo* \
            && ipfs init \
            && ipfs bootstrap rm --all \
            && ipfs bootstrap add /ip4/153.120.91.229/tcp/4001/p2p/12D3KooWRdUnAXeCoW9FUnchhQsiNfvffwMYqS2nGdraUfvuqzoy
            
COPY        swarm.key /root/.ipfs/


# Make necessary changes to prepare the environment for IPWB
RUN        apt update && apt install -y locales \
            && rm -rf /var/lib/apt/lists/* \
            && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
            && locale-gen

# Install basic requirements
WORKDIR    /ipwb
COPY       requirements.txt ./
RUN        pip install -r requirements.txt


# Standard JS lint
FROM       node
WORKDIR    /ipwb
COPY       . ./
ARG        SKIPTEST=false
RUN        $SKIPTEST || npm install -g standard
RUN        $SKIPTEST || standard

# Final production image
FROM base

# Install IPWB from the source code
COPY       . ./
RUN        python setup.py install

# Run ipfs daemon in background
# Wait for the daemon to be ready
# Runs provided command
ENTRYPOINT ["entrypoint.sh"]