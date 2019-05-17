# Mollusk Inventory

Thrash the inventory wave...

## Getting Started:

### Installing Locally

1. **Run `$ bundle install` and resolve any errors**  

2. **Configure your DB:**
  * Create a new ROLE in postgres for 'grits'
    * `$ psql -h localhost`
    * `$ CREATE ROLE mollusk WITH CREATEDB LOGIN PASSWORD 'inventory';`

3. **Create your databases:**
  * `$ bundle exec rake db:create`

4. **Import the latest postgres backup from Heroku (You'll need access to Heroku):**
   * `$ heroku pg:backups:capture`
   * `$ heroku pg:backups:download`
   * `$ pg_restore --verbose --clean --no-acl --no-owner -h localhost -U mollusk -d inventory_app-dev latest.dump`
   * `$ rm latest.dump`
    
5. **Migrate your databases:**
  * `$ bundle exec rake db:migrate`

6. **Start up the app locally:**
  * `$ bundle exec rails s`

7. **Enjoy at:** http://0.0.0.0:3000

### Refreshing DB with production data

1. **Drop your databases:**
  * `$ bundle exec rake db:drop`

2. **Complete Steps 3 through 5 under "Installing Locally" above**



