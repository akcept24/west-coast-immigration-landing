FROM nginx:alpine

COPY index.html ru/index.html styles.css script.js i18n.js /usr/share/nginx/html/
COPY ru/index.html /usr/share/nginx/html/ru/index.html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
