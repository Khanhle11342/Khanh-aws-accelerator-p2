FROM nginx:1.25-alpine

COPY app/ /usr/share/nginx/html/

EXPOSE 80
