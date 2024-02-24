phpRedisAdmin
=============

phpRedisAdmin is a simple web interface to manage [Redis](http://redis.io/)
databases. It is released under the
[Creative Commons Attribution 3.0 license](http://creativecommons.org/licenses/by/3.0/).
This code is being developed and maintained by [Erik Dubbelboer](https://github.com/ErikDubbelboer/).

You can send comments, patches, questions
[here on github](https://github.com/ErikDubbelboer/phpRedisAdmin/issues)
or to erik@dubbelboer.com.


Example
=======

You can find an example database at
[http://dubbelboer.com/phpRedisAdmin/](http://dubbelboer.com/phpRedisAdmin/)


Installing/Configuring
======================

To install [phpRedisAdmin](https://packagist.org/packages/erik-dubbelboer/php-redis-admin) through [composer](http://getcomposer.org/) you need to execute the following commands:

```
curl -s http://getcomposer.org/installer | php
php composer.phar create-project -s dev erik-dubbelboer/php-redis-admin path/to/install
```

You may also want to copy includes/config.sample.inc.php to includes/config.inc.php
and edit it with your specific redis configuration.

Instead of using composer, you can also do a manual install using:

```
git clone https://github.com/ErikDubbelboer/phpRedisAdmin.git
cd phpRedisAdmin
git clone https://github.com/nrk/predis.git vendor
```

Docker Image
============
A public [phpRedisAdmin Docker image](https://hub.docker.com/r/erikdubbelboer/phpredisadmin/) is available on Docker Hub [automatically built](https://docs.docker.com/docker-hub/builds/) from latest source.
The file ```includes/config.environment.inc.php``` is used as the configuration file to allow environment variables to be used as configuration values.
Example:
```
docker run --rm -it -e REDIS_1_HOST=myredis.host -e REDIS_1_NAME=MyRedis -p 80:80 erikdubbelboer/phpredisadmin
```
Also, a Docker Compose manifest with a stack for testing and development is provided. Just issue ```docker-compose up --build``` to start it and browse to http://localhost. See ```docker-compose.yml``` file for configuration details.

Environment variables summary
====

* ``REDIS_1_HOST`` - define host of the Redis server
* ``REDIS_1_NAME`` - define name of the Redis server
* ``REDIS_1_PORT`` - define port of the Redis server
* ``REDIS_1_AUTH`` - define password of the Redis server
* ``ADMIN_USER`` - define username for user-facing Basic Auth
* ``ADMIN_PASS`` - define password for user-facing Basic Auth

TODO
====

* Encoding support for editing
* Javascript sorting of tables
* Better error handling
* Move or Copy key to different server
* Importing JSON
* JSON export with seperate objects based on your seperator


Credits
=======

Icons by [http://p.yusukekamiyamane.com/](http://p.yusukekamiyamane.com/) ([https://github.com/yusukekamiyamane/fugue-icons/tree/master/icons-shadowless](https://github.com/yusukekamiyamane/fugue-icons/tree/master/icons-shadowless))

Favicon from [https://github.com/antirez/redis-io/blob/master/public/images/favicon.png](https://github.com/antirez/redis-io/blob/master/public/images/favicon.png)
