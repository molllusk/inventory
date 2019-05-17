Dump db from heroku to your local dev environment:

1. `heroku pg:backups:capture`
2. `heroku pg:backups:download`
3. `bundle exec rake db:create`
4. `pg_restore --verbose --clean --no-acl --no-owner -h localhost -U mollusk -d inventory_app-dev latest.dump`
5. `bundle exec rake db:migrate`

Make sure to `bundle exec rake db:drop` if you have a previously existing db.
