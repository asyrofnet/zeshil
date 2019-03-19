# Welcome to Kiwari Documentation

## Info

* Rails version: 5.0.2
* Ruby version: 2.4.0
* BASE URL PROD: [http://qisme-engine.herokuapp.com](http://qisme-engine.herokuapp.com)
* BASE URL STAG: [http://qisme-engine-stag.herokuapp.com](http://qisme-engine-stag.herokuapp.com)

-----

## Accessing protected resource

To access protected resources you can send `access_token` via URL parameter or via `Authorization` Header. Both this way will let you to access protected resources:

* Via Header token:

```
GET /api/v1/me/ HTTP/1.1
Host: qisme-engine.herokuapp.com
Authorization: Token token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJ0aW1lc3RhbXAiOiIyMDE2LTEyLTIyIDA3OjU0OjI0ICswMDAwIn0.pomTKwTLZmvzqkXXtJ23l1KKgfLLLueXWK3BQf6RuOY
Cache-Control: no-cache
Postman-Token: cf4cf2da-1857-3e39-5118-b3c76f5c6824

```

* Via URL parameter

[http://qisme-engine.herokuapp.com/api/v1/me?access_token=THE_ACCESS_TOKEN](http://qisme-engine.herokuapp.com/api/v1/me?access_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJ0aW1lc3RhbXAiOiIyMDE2LTEyLTIyIDA3OjU0OjI0ICswMDAwIn0.pomTKwTLZmvzqkXXtJ23l1KKgfLLLueXWK3BQf6RuOY)



## JSON Response

All end-point should return JSON, unless mentioned in specific route documentation. You must see JSON structure in each request before parsing it (in web or mobile client), because in some condition there are some changes (add or remove) JSON object and it is delitace task to update all JSON response example.