FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    libicu70 \
    docker.io \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

# Create agent user
RUN useradd -m -s /bin/bash agent \
    && usermod -aG sudo agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy pre-downloaded agent package
WORKDIR /azp
COPY vsts-agent-linux-x64-3.236.1.tar.gz /azp/agent.tar.gz
RUN tar xzf agent.tar.gz \
    && rm agent.tar.gz \
    && ./bin/installdependencies.sh

# Copy start script and set ownership
COPY start.sh /azp/
RUN chmod +x /azp/start.sh \
    && chown -R agent:agent /azp

# Switch to agent user
USER agent

CMD ["/azp/start.sh"]
