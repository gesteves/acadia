# About

_Acadia_ is static Middleman-based website I'm using as my personal site at [gesteves.com](http://gesteves.com). It pulls data from several social networks and services I use and puts it in the `data/` folder to populate the site. It's hosted on an Amazon S3 bucket backed by CloudFront for extra speediness.

## Useful rake tasks

`$ bundle exec rake import`: Runs the scripts to import external data and populates the `data/` and `source/images/` folders with it.

`$ bundle exec rake build`: Imports the external data and builds the site.

`$ bundle exec rake preview`: Imports the external data and starts the Middleman preview server.

`$ bundle exec rake publish:full`: Imports the external data, builds the site, and syncs it to S3.

`$ bundle exec rake publish:build_only`: Builds the site and syncs it to S3 without re-importing all the external data.