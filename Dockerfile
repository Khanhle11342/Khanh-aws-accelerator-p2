FROM nginx:1.29-alpine

COPY app/ /usr/share/nginx/html/

EXPOSE 80
