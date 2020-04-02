docker build -t buildjar:build . -f Dockerfile.build

docker container create --name extract buildjar:build
docker container cp extract:/src/build/libs/nexus-proxy-2.3.0.jar /nexus/nexus-proxy/
docker container rm -f extract