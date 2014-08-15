# will_publish

Provides publishing ability to your ActiveRecord models.

NOTE: This is a work-in-progress, and is not yet ready for actual use

## Installation

Add ```gem 'will_publish', github: 'nneufeld/will_publish'``` to your Gemfile.

## Usage

When publishing an object, a copy of the object is made, along with any objects that belong to the object(including nested objects).

```ruby
class Guide
  has_many :steps
  has_and_belongs_to_many :authors

  will_publish
end

guide = Guide.create(name: 'How To Write A Rails App', description: 'Learn how to write your first Rails app!')
guide.steps.create(name: 'Install Rails') # <Step: id: 1, name: 'Install Rails'>
guide.publish
published_version = guide.published_version # <Guide id: 2, name: 'How To Write A Rails App', description: ...>
published_version.draft_version # <Guide id: 1, name: 'How To Write A Rails App', description: ...>
published_version.steps.first # <Step: id: 2, name: 'Install Rails'>

guide.update_attributes(name: 'How To Write Your First Rails App')
guide.steps.first.update_attributes(name: 'Install Ruby on Rails')
guide.publish
published_version = guide.published_version # <Guide id: 2, name: 'How To Write Your First Rails App', description:
published_version.steps.first # <Step: id: 2, name: 'Install Ruby on Rails'>...>
```

## Filtering

By default, will_publish will copy all attributes, and all has_one, has_many, and has_and_belongs_to_many association. There are cases where you may want to exclude certain attributes or associations, usually for user created data on the published version. To do this, you can pass an 'only' or 'exclude' option to will_publish

```ruby
class Guide
  has_many :steps
  has_many :comments
  has_and_belongs_to_many :authors

  will_publish except: { 
    attributes: [:like_count],
    associations: [:comments, steps: { attributes: [:like_count], associations: [:comments] }]
  }
end
```

In this example, when publishing a guide, the like_count attribute and comments association on both the guide and any steps belonging to the guide will remain untouched.

## Callbacks

You can define before_publish, after_publish, and around_publish callbacks on your models.
```after_publish :add_to_search_index```
