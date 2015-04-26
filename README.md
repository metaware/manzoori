# Pravangi [![Build Status](https://travis-ci.org/metaware/pravangi.svg?branch=master)](https://travis-ci.org/metaware/pravangi) [![Code Climate](https://codeclimate.com/github/metaware/pravangi/badges/gpa.svg)](https://codeclimate.com/github/metaware/pravangi)

ਪ੍ਰਵਾਨਗੀ (pravangi) : Let's you add an approval process on top of your models/objects. Assume you have an object which is in an `approved` state, you want any subsequent changes to this model to go into a review queue and have someone review these changes until they are actually committed to the object.

## Installation

### Rails 3 & 4

1. Add pravangi to your `Gemfile`.

    `gem 'pravangi'`

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
```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality.

**You get extra attention, if your PR includes specs/tests.**

1. Fork or clone the project.
2. Create your feature branch (`$ git checkout -b my-new-feature`)
3. Install the dependencies by doing: `$ bundle install` in the project directory.
4. Add your bug fixes or new feature code.
    - New features should include new specs/tests. 
    - Bug fixes should ideally include exposing specs/tests.
5. Commit your changes (`$ git commit -am 'Add some feature'`)
6. Push to the branch (`$ git push origin my-new-feature`)
7. Open your Pull Request!


## License
Copyright (c) 2013 [Jasdeep Singh](http://jasdeep.ca) ([Metaware Labs Inc](http://metawarelabs.com/))

Licensed under the MIT license.