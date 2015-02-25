# About

This is a static Middleman-based website I’m using as my personal site at [gesteves.com](http://gesteves.com). An import script pulls data from several social networks and services I use and puts it in the `data/` and `source/images` folders to populate the site. A cron job running on Heroku periodically re-generates the site using [Middleman](http://middlemanapp.com/) to keep it up to date and pushes it to an Amazon S3 bucket, where it gets served from Amazon CloudFront for extra speediness.

## Useful tasks

* `$ bundle exec rake import`: Runs the tasks to import external data and populate the `data/` and `source/images/` folders with it. It can also import individual sources, such as `rake import:twitter`. The available sources are `twitter`, `instagram`, `photoblog`, `links`, `github`, `rdio`, `goodreads`, and `untappd`.
* `$ bundle exec rake publish`: Runs the import tasks, builds the site, and syncs it to S3.

&copy; 2014 Guillermo Esteves. Feel free to take a look and use this for your own projects, but please don’t straight up republish my website verbatim.
