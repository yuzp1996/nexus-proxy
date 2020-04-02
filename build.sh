docker build -t buildjar:build . -f Dockerfile.build

docker container create --name extract buildjar:build
docker container cp extract:/src/build/libs/useless-nexus-proxy-2.3.0.jar /nexus/nexus-proxy/src/build/libs/useless-nexus-proxy-2.3.0.jar
docker container rm -f extract