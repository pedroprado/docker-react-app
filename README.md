DOCKER TUTORIAL

**Terminology**
What is Docker?
It is a platform (ecosystem) that has multiple programs (tools, like Docker CLI and Docker Server) for creating and running CONTAINERS.

What is a Container?
Its a linux process, a running program that has it OWN ISOLATED HARDWARE RESOURSES (memory, hard drive, networking).

What is a Image?
It is a file with instructions to create a program (container).

1.BASIC COMMANDS

  -docker run <image_name> :  docker create <image_name> + docker start <conteiner_id>
 	docker create = cria um container a partir da imagem image_name 
	docker start = inicia o processo primário do conteiner

  -docker run <image_name> <command>:
cria um contêiner a partir de image_name e start com o comando command

  -docker exec -it <container_id>  <command_inside_container>:
Comando para executar um comando command_inside_container dentro do contêiner ligado container_id.

  -docker exec -it <container_id>  sh
Comando para abrir o terminal dentro do contêiner:

  -docker ps: mostra todos os containers que estão em pé
  -docker ps --all: mostra todos os containers que já foram criados na máquina
  -docker system prune: remove todos os containers que estão com status Exited


  -docker run -it image_name <override_command>
Inicia um contêiner (a partir de image_name) executando um comando dentro dele override_command

  -docker stop <container_id>: manda um sinal para parar o contêiner
  -docker kill <container_id>: para na hora o contêiner

  -docker rm <container_id> : remove um contêiner com status Exited
  -docker rmi <image_id> remove uma imagem (o contêiner que usa aquela imagem precisa ter sido removido antes!)

  -docker logs <container_id>: obtain the container logs

DOCKERFILE

“docker build .” : 
Constrói uma imagem do docker, usando um Dockerfile

“docker run -p <port_outside_container>:<port_inside_container> <image_name>” :
Mapeia a porta a porta dentro do contêiner para uma porta fora dele.
Exemplo:docker run -p 8000:8002 pedroprado/say-hello

2.DOCKER-COMPOSE

**Docker compose is also use for facilitate starting multiple containers with appropriate arguments, avoiding long “docker run commands”.

Docker compose is a way of connecting docker containers (processes). It creates a network among the containers started with it.
Structure:
	“Here is what we want you to do”
		“Create image of redis-server”
		“Create image of node-app”

Example: docker-compose.yml
```yaml
version: '3'
services:
  redis-server: 
    image: 'redis'
  node-app:
    build: .
    ports:
      - "8002:9000"
```


Docker compose start commands:
	-docker-compose up: docker compose will run the images listed inside de compose file
	-docker-compose up --build: docker compose will rebuild the images 
Stopping docker containers in docker-compose:
	-docker-compose down

Run docker containers in the BACKGROUND: Add the flag -d
-docker run -d  <image_name> 
-docker-compose up -d
Status  of docker-compose containers:
-docker-compose ps: it needs to be done in the same directory of the docker-compose.yml file; 

***The diferente services inside the docker-compose are like “Different domains”. Inside the docker-compose, you can access any services by referring its name.

HOW TO DEAL WITH CONTAINERS THAT CRASH?

Exit Codes:
0: exited and everything is OK
1,2,3: exited because something went wrong

Restart Policies: (restart)
“no’: never restart (default) (‘no’ must be a string)
always: always try to restart
on-failure: try to restart when a failure occurred
unless-stopped: always restart, unless we (developers) say not to

Example of “restart = always”
```yaml
version: '3'
services:
  redis-server: 
    image: 'redis'
  node-app:
    restart: always
    build: .
    ports:
      - "8002:9000"
```

Use of restart policies:
on-failure => (workers nodes: example, a container that do a calculation and stops)
always => (web apps)

NGINX

HTTP server for Web apps;
Nginx = consumes more memory and it is “event-based”
Apache = consumes less memory and it is “process-based”


3.DOCKERFILE DEV x PROD

a.DEV:
	This Dockerfile may contain “Volumes”;
	Volumes:
essentially a way of map the directories inside the container to the directories outside the containers;
volumes can be used for developing purposes, where we want the changes in our application to be reflected immediately inside the container. Thus, the container must reflect the changes in the application outside it.

Volumes with docker run command:
     docker run -p <port>:<port> -v /app/modules -v $(pwd):/app <image_id>

** -v /app/modules says: “this /app/modules folder inside the container should not be mapped to any folder outside the container”
** -v $(pwd): /app  says: “map the /app folder inside the container to the current work directory (pwd) outside the container

Volumes with Docker compose:
```yaml
version: '3'
services:
 webapp:
   build:
     context: .
     dockerfile: Dockerfile.dev
   ports:
    - "4000:3000"
   volumes:
     - /app/node_modules
     - .:/app
```
 


b.PROD Dockerfile
	This Dockerfile may not contain “volumes”.
	It needs to have a “build” phase, where the docker builds a production version of the application.
	It needs to use an appropriate production server, like NGINX.

```
#phase 1: build phase
FROM node:alpine as builder
WORKDIR '/app'
COPY package.json ./
RUN npm install
COPY ./ ./
RUN npm run build    //builds the production version
 
#phase 2: run/start phase (using a second FROM, docker automatically discards the previous image)
FROM nginx
#expose is necessary for Elasticbeanstalk to do the mapping of the container the server elasticbeanstalk
EXPOSE 80
#we copy all the production version build previously to the appropriate folder inside the nginx server container   
COPY --from=builder /app/build /usr/share/ngnix/html
```


4.SINGLE CONTAINER APPLICATION
CONTINUOUS INTEGRATION FLOW



For the continuous integration to work we need a CI server. In this case we use Travis CI. Any time we push code to the master branch in our git repository, Travis CI is called for execute the steps listed above.
For Travis CI to work responsively to our “pushes” in the git repository, we have to add on configuration file (.travis.yml) in the root directory of our project.

```yaml
sudo: required
#os services são programas que o travis CI precisa ter para executar seu processo de integração contínua
services:
    - docker
 
#essa tag diz o que deve ocorrer antes da fase de testes do processo de CI
before_install:
    - docker build -f Dockerfile.dev -t pedroprado/react-app .
 
#tag que diz os comandos a serem executados na fase de testes
script:
    # originalmente, o npm run test espera uma entrada para executar os testes
    # -e CI=true força a execução apenas uma vez
    # e saída do "npm run test"
    - docker run -e CI=true pedroprado/react-app npm run test
 
deploy:
    provider: elasticbeanstalk
    region: "us-east-2"
    app: "docker-react"
    env: "DockerReact-env"
    #bucket = é o nome do disco onde está o app
    bucket_name: "elasticbeanstalk-us-east-2-702988789672"
    #default= é o mesmo nome que o "app"
    bucket_path: "docker-react"
    on:
        branch: master
    access_key_id: $AWS_ACCESS_KEY
    secret_access_key:
        secure: "$AWS_SECRET_KEY"
```

Important: the Test phase occurs with the Development version of our application. NO TESTS should be done over the Production Version!


