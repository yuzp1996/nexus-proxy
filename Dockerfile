# -- run
FROM alpine:3.10

# Install java runtime
RUN apk add --no-cache --update openjdk8-jre && \
    rm -rf /tmp/* /var/cache/apk/*

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/jre
ENV ALLOWED_USER_AGENTS_ON_ROOT_REGEX "GoogleHC"
ENV AUTH_CACHE_TTL "300"
ENV BIND_PORT "8080"
ENV CLIENT_ID "REPLACE_ME"
ENV CLIENT_SECRET "REPLACE_ME"
ENV CLOUD_IAM_AUTH_ENABLED "false"
ENV JWT_REQUIRES_MEMBERSHIP_VERIFICATION "true"
ENV KEYSTORE_PATH "keystore.jceks"
ENV KEYSTORE_PASS "safe#passw0rd!"
ENV NEXUS_DOCKER_HOST "containers.example.com"
ENV NEXUS_HTTP_HOST "nexus.example.com"
ENV NEXUS_RUT_HEADER "X-Forwarded-User"
ENV ORGANIZATION_ID "REPLACE_ME"
ENV REDIRECT_URL "https://nexus.example.com/oauth/callback"
ENV SESSION_TTL "1440000"
ENV TLS_CERT_PK12_PATH "cert.pk12"
ENV TLS_CERT_PK12_PASS "safe#passw0rd!"
ENV TLS_ENABLED "false"
ENV UPSTREAM_DOCKER_PORT "5003"
ENV UPSTREAM_HOST "localhost"
ENV UPSTREAM_HTTP_PORT "8081"


COPY nexus-proxy-2.3.0.jar /nexus-proxy.jar

EXPOSE 8080
EXPOSE 8443

CMD ["-jar", "/nexus-proxy.jar"]

ENTRYPOINT ["java"]
