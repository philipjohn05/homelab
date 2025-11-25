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
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl \
    && chmod +x kubectl && mv kubectl /usr/local/bin/

# Install kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/ \
    && chmod +x /usr/local/bin/kustomize

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Flux CLI
RUN FLUX_VERSION=2.7.4 && \
    curl -LO "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" && \
    tar xzf flux_${FLUX_VERSION}_linux_amd64.tar.gz && \
    mv flux /usr/local/bin/ && \
    chmod +x /usr/local/bin/flux && \
    rm flux_${FLUX_VERSION}_linux_amd64.tar.gz

# Create agent user
RUN useradd -m -s /bin/bash agent \
    && usermod -aG sudo agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy pre-downloaded agent package
WORKDIR /azp
COPY vsts-agent-linux-x64-*.tar.gz /azp/agent.tar.gz
RUN tar xzf agent.tar.gz \
    && rm agent.tar.gz \
    && ./bin/installdependencies.sh

# Copy start script and set ownership
COPY start.sh /azp/
RUN chmod +x /azp/start.sh \
    && chown -R agent:agent /azp

# Verify installations
RUN echo "Verifying installations:" \
    && docker --version \
    && kubectl version --client \
    && kustomize version \
    && flux --version \
    && helm version

# Switch to agent user
USER agent

CMD ["/azp/start.sh"]
