# SPDX-License-Identifier: MPL-2.0
#
# Multi-stage build for Open Integration Engine
#
# Build:  docker build -t oie .
# Run:    docker run -p 8080:8080 -p 8443:8443 oie

# ---------------------------------------------------------------------------
# Stage 1: Build
# ---------------------------------------------------------------------------
FROM azul/zulu-openjdk:17 AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends ant && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN cd server && ant -f mirth-build.xml -DdisableSigning=true -DdisableTests=true

# ---------------------------------------------------------------------------
# Stage 2: Runtime
# ---------------------------------------------------------------------------
FROM azul/zulu-openjdk:17-jre

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash && \
    rm -rf /var/lib/apt/lists/*

ENV OIE_HOME=/opt/oie

COPY --from=build /src/server/setup ${OIE_HOME}

# Ensure startup script is executable
RUN chmod +x ${OIE_HOME}/oieserver

# Persistent data: embedded DB, keystore, config overrides, logs
VOLUME ["${OIE_HOME}/appdata", "${OIE_HOME}/logs"]

EXPOSE 8080 8443

WORKDIR ${OIE_HOME}

ENTRYPOINT ["./oieserver"]
