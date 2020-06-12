FROM alpine:latest

LABEL "maintainer"="Scott Ng <thuongnht@gmail.com>"
LABEL "repository"="https://github.com/cross-the-world/ssh-scp-ssh-pipelines"
LABEL "version"="1.0.0"

LABEL "com.github.actions.name"="ssh-scp-ssh-pipelines"
LABEL "com.github.actions.description"="Pipelines: ssh -> scp -> ssh"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="gray-dark"

RUN apk update && \
  apk add ca-certificates && \
  apk add --no-cache openssh-client openssl openssh sshpass && \
  apk add --no-cache --upgrade bash openssh sshpass && \
  rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY test /opt/test
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]