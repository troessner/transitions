### Overview 
[![Build status](https://secure.travis-ci.org/troessner/transitions.png?branch=master)](http://travis-ci.org/troessner/transitions) 
[![Gem Version](https://badge.fury.io/rb/transitions.png)](http://badge.fury.io/rb/transitions)
[![Code Climate](https://codeclimate.com/github/troessner/transitions.png)](https://codeclimate.com/github/troessner/transitions)

### Synopsis

`transitions` is a ruby state machine implementation.

### Ruby Compatibility

Supported versions:

*   1.9.3
*   2.0

`transitions` does not work with ruby 1.8.7 (see [this
issue](https://github.com/troessner/transitions/issues/86) for example).

### Rails Compatibility

Right now `transitions` does **only** support rails 3. Rails 4 is **not** supported right now but I am working on fixing this.

### Installation

#### Rails

This goes into your Gemfile:
```ruby
gem "transitions", :require => ["transitions", "active_model/transitions"]
```

… and this into your ORM model:
```ruby
include ActiveModel::Transitions
```

#### Standalone
```shell
gem install transitions
```

### Using transitions
```ruby
class Product
  include ActiveModel::Transitions

  state_machine do
    state :available # first one is initial state
    state :out_of_stock, :exit => :exit_out_of_stock
    state :discontinued, :enter => lambda { |product| product.cancel_orders }

    event :discontinued do
      transitions :to => :discontinued, :from => [:available, :out_of_stock], :on_transition => :do_discontinue
    end
    event :out_of_stock, :success => :reorder do
      transitions :to => :out_of_stock, :from => [:available, :discontinued]
    end
    event :available do
      transitions :to => :available, :from => [:out_of_stock], :guard => lambda { |product| product.in_stock > 0 }
    end
  end
end
```
In this example we assume that you are in a rails project using Bundler, which
would automatically require `transitions`. If this is not the case for you you
have to add
```ruby
require 'transitions'
```

wherever you load your dependencies in your application.

**Known limitations:** 

*   You can only use one state machine per model. While in theory you can
    define two or more, this won't work as you would expect. Not supporting
    this was intentional, if you're interested in the ratione look up version
    0.1.0 in the CHANGELOG.

*   Use symbols, not strings for declaring the state machine. Using strings is
    **not** supported as is using whitespace in names (because `transitions`
    possibly generates methods out of this).

### Features

#### Getting and setting the current state

Use the (surprise ahead) `current_state` method - in case you didn't set a
state explicitly you'll get back the state that you defined as initial state.
```ruby
>> Product.new.current_state
=> :available
```

You can also set a new state explicitly via `update_current_state(new_state,
persist = true / false)` but you should never do this unless you really know
what you're doing and why - rather use events / state transitions (see below).

Predicate methods are also available using the name of the state.
```ruby
>> Product.new.available?
=> true
```

#### Events

When you declare an event, say `discontinue`, three methods are declared for
you: `discontinue`, `discontinue!` and `can_discontinue?`. The first two
events will modify the `state` attribute on successful transition, but only
the bang(!)-version will call `save!`.  The `can_discontinue?` method will not
modify state but instead returns a boolean letting you know if a given
transition is possible.

In addition, a `can_transition?` method is added to the object that expects one or more event names as arguments. This semi-verbose method name is used to avoid collission with [https://github.com/ryanb/cancan](the authorization gem CanCan).
```ruby
>> Product.new.can_transition? :out_of_stock
=> true
```

If you need to get all available transitions for current state you can simply call:
```ruby
>> Product.new.available_transitions
=> [:discontinued, :out_of_stock]
```
    
#### Automatic scope generation

`transitions` will automatically generate scopes for you if you are using
ActiveRecord and tell it to do so via the `auto_scopes` option:

Given a model like this:
```ruby
class Order < ActiveRecord::Base
  include ActiveModel::Transitions
  state_machine :auto_scopes => true do
    state :pick_line_items
    state :picking_line_items
    event :move_cart do
      transitions to: :pick_line_items, from: :picking_line_items
    end
  end
end
```

you can use this feature a la:
```ruby
>> Order.pick_line_items
=> []
>> Order.create!
=> #<Order id: 3, state: "pick_line_items", description: nil, created_at: "2011-08-23 15:48:46", updated_at: "2011-08-23 15:48:46">
>> Order.pick_line_items
=> [#<Order id: 3, state: "pick_line_items", description: nil, created_at: "2011-08-23 15:48:46", updated_at: "2011-08-23 15:48:46">]
```

#### Using `guard`

Each event definition takes an optional `guard` argument, which acts as a
predicate for the transition.

You can pass in Symbols, Strings, or Procs like this:
```ruby
event :discontinue do
  transitions :to => :discontinued, :from => [:available, :out_of_stock], :guard => :can_discontinue
end
```

or
```ruby
event :discontinue do
  transitions :to => :discontinued, :from => [:available, :out_of_stock], :guard => [:can_discontinue, :super_sure?]
end
```

Any arguments passed to the event method will be passed on to the `guard`
predicate.

#### Using `on_transition`

Each event definition takes an optional `on_transition` argument, which allows
you to execute methods on transition.

You can pass in a Symbol, a String, a Proc or an Array containing method names
as Symbol or String like this:
```ruby
event :discontinue do
  transitions :to => :discontinued, :from => [:available, :out_of_stock], :on_transition => [:do_discontinue, :notify_clerk]
end
```

Any arguments passed to the event method will be passed on to the `on_transition` callback.

`on_transition` is called after `guard` and before `enter` on the state that it is transitioning to.

#### Using `enter` and `exit`

If you want to trigger a method call when the object enters or exits a state regardless
of the transition that made that happen, use `enter` and `exit`.

`exit` will be called before the transition out of the state is executed. If you want the method
to only be called if the transition is successful, then use another approach.

`enter` will be called after the transition has been made but before the object is persisted. If you want
the method to only be called after a successful transition to a new state including persistence,
use the `success` argument to an event instead.

#### Using `success`

In case you need to trigger a method call after a successful transition you
can use `success`. This will be called after the `save!` is complete (if you
use the `state_name!` method) and should be used for any methods that require
that the object be persisted.
```ruby
event :discontinue, :success => :notfiy_admin do
  transitions :to => :discontinued, :from => [:available, :out_of_stock]
end
```

In addition to just specify the method name on the record as a symbol you can
pass a lambda to perfom some more complex success callbacks:
```ruby
event :discontinue, :success => lambda { |order| AdminNotifier.notify_about_discontinued_order(order) } do
  transitions :to => :discontinued, :from => [:available, :out_of_stock]
end
```

If you need it, you can even call multiple methods or lambdas just passing an
array:
```ruby
event :discontinue, :success => [:notify_admin, lambda { |order| AdminNotifier.notify_about_discontinued_order(order) }] do
  transitions :to => :discontinued, :from => [:available, :out_of_stock]
end
```

#### Timestamps

If you'd like to note the time of a state change, Transitions comes with
timestamps free! To activate them, simply pass the `timestamp` option to the
event definition with a value of either true or the name of the timestamp
column. *NOTE - This should be either true, a String or a Symbol*
```ruby
# This will look for an attribute called exploded_at or exploded_on (in that order)
# If present, it will be updated
event :explode, :timestamp => true do
  transitions :from => :complete, :to => :exploded
end

# This will look for an attribute named repaired_on to update upon save
event :rebuild, :timestamp => :repaired_on do
  transitions :from => :exploded, :to => :rebuilt
end
```

#### Using `event_fired` and `event_failed`

In case you define `event_fired` and / or `event_failed`, `transitions` will
use those callbacks correspondingly.

You can use those callbacks like this:
```ruby
def event_fired(current_state, new_state, event)
  MyLogger.info "Event fired #{event.inspect}"
end

def event_failed(event)
  MyLogger.warn "Event failed #{event.inspect}"
end
```

#### Listing all the available states and events

You can easily get a listing of all available states:
```ruby
Order.available_states # Uses the <tt>default</tt> state machine
# => [:pick_line_items, :picking_line_items]
```

Same goes for the available events:
```ruby
Order.available_events
# => [:move_cart]
```

#### Explicitly setting the initial state with the `initial` option
```ruby
state_machine :initial => :closed do
  state :open
  state :closed
end
```

### Configuring a different column name with ActiveRecord

To use a different column than `state` to track it's value simply do this:
```ruby
class Product < ActiveRecord::Base
  include Transitions

  state_machine :attribute_name => :different_column do

    ...

  end
end
```

### Known bugs / limitations

*   Right now it seems like `transitions` does not play well with `mongoid`. A
    possible fix had to be rolled back due to other side effects:
    https://github.com/troessner/transitions/issues/76. Since I know virtually
    zero about mongoid, a pull request would be highly appreciated.
*   Multiple state machines are and will not be supported. For the rationale
    behind this see the Changelog.


### Documentation, Guides & Examples

*   [Online API Documentation](http://rdoc.info/github/troessner/transitions/master/Transitions)
*   [Railscasts #392: A Tour of State Machines](http://railscasts.com/episodes/392-a-tour-of-state-machines) (requires Pro subscription)


### Copyright

Copyright (c) 2010 Jakub Kuźma, Timo Rößner. See LICENSE for details.
