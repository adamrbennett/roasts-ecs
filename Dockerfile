FROM node:alpine

ENV APP_PORT "80"

EXPOSE 80

RUN mkdir -p /usr/src/api

COPY . /usr/src/api

WORKDIR /usr/src/api

RUN npm install --production

CMD ["node", "index.js"]
