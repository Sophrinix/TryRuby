# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_tryruby_session',
  :secret      => '522523ceaba8ca180200d1931128947224663751e03dc442c9cba14d758b80fe166eb4bb2c0b2521a78152e0ae5c3e29237bc826aadb55b8182b1b293af75163'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
