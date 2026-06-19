FROM nginx:1.29-alpine

RUN apk upgrade --no-cache

COPY app/ /usr/share/nginx/html/

EXPOSE 80
