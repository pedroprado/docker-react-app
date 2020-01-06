#fase 1: fase de build
FROM node:alpine as builder
WORKDIR '/app'
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

#fase 2: fase de run (usando um segundo FROM, o docker automaticamente descarta a imagem anterior)
FROM nginx
EXPOSE 80
COPY --from=builder /app/build /usr/share/ngnix/html


