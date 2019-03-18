# Installation

## Clone project

Clone project from Github or Bitbucket.

## Set Environment Variable

Please see `application.yml.sample` or simply copy it to `application.yml`

```
$ cp config/application.yml.sample application.yml
```

Make sure you have change all variable value to real value, for example `SENTRY_DSN` must be changed to new sentry dsn url.

## Deployment instructions

After you are set all environment variable, please run:

```
$ rails db:migrate
$ rails db:seed
```

for migrating and seeding initial data.

After that, you need to create your own application via rails console:

```
params = {
  :app_id => 'qisme',
  :app_name => 'Qisme Application',
  :app_description => '',
  :qiscus_sdk_url => 'http://qisme.qiscus.com',
  :qiscus_sdk_secret => 'qisme-123'
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

