# Running Zee with Docker

When you create a new app, two Docker files will be created for you:
`Dockerfile` and `.dockerignore`. These files are used to build a Docker image
that will run your app.

To build the image, you do something like `docker build -t myapp .`. Make sure
your Dockerfile's Ruby version matches whatever is set on your `.ruby-version`
file or equivalent. Same thing for the Node version.

To run the image, you can create a `.env.production` file with your apps'
secrets on your deployment environment and run the following command:

```bash
docker run \
  -p 3000:8080 \
  --env-file .env.production \
  --volume myapp-storage:/app/storage \
  --volume myapp-public:/app/public \
  --name myapp \
  myapp
```

By default, the app is exposed on port 8080, so it works with [Fly.io][flyio]
without having to tweak the Dockerfile.

The volumes that are being defined will hold file uploads and your public assets
respectively. This allows you to use a webserver like [Caddy][caddy] to serve
static files. If you don't want to use a webserver, you can force the app to
serve them with `ZEE_SERVE_STATIC_FILES=1`.

Your `.env.production` could look like this:

```bash
DATABASE_URL=postgres://fnando@host.docker.internal/myapp
ZEE_KEYRING=/secrets/myapp.key
```

> [!NOTE]
>
> For production environments, managing application secrets with [Docker
> Swarm][docker-swarm] provides better security through its encrypted secrets
> management system. However, Swarm adds additional complexity since it's a full
> container orchestration solution.

## Running migrations

To run migrations, you can use the following command:

```console
$ docker exec myapp bin/zee db migrate --verbose
```

In fact, you can run any command using `docker exec`. For instance, here's how
you can open the console:

```console
$ docker exec -it blog bin/zee console
irb(prod)>
```

## Serving static files

Zee doesn't have something like [Thruster][thruster], although you can use it if
you want, but that defeats the purpose of not using anything related to Rails.
Instead, you'll have a Dockerfile configured to use [Caddy][caddy] to proxy
requests to your app and serve static files.

The configuration lives at `Caddyfile`, and it's actually super simple:

```caddy
{
  admin off
}

:8080 {
  header {
    -Server
  }

  root * /app/public
  file_server
  handle_errors {
    header {
      -Server
    }

    reverse_proxy 127.0.0.1:3000
  }
}
```

You can tweak it in any way you want. By default, it exposes port 8080 and
proxies requests to port 3000.

For simple setups, you may want to handle [Let's Encrypt][lets-encrypt]
certificates and expose your container publicly.

1. Replace `:8080` with your actual host name, for instance `example.com`.
2. Change the Dockerfile to expose ports 80 and 443.
3. Run your container mapping the ports 80 and 443 with
   `docker run -p 80:80 -p 443:443`.

Once your DNS resolves to the server running your app, a new certificate will be
generated. You may want to define a volume to store your certificates. See
[Caddy's `storage` configuration][caddy-storage].

[docker-swarm]: https://docs.docker.com/engine/swarm
[docker-secrets]: https://docs.docker.com/engine/swarm/secrets/
[flyio]: https://fly.io
[caddy]: https://caddyserver.com
[lets-encrypt]: https://letsencrypt.org
[caddy-storage]: https://caddyserver.com/docs/caddyfile/options#storage
