FROM nginx:stable-alpine
COPY build/ /web/data/
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
