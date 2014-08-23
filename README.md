# About

_Acadia_ is a static Middleman-based website I’m using as my personal site at [gesteves.com](http://gesteves.com). It pulls data from several social networks and services I use and puts it in the `data/` folder to populate the site. It's hosted on an Amazon S3 bucket backed by Amazon CloudFront for extra speediness.

## Useful tasks

* `$ bundle exec rake import`: Runs the tasks to import external data and populate the `data/` and `source/images/` folders with it. It can also import individual sources, such as `rake import:twitter`. The available sources are `twitter`, `instagram`, `photoblog`, `links`, `github`, `lastfm`, `goodreads`, and `untappd`.
* `$ bundle exec rake build`: Runs the import tasks and builds the site.
* `$ bundle exec rake preview`: Runs the import tasks and starts the Middleman preview server.
* `$ bundle exec rake publish:full`: Runs the import tasks, builds the site, and syncs it to S3.
* `$ bundle exec rake publish:build_only`: Builds the site and syncs it to S3 without running the import tasks.