# will_publish

Provides publishing ability to your ActiveRecord models

NOTE: This is a work-in-progress, and is not yet ready for actual use

## Installation

Add ```gem 'will_publish'``` to your Gemfile.

## Usage

```ruby
class Guide
  has_many :steps
  has_and_belongs_to_many :authors

  will_publish
end

guide = Guide.create(name: 'How To Write A Rails App', description: 'Learn how to write your first Rails app!')
guide.publish
published_version = guide.published_version # <Guide id: 2, name: 'How To Write A Rails App', description: ...>
published_version.draft_version # <Guide id: 1, name: 'How To Write A Rails App', description: ...>

guide.update_attributes(name: 'How To Write Your First Rails App')
guide.publish
published_version = guide.published_version # <Guide id: 2, name: 'How To Write Your First Rails App', description: ...>
```