ARG RUNTIME_VERSION=latest
ARG SDK_VERSION=latest

FROM mcr.microsoft.com/dotnet/sdk:${SDK_VERSION} AS tools-install

RUN dotnet tool install --tool-path /dotnetcore-tools dotnet-sos
RUN dotnet tool install --tool-path /dotnetcore-tools dotnet-trace
RUN dotnet tool install --tool-path /dotnetcore-tools dotnet-dump
RUN dotnet tool install --tool-path /dotnetcore-tools dotnet-counters

FROM mcr.microsoft.com/dotnet/aspnet:${RUNTIME_VERSION} as base

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    file \
    lldb \
    curl \
    gnupg2 \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=tools-install /dotnetcore-tools /opt/dotnetcore-tools
ENV PATH="/opt/dotnetcore-tools:${PATH}"
RUN dotnet-sos install

EXPOSE 80

# https://github.com/dotnet/runtime/issues/98797
COPY openssl.cnf /etc/ssl/openssl.cnf

FROM base as chrome-deps

RUN curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && echo "deb http://httpredir.debian.org/debian stable main contrib non-free" >> /etc/apt/sources.list \
    && echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends $(apt-cache depends google-chrome-stable | grep Depends | sed -e "s/.*ends:\ //" -e 's/<[^>]*>//') libxss1 libxtst6 libxshmfence1 \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
    ttf-mscorefonts-installer fonts-paratype \
    && rm -rf /var/lib/apt/lists/*
