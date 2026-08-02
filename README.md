# Laragon - The Dev Environment for Entrepreneurs

## What is Laragon?

Laragon is a portable, isolated, fast & powerful universal development environment for PHP, Node.js, Python. It is fast, lightweight, easy-to-use and easy-to-extend.

Laragon is great for building and managing modern web applications. It is focused on performance  - designed around stability, simplicity, flexibility and freedom.

Laragon is very lightweight and will stay as lean as possible. The core binary itself is less than 6MB and uses around 4MB - 10MB RAM when running.

Laragon doesn't use Windows services. It has its own `service orchestration` which manages services asynchronously and non-blocking so you'll find things run fast & smoothly with Laragon.

Enjoy!

> Starting with Laragon 7.x, a license is required to use Laragon. For more details, visit <https://laragon.lemonsqueezy.com/>.

## Features

- **Pretty URLs**
  Use `app.test` instead of `localhost/app`.
- **Portable**
  You can move Laragon folder around (to another disks, to another laptops, sync to Cloud,...) without any worries.
- **Isolated**
  Laragon has an isolated environment with your OS - it will keep your system clean.
- **Easy Operation**
  Unlike others which pre-config for you, Laragon **`auto-configs`** all the complicated things. That way you can add another versions of PHP, Python, Ruby, Java, Go, Apache, Nginx, MySQL, PostgreSQL, MongoDB,... effortlessly.
- **Modern & Powerful**
  Laragon comes with a modern architecture which is suitable to build modern web apps. You can work with both Apache & Nginx as they are fully-managed.
  Also, Laragon makes things a lot easier:
  - Wanna have a Wordpress CMS? Just 1 click.
  - Wanna show your local project to customers? Just 1 click.
  - Wanna enable/disable a PHP extension? Just 1 click.



*Laragon is trully isolated & portable. However, you may need to use the installer as it will detect and install missing run-time components that are required to run C++ applications built using Visual Studio such as `PHP, Apache` for you.*


## How fast?
Laragon starts instantly. You can set Laragon autorun when Windows starts. When running, Laragon uses just a little amount of your RAM.
Here is the GUI of Laragon:
![0_1513173700919_01-dashboard.png](https://i.imgur.com/0py3k1X.png)

## How easy?
- Laragon is very easy to install & upgrade. Just download the latest version and click `Next, Next, Next...`
- Laragon is very easy to use. Most of the time it will work out-of-the-box without the need to touch any configuration files.
- Laragon is very easy to extend. You can add other services to your current stack by just extracting them to `Laragon's bin` folder.

## PostgreSQL

PostgreSQL is managed by Laragon the same way MySQL is - it runs alongside MySQL on its own port, so you can use both at once.

**Install:** `Menu > Tools > Quick add > postgresql-18.4`

To install it by hand instead, download the binaries zip from
[EnterpriseDB](https://www.enterprisedb.com/download-postgresql-binaries) and unpack it so that
`postgres.exe` lands here:

```
laragon\bin\postgresql\postgresql-18.4\bin\postgres.exe
```

The folder name must start with `postgresql-` - that is the prefix Laragon uses to build the version list.
The EDB zip unpacks to a folder called `pgsql`, so rename it.

**Use it:**

| What | Where |
| --- | --- |
| Enable the service | `Menu > Preferences > Services & Ports` (default port `5432`) |
| Switch version | `Menu > PostgreSQL > Version` |
| Data directory | `Menu > PostgreSQL > DataDir` (defaults to `laragon\data`) |
| Config / log | `Menu > PostgreSQL > postgresql.conf` / `postgresql.log` |
| GUI clients | `Menu > PostgreSQL >` HeidiSQL, DBeaver, or pgAdmin 4 |

The first start runs `initdb`, then creates the `postgres` superuser and a `postgres` database. There is no
password by default, matching Laragon's MySQL behaviour.

### Admin panel

phpMyAdmin only speaks MySQL, so PostgreSQL gets **Adminer** at <http://localhost/adminer> - the aliases in
`etc\apache2\alias\adminer.conf` and `etc\nginx\alias\adminer.conf` are already wired up. It opens with the
PostgreSQL driver and `127.0.0.1:5432` pre-selected. MySQL still works from the same page via the driver
list, or keep using `/phpmyadmin`.

```
etc\apps\adminer\
    index.php     # Laragon wrapper: PostgreSQL defaults
    adminer.php   # Adminer 5.5.1 itself
```

**One-time setup - give the postgres role a password:**

```
psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

Unlike phpMyAdmin with MySQL's blank-password `root`, Adminer refuses to connect to an account with an empty
password, and Laragon's `initdb` creates `postgres` without one. Setting a password is the only way in - it
also saves you trouble later, since pgAdmin, DBeaver and Laravel all expect one.

For a desktop client instead, **pgAdmin 4** ships inside the PostgreSQL package at
`bin\postgresql\postgresql-18.4\pgAdmin 4\runtime\pgAdmin4.exe` - reachable from `Menu > PostgreSQL > pgAdmin 4`.

**PHP:** to connect from PHP, enable `pdo_pgsql` and `pgsql` in `Menu > PHP > Extensions`. For Laravel, set
`DB_CONNECTION=pgsql` and `DB_PORT=5432` in `.env`.
