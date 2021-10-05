FROM ruby:2.7.1
RUN gem install bundler

WORKDIR /app

COPY Gemfile /app/
COPY Gemfile.lock /app/
RUN bundle config --local set path 'vendor/bundle'
RUN bundle install
COPY . /app/

# CMD ["ls -al; pwd"]
CMD ["bundle", "exec", "ruby", "atcoder_tl.rb"]
