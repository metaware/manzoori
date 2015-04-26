# Pravangi

ਪ੍ਰਵਾਨਗੀ (pravangi) : Let's you add an approval process on top of your models/objects. Assume you have an object which is in an `approved` state, you want any subsequent changes to this model to go into a review queue and have someone review these changes until they are actually committed to the object.

## Installation

### Rails 3 & 4

1. Add pravangi to your `Gemfile`.

    `gem 'pravangi'

2. Generate a migration which will add a `pending_approvals` table to your database.

    `bundle exec rails generate pravangi:install`

3. Run the migration.

    `bundle exec rake db:migrate`

4. Add `requires_approval` to the models you want to track.

## API Summary

When you declare `requires_approval` in your model, you get these methods:

```ruby
class Article < ActiveRecord::Base
  requires_approval   # you can pass various options here
end

# check if this object requires any approval?
article.pending_approval?


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
