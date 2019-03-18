# README

* Ruby version 2.4.1

* System dependencies
  * Bundler version 1.14.6
  * Rails 5.1.1

* Configuration, please make sure you have set this ENVIRONMENT KEY, for detailed key, please refer to application.yml.sample file.
  * `JWT_KEY`
  * `CLOUDINARY_API_KEY`
  * `CLOUDINARY_API_SECRET`
  * `CLOUDINARY_CLOUD_NAME`
  * `NEXMO_API_KEY`
  * `NEXMO_API_SECRET`
  * `TWILIO_SID_KEY`
  * `TWILIO_TOKEN_KEY`
  * `EMAIL_SENDER`
  * `MAILGUN_API_KEY`
  * `MAILGUN_DOMAIN`
  * `SENTRY_DSN`
  * `PAPERTRAIL_API_TOKEN`
  * `NEW_RELIC_LICENSE_KEY`
  * `REDIS_URL`
  * `REDIS_CACHE`
  * `SUPER_ADMIN_USERNAME`
  * `SUPER_ADMIN_PASSWORD`
  * `IS_PUSHKIT_DEV`
  * `IS_APNS_DEV`
  * `SIDEKIQ_USERNAME`
  * `SIDEKIQ_PASSWORD`

* Database creation, you can either set via `DATABASE_URL` string or
  * `APP_DATABASE_HOST`
  * `APP_DATABASE_PORT`
  * `APP_DATABASE_USERNAME`
  * `APP_DATABASE_PASSWORD`
  * `APP_DATABASE_NAME`
  * `APP_DATABASE_TEST_NAME`


* Database initialization
  `rails db:migrate`

* Services
  * Job queue using sidekiq please run `bundle exec sidekiq` in another service


## Deployment instructions

After you are set all environment variable, please run:

```
rails db:seed
```

for seeding initialising data.

After that, you need to create your own application via rails console:

```
params = {
  :app_id => 'qisme',
  :app_name => 'Qisme Application',
  :app_description => '',
  :qiscus_sdk_url => 'http://qisme.qiscus.com',
  :qiscus_sdk_secret => 'qisme-123',
  :sms_server => 'VERIFY',
  :secret_key => '',
  :fcm_key => ''
}

Application.create(params)
```

Then if you want to register new user, you can post it via Postman or using CURL:

```
curl -X POST -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" -F "user[phone_number]=+6281233541554" -F "user[app_id]=kiwari-stag" "{URL}/api/v1/auth/"
```

If you want to set a registered user as an admin, you can do via dashboard admin page or via console:

```
u = User.find_by(phone_number: "+6281233541554")
UserRole.create(user: u, role: Role.admin)
```

## Running Using Docker

### Using Docker

```bash
$ docker build -t qisme_engine .
$ docker run -p 8000:3000 qisme_engine
```

Then access in `localhost:8000`. It may not run properly since you have not configure all needed keys. Set to real value using `-e` argument in docker and it should running properly.


### Using docker compose

Or use docker compose for easy configuration. In staging mode, just copy `docker-compose.yml.example` to `docker-compose.yml`

```bash
$ cp docker-compose.yml.example docker-compose.yml

```

Then run:

```bash
$ docker-compose up
```

Access it in `localhost:8000`


### Connect to postgresql on docker host
Run this sh file [postgres-docker-config.sh](https://gist.github.com/therusetiawan/e829600e740c0f2509ba494cfe01ba77)

### Connect to redis on docker host
Bind your docker0 ip address into redis config file (/etc/redis/redis.conf)
```bash
bind 172.17.0.1
```

## Building Documentation

There are 2 tools to build docs. First [MKDOCS](http://www.mkdocs.org/) to build static page via markdown file, second is [APIDOCJS](http://apidocjs.com/) to build Inline Documentation for RESTful web APIs.

Installing two of them is easy, but they need this prerequisites:

For MKDOCS, it needs:

* Python 2.7 or later
* PIP 1.5.2 or later

For APIDOCJS, needs:

* NodeJS v6 or later
* NPM v3 or later

Then install mkdocs and apidocjs:

```
$ sudo pip install mkdocs
$ sudo npm install --global apidoc
```

After installation completed, you can build new api doc using following command from rails root directory:

```
$ apidoc -i app/controllers -o docs/apidoc
```

Please keep in mind that you must generate apidoc in `docs/apidoc` directory.

If you change or add new file inside `docs/docs` directory (for instance you adding some note in there), you must re-generate your docs to html using mkdocs. First, change your directory to `docs`, then run `mkdocs build`, here is the full command:

```
$ cd docs
$ mkdocs build
$ cd ..
```

And now your documentation is up-to-date, don't forget to commit and push it into repo.

