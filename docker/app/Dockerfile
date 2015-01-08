# Standard Rack app container.
FROM ruby:2.2.0

WORKDIR /app

# Installing:
# 1. Curl
# 2. Rake, Bundler - pretty much anything in ruby will need it
# 3. Thin, Rack    - base to any Rack app
#
RUN apt-get -y install curl &&\
    bash -l -c 'gem install rake thin rack bundler'

EXPOSE 80

CMD bundle exec thin -R config.ru -p 80 start
