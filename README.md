# json-config

This is a simple library for reading application configuration in json format. It was inspired by the way the javascript config lilibrary works:
  - read default.json and an environment-specific config file
  - do template substitution from environment variables
  - merge the values such that environment-specific config overrides default config

For example

default.json
```
{
    "postgres": { 
        "host": "{{POSTGRES_HOST}}",
        "port": {{POSTGRES_PORT || 5432}},
        "user": "{{POSTGRES_USER}}",
        "password": "{{POSTGRES_PASSWORD}}",
        "database": "{{POSTGRES_DATABASE}}" 
    },
    "redis": {
        "host": "{{REDIS_HOST}}",
        "port": {{REDIS_PORT || 6379}}
    },
    "apiserver": {
        "port": {{API_SERVER_PORT || 80}},
        "jwtKey": "{{JWT_KEY}}"
    },
    "smtp": {
        "host": "{{SMTP_HOST}}",
        "port": {{SMTP_PORT || 25}}
    }
}
```

localhost.json
```
{
    "postgres": {
        "host": "localhost",
        "port": 15432,
        "user": "postgres",
        "password": "password",
        "database": "main" 
    },
    "redis": {
        "host": "localhost",
        "port": 16379
    },
    "apiserver": {
        "port": 8081,
        "jwtkey": "localhost key"
    },
    "smtp": {
        "host": "localhost",
        "port": 11025
    }
}
```


