# 1.0.0

(troessner) Remove suppport for multipe state machines

Here is the reasoning:

1.) If you really need multiple state machines for one model, you probably need multiple models.
    So far, I have not seen a valid use case for multiple state machines, which was not better expressed
    by using multiple models.

2.) The current transitions semantics and  API is not suited for multiple state machines:
    Right now events are just plain methods defined on the models itself.
    Consider you had multiple state machines, on named `day` and one named `night`, both with differing events.
    What to do when you switch to state machine `day` but trigger an event defined on `night`?
    You can either allow it, but this would make multiple state machines pointless if there is no enforced
    separation of concerns. Or you disallow it, in which case `events` would either have to be bound
    to state machines, not to the object itself, which would be tedious and ugly, or the `events` themselves
    would need to check if they are allowed to be called. The last solution seems like a clean solution
    but it would require a decent amount of rewriting existing code - and I just do not see the benefit for this.

3.) Kind of a weak point, but right now the functionality is broken anyway throughout the gem. This functionality
    is not even documented, so the side effects on existing projects should be minimal.

On the plus side, removing the possibility of having multiple state machines will streamline and improve existing
code a lot.

# 0.0.18 (2012-05-18)

* (troessner) Remove `define_state_query_method` from public API
* (troessner) Do not override existing methods when defining state query methods but warn the user.

# 0.0.17 (2012-05-02):

* (zmillman) Add write_state_without_persistence.

# 0.0.16 (2012-04-18):

* (mperham) Remove backports, fix Ruby 1.8 support.

# 0.0.15 (2012-04-17):

* (troessner) Ensure ruby 1.8.7 compatibility.

# 0.0.14 (2012-04-16):

* (troessner) Improve error messages for invalid transitions.
