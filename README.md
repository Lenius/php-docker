docker build --no-cache -f Dockerfile . -t pdflib
docker images | grep pdflib

docker run -it pdflib php -m
docker run -it --entrypoint sh -p 80:8080 pdflib
docker run -it --entrypoint sh pdflib

docker-compose -f docker-compose.yml up -d
docker-compose -f docker-compose.yml down

docker service rm $(docker service ls -q) && docker rm -f $(docker ps -a -q)