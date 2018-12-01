FROM ruby:2.5.3-alpine
ENV LANG C.UTF-8
ENV TERM xterm-256color
WORKDIR /opt
COPY . /opt/
RUN \
  apk add --no-cache build-base libstdc++ && \
  bundle install --deployment && \
  apk del --no-cache build-base
CMD ["bundle", "exec", "ruby", "web.rb"]
EXPOSE 8080
