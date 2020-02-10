FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG GITHUB_TAGNAME
ARG GITHUB_NAME
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="gustavo8000br"

# environment settings
ENV HOME="/config"

RUN \
 apt-get update && \
 apt-get install -y \
	git \
	jq \
	nano \
	net-tools \
	sudo && \
 echo "**** install code-server ****" && \
 if [ -z ${GITHUB_TAGNAME+x} ]; then \
	GITHUB_TAGNAME=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases" \
	| jq -r 'first(.[] | select(.prerelease == false)) | .tag_name'); \
 fi && \
 if [ -z ${GITHUB_NAME+x} ]; then \
	GITHUB_TAGNAME=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases" \
	| jq -r 'first(.[] | select(.prerelease == false)) | .name'); \
 fi && \
 CODE_URL=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/tags/${CODE_RELEASE}" \
	| jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64")) | .browser_download_url') && \
 curl -o \
	/tmp/code.tar.gz -L \
	"${CODE_URL}" && \
 tar xzf /tmp/code.tar.gz -C \
	/usr/bin/ --strip-components=1 \
	--wildcards code-server*/code-server && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443
