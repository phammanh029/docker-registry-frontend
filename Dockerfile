FROM node:10.16.0 as builder
WORKDIR /source
ADD . .
RUN npm install
RUN npm audit fix
RUN node_modules/bower/bin/bower install --allow-root
RUN node_modules/grunt-cli/bin/grunt build --allow-root

FROM nginx:1.17.5-alpine
WORKDIR /usr/share/nginx/html
ENV DOCKER_REGISTRY_HOST hub.i2r.work
ENV DOCKER_REGISTRY_PORT 443
ENV DOCKER_REGISTRY_SCHEME https
COPY --from=builder /source/dist/* ./
COPY nginx/conf.d/ /etc/nginx/conf.d/
RUN echo "{\"host\": \"$DOCKER_REGISTRY_HOST\", \"port\": $DOCKER_REGISTRY_PORT }" > registry-host.json
RUN echo "{\"browseOnly\": false, \"defaultRepositoriesPerPage\": 50 , \"defaultTagsPerPage\":50}}" > app-mode.json
RUN echo "{\"git\": {\"sha1\":\"foo\", \"ref\": \"bar\"}}" > app-version.json
RUN sed -i 's/${DOCKER_REGISTRY_SCHEME}/'"${DOCKER_REGISTRY_SCHEME}"'/' /etc/nginx/conf.d/registry-frontend.conf
RUN sed -i 's/${DOCKER_REGISTRY_HOST}/'"${DOCKER_REGISTRY_HOST}"'/' /etc/nginx/conf.d/registry-frontend.conf
RUN sed -i 's/${DOCKER_REGISTRY_PORT}/'"${DOCKER_REGISTRY_PORT}"'/' /etc/nginx/conf.d/registry-frontend.conf
# COPY app/app-model.json /var/www/html/
# COPY app/app-version.json /var/www/html/
EXPOSE 80 443
# CMD [ "executable" ]