FROM node:17-alpine

ENV COMMIT_SHA=ab9267fa3f88623a7031f3996fcc76a9fe115111

RUN apk update && apk add --no-cache git

RUN git clone https://github.com/Blockstream/esplora.git && \
  cd esplora && \
  git checkout ${COMMIT_SHA} && \
  npm install --unsafe-perm

WORKDIR /esplora

ENV CORS_ALLOW=*

EXPOSE 5000

CMD [ "npm", "run", "dev-server" ]